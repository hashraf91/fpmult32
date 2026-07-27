#include <time.h>

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <mutex>
#include <sstream>
#include <stdexcept>
#include <string>
#include <thread>

#include "fpmult_e8m23.h"

struct HexLineData {
  uint32_t a, b;
  uint32_t prod, exact;
};

struct Metrics {
  uint64_t err_cnt;
  uint64_t ED_max;
  uint64_t ED_total;
  uint64_t EDsq_total;
  long double RED_total;
};

static Metrics metrics = {0, 0, 0, 0, 0.0L};
static std::mutex g_metrics_mutex;

using ModelFn = uint32_t (*)(uint32_t, uint32_t);

struct ModelInfo {
  std::string canonical_name;
  ModelFn fn;
};

static std::string trim(const std::string &s) {
  const char *ws = " \t\r\n";
  size_t start = s.find_first_not_of(ws);
  if (start == std::string::npos) {
    return "";
  }
  size_t end = s.find_last_not_of(ws);
  return s.substr(start, end - start + 1);
}

static ModelInfo resolveModel(const std::string &name) {
  if (name == "fpmult_e8m23_viv_acc" || name == "viv_acc" || name == "acc")
    return {"fpmult_e8m23_viv_acc", fpmult_e8m23_viv_acc_u32};

  if (name == "fpmult_e8m23_mxa1" || name == "mxa1")
    return {"fpmult_e8m23_mxa1", fpmult_e8m23_mxa1_u32};

  if (name == "fpmult_e8m23_mxa2" || name == "mxa2")
    return {"fpmult_e8m23_mxa2", fpmult_e8m23_mxa2_u32};

  if (name == "fpmult_e8m23_lxa" || name == "lxa")
    return {"fpmult_e8m23_lxa", fpmult_e8m23_lxa_u32};

  if (name == "fpmult_e8m23_lmul" || name == "lmul")
    return {"fpmult_e8m23_lmul", fpmult_e8m23_lmul_u32};

  if (name == "fpmult_e8m23_ssm_m12" || name == "ssm_m12")
    return {"fpmult_e8m23_ssm_m12", fpmult_e8m23_ssm_m12_u32};

  if (name == "fpmult_e8m23_ssm_m12c" || name == "ssm_m12c")
    return {"fpmult_e8m23_ssm_m12c", fpmult_e8m23_ssm_m12c_u32};

  if (name == "fpmult_e8m23_ssm_m14" || name == "ssm_m14")
    return {"fpmult_e8m23_ssm_m14", fpmult_e8m23_ssm_m14_u32};

  if (name == "fpmult_e8m23_ssm_m14c" || name == "ssm_m14c")
    return {"fpmult_e8m23_ssm_m14c", fpmult_e8m23_ssm_m14c_u32};

  if (name == "fpmult_e8m23_ssm_m16" || name == "ssm_m16")
    return {"fpmult_e8m23_ssm_m16", fpmult_e8m23_ssm_m16_u32};

  if (name == "fpmult_e8m23_ssm_m16c" || name == "ssm_m16c")
    return {"fpmult_e8m23_ssm_m16c", fpmult_e8m23_ssm_m16c_u32};

  if (name == "fpmult_e8m23_ssm_m18" || name == "ssm_m18")
    return {"fpmult_e8m23_ssm_m18", fpmult_e8m23_ssm_m18_u32};

  if (name == "fpmult_e8m23_ssm_m18c" || name == "ssm_m18c")
    return {"fpmult_e8m23_ssm_m18c", fpmult_e8m23_ssm_m18c_u32};

  throw std::runtime_error("Unknown model name: " + name);
}

static void printUsage(const char *prog) {
  std::cerr << "Usage: " << prog << " <model-name> [csv-file]\n\n";
  std::cerr << "Examples:\n";
  std::cerr << "  " << prog << " viv_acc\n";
  std::cerr << "  " << prog << " mxa1\n";
  std::cerr << "  " << prog << " mxa2\n";
  std::cerr << "  " << prog << " lxa\n";
  std::cerr << "  " << prog << " lmul\n";
  std::cerr << "  " << prog << " ssm_m12\n";
  std::cerr << "  " << prog << " ssm_m12c\n";
  std::cerr << "  " << prog << " mxa1 /path/to/fpmult_e8m23_mxa1.csv\n";
}

size_t getTotalLines(const std::string &filename) {
  std::ifstream file(filename);
  if (!file.is_open()) {
    throw std::runtime_error("Failed to open file: " + filename);
  }

  std::string header, line;
  std::getline(file, header);
  std::getline(file, line);

  if (header.empty() || line.empty()) {
    throw std::runtime_error("CSV file appears empty or malformed: " + filename);
  }

  size_t headerLength = header.length() + 1;
  size_t lineLength = line.length() + 1;

  size_t totalSize = std::filesystem::file_size(filename);
  return (totalSize - headerLength) / lineLength;
}

size_t getStartPos(const std::string &filename, size_t start) {
  std::ifstream file(filename);
  if (!file.is_open()) {
    throw std::runtime_error("Failed to open file: " + filename);
  }

  std::string header, line;
  std::getline(file, header);
  std::getline(file, line);
  return header.length() + 1 + start * (line.length() + 1);
}

size_t compareHwImplementation(const std::string &filename, size_t start,
                               size_t numOfLines, ModelFn modelFn) {
  std::ifstream file(filename);
  static std::mutex printMtx;

  if (!file.is_open()) {
    std::lock_guard<std::mutex> lk(printMtx);
    std::cerr << "Error: Unable to open file: " << filename << "\n";
    return 0;
  }

  std::streampos startPos =
      static_cast<std::streampos>(getStartPos(filename, start));
  file.seekg(startPos);

  std::string line;
  size_t linesMatched = 0;

  uint64_t err_cnt = 0;
  uint64_t ED = 0, ED_max = 0, ED_total = 0, EDsq = 0, EDsq_total = 0;
  long double RED = 0.0L, RED_total = 0.0L;

  for (size_t count = 0; count < numOfLines && std::getline(file, line); count++) {
    std::istringstream ss(line);
    std::string token;

    HexLineData entry{};
    try {
      std::getline(ss, token, ',');
      entry.a = std::stoul(trim(token), nullptr, 16);

      std::getline(ss, token, ',');
      entry.b = std::stoul(trim(token), nullptr, 16);

      std::getline(ss, token, ',');
      entry.prod = std::stoul(trim(token), nullptr, 16);

      std::getline(ss, token, ',');
      entry.exact = std::stoul(trim(token), nullptr, 16);
    } catch (const std::exception &e) {
      std::lock_guard<std::mutex> lk(printMtx);
      std::cerr << "Parse error on line " << (start + count + 1) << ": "
                << e.what() << "\n";
      continue;
    }

    try {
      uint32_t actual = modelFn(entry.a, entry.b);
      if (actual != entry.prod) {
        std::lock_guard<std::mutex> lk(printMtx);
        std::cerr << "Result mismatch for A=0x" << std::hex << entry.a
                  << ", B=0x" << entry.b
                  << ", SW=0x" << actual
                  << ", HW=0x" << entry.prod << std::dec << std::endl;
        break;
      }
    } catch (const std::exception &e) {
      std::lock_guard<std::mutex> lk(printMtx);
      std::cerr << "Model execution error at line " << (start + count + 1)
                << ": " << e.what() << "\n";
      break;
    }

    linesMatched++;

    ED = (entry.exact > entry.prod) ? (entry.exact - entry.prod)
                                    : (entry.prod - entry.exact);

    if (ED > ED_max) {
      ED_max = ED;
    }
    ED_total += ED;

    EDsq = ED * ED;
    EDsq_total += EDsq;

    if (entry.exact) {
      RED = (long double)ED / entry.exact;
      RED_total += RED;
    }

    err_cnt += !!ED;
  }

  {
    std::lock_guard<std::mutex> lk(g_metrics_mutex);
    metrics.err_cnt += err_cnt;
    if (ED_max > metrics.ED_max) {
      metrics.ED_max = ED_max;
    }
    metrics.ED_total += ED_total;
    metrics.EDsq_total += EDsq_total;
    metrics.RED_total += RED_total;
  }

  return linesMatched;
}

int main(int argc, char *argv[]) {
  try {
    if (argc < 2 || argc > 3) {
      printUsage(argv[0]);
      return 1;
    }

    ModelInfo model = resolveModel(argv[1]);

    std::string filename;
    if (argc == 3) {
      filename = argv[2];
    } else {
      filename = "/home/siemens/mydata/MSEE_ICS/4th_semester/Thesis/results/" +
                 model.canonical_name + ".csv";
    }

    long nproc = sysconf(_SC_NPROCESSORS_ONLN);
    if (nproc <= 0) {
      nproc = 1;
    }

    unsigned long threadsCount = 0;
    uint64_t totalThreads = 0;
    std::condition_variable threadsCv;
    std::mutex threadsMtx;

    size_t totalLines = getTotalLines(filename);
    const size_t maxLinesPerThread = 1ULL << 12;

    time_t start, end;
    double elapsed = 0.0, prevElapsed = 0.0;
    std::atomic<uint32_t> errors(0);

    time(&start);

    for (size_t count = 0; count < totalLines;) {
      size_t linesPerThread =
          ((count + maxLinesPerThread) < totalLines)
              ? maxLinesPerThread
              : (totalLines - count);

      {
        std::lock_guard<std::mutex> lk(threadsMtx);
        threadsCount++;
      }

      std::thread([count, linesPerThread, filename, model, &threadsMtx,
                   &threadsCount, &threadsCv, &errors] {
        if (compareHwImplementation(filename, count, linesPerThread, model.fn) !=
            linesPerThread) {
          errors++;
        }

        {
          std::lock_guard<std::mutex> lk(threadsMtx);
          threadsCount--;
        }
        threadsCv.notify_one();
      }).detach();

      count += linesPerThread;
      totalThreads++;

      time(&end);
      elapsed = difftime(end, start);
      if (elapsed >= prevElapsed + 5.0) {
        prevElapsed = elapsed;
      }

      std::unique_lock<std::mutex> lk(threadsMtx);
      threadsCv.wait(lk, [&threadsCount, nproc]() {
        return threadsCount < (unsigned long)nproc;
      });

      if (errors > 0) {
        break;
      }
    }

    {
      std::unique_lock<std::mutex> lk(threadsMtx);
      threadsCv.wait(lk, [&threadsCount]() { return threadsCount == 0; });
    }

    if (errors > 0) {
      printf("Errors found: %u\n", errors.load());
      return 1;
    }

    const uint64_t max_cnt = totalLines;
    long double ER = (long double)metrics.err_cnt / max_cnt;
    long double MED = (long double)metrics.ED_total / max_cnt;
    long double MSED = (long double)metrics.EDsq_total / max_cnt;
    long double NMED = (metrics.ED_max == 0) ? 0.0L : (MED / metrics.ED_max);
    long double MRED = metrics.RED_total / max_cnt;

    printf("Threads: %ld\n", nproc);
    printf("Total thread chunks launched: %lu\n", totalThreads);
    printf("CSV file: %s\n", filename.c_str());
    printf("Error Metrics (ULPs) for %s:\n", model.canonical_name.c_str());
    printf("CNT  | Max_Count                      | %lu\n", max_cnt);
    printf("ER   | Error_Ratio                    | %Lf\n", ER);
    printf("EDX  | Error_Distance_Max             | %lu\n", metrics.ED_max);
    printf("MED  | Mean_Error_Distance            | %Lf\n", MED);
    printf("MSED | Mean_Square_Error_Distance     | %Lf\n", MSED);
    printf("NMED | Normalized_Mean_Error_Distance | %Lf\n", NMED);
    printf("MRED | Mean_Relative_Error_Distance   | %Lg\n", MRED);
  } catch (const std::exception &e) {
    std::cerr << "Fatal error: " << e.what() << "\n";
    return 1;
  }

  return 0;
}

#include <time.h>

#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <iostream>
#include <mutex>
#include <random>
#include <stdexcept>
#include <string>
#include <thread>
#include <atomic>

#include "fpmult_e8m23.h"

struct Metrics {
  uint64_t err_cnt;
  uint64_t ED_max;
  unsigned long long ED_total;
  long double EDsq_total;
  long double RED_total;
};

static Metrics metrics = {0, 0, 0, 0.0L, 0.0L};
static std::mutex g_metrics_mutex;
static std::atomic<uint64_t> g_processed_count(0);

enum class Domain {
  INT,
  FP32
};

struct ModelInfo {
  std::string canonical_name;
  Domain domain;
  int size_bits; // 3, 6, 12, 23, 24, 32(fp32)
  std::function<uint64_t(uint64_t, uint64_t)> fn_u64;
};

static std::string normalize_name(const std::string &s) {
  if (s == "acc" || s == "exact") return "acc1";
  return s;
}

static void printUsage(const char *prog) {
  std::cerr << "Usage: " << prog << " <model-name> <size>\n\n";
  std::cerr << "Examples:\n";
  std::cerr << "  " << prog << " acc1 3\n";
  std::cerr << "  " << prog << " acc2 24\n";
  std::cerr << "  " << prog << " mxa1 12\n";
  std::cerr << "  " << prog << " mxa2 24\n";
  std::cerr << "  " << prog << " lxa 24\n";
  std::cerr << "  " << prog << " viv_acc fp32\n";
  std::cerr << "  " << prog << " mxa1 fp32\n";
  std::cerr << "  " << prog << " lmul fp32\n";
  std::cerr << "  " << prog << " ssm_m12 fp32\n";
  std::cerr << "  " << prog << " ssm_m12 23\n";
  std::cerr << "  " << prog << " ssm_m12c 23\n";
}

static int parseSize(const std::string &s) {
  if (s == "fp32") return 32;
  return std::stoi(s);
}

// User-requested policy: exhaustive up to 24x24, random only above 24 (i.e. fp32)
static bool useRandomForSize(int size_bits) {
  return (size_bits > 12);
}

static uint32_t random_u32(std::mt19937 &rng) {
  static thread_local std::uniform_int_distribution<uint32_t> dist(0, 0xFFFFFFFFU);
  return dist(rng);
}

static uint32_t random_masked_u32(std::mt19937 &rng, int bits) {
  uint32_t val = random_u32(rng);
  if (bits >= 32) return val;
  return val & ((1U << bits) - 1U);
}

static ModelInfo resolveModel(const std::string &raw_name, int size_bits) {
  const std::string name = normalize_name(raw_name);

  if (size_bits == 32) {
    if (name == "viv_acc")
      return {"fpmult_e8m23_viv_acc", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_viv_acc_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "acc1")
      return {"fpmult_e8m23_viv_acc", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_viv_acc_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "acc2")
      return {"fpmult_e8m23_viv_acc", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_viv_acc_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "mxa1")
      return {"fpmult_e8m23_mxa1", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_mxa1_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "mxa2")
      return {"fpmult_e8m23_mxa2", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_mxa2_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "lxa")
      return {"fpmult_e8m23_lxa", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_lxa_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "lmul")
      return {"fpmult_e8m23_lmul", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_lmul_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "ssm_m12")
      return {"fpmult_e8m23_ssm_m12", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_ssm_m12_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "ssm_m12c")
      return {"fpmult_e8m23_ssm_m12c", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_ssm_m12c_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "ssm_m14")
      return {"fpmult_e8m23_ssm_m14", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_ssm_m14_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "ssm_m14c")
      return {"fpmult_e8m23_ssm_m14c", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_ssm_m14c_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "ssm_m16")
      return {"fpmult_e8m23_ssm_m16", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_ssm_m16_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "ssm_m16c")
      return {"fpmult_e8m23_ssm_m16c", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_ssm_m16c_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "ssm_m18")
      return {"fpmult_e8m23_ssm_m18", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_ssm_m18_u32((uint32_t)a, (uint32_t)b); }};

    if (name == "ssm_m18c")
      return {"fpmult_e8m23_ssm_m18c", Domain::FP32, 32,
              [](uint64_t a, uint64_t b) { return (uint64_t)fpmult_e8m23_ssm_m18c_u32((uint32_t)a, (uint32_t)b); }};

    throw std::runtime_error("Unsupported fp32 model: " + name);
  }

  if (size_bits == 3) {
    if (name == "acc1" || name == "viv_acc")
      return {"mult_3x3_acc1", Domain::INT, 3,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_3x3_acc1_u8((uint8_t)a, (uint8_t)b); }};
    if (name == "acc2")
      return {"mult_3x3_acc2", Domain::INT, 3,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_3x3_acc2_u8((uint8_t)a, (uint8_t)b); }};
    if (name == "mxa1")
      return {"mult_3x3_mxa1", Domain::INT, 3,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_3x3_mxa1_u8((uint8_t)a, (uint8_t)b); }};
    if (name == "mxa2")
      return {"mult_3x3_mxa2", Domain::INT, 3,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_3x3_mxa2_u8((uint8_t)a, (uint8_t)b); }};
  }

  if (size_bits == 6) {
    if (name == "acc1" || name == "viv_acc")
      return {"mult_6x6_acc1", Domain::INT, 6,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_6x6_acc1_u16((uint8_t)a, (uint8_t)b); }};
    if (name == "acc2")
      return {"mult_6x6_acc2", Domain::INT, 6,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_6x6_acc2_u16((uint8_t)a, (uint8_t)b); }};
    if (name == "mxa1")
      return {"mult_6x6_mxa1", Domain::INT, 6,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_6x6_mxa1_u16((uint8_t)a, (uint8_t)b); }};
    if (name == "mxa2")
      return {"mult_6x6_mxa2", Domain::INT, 6,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_6x6_mxa2_u16((uint8_t)a, (uint8_t)b); }};
  }

  if (size_bits == 12) {
    if (name == "acc1" || name == "viv_acc")
      return {"mult_12x12_acc1", Domain::INT, 12,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_12x12_acc1_u32((uint16_t)a, (uint16_t)b); }};
    if (name == "acc2")
      return {"mult_12x12_acc2", Domain::INT, 12,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_12x12_acc2_u32((uint16_t)a, (uint16_t)b); }};
    if (name == "mxa1")
      return {"mult_12x12_mxa1", Domain::INT, 12,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_12x12_mxa1_u32((uint16_t)a, (uint16_t)b); }};
    if (name == "mxa2")
      return {"mult_12x12_mxa2", Domain::INT, 12,
              [](uint64_t a, uint64_t b) { return (uint64_t)mult_12x12_mxa2_u32((uint16_t)a, (uint16_t)b); }};
  }

  if (size_bits == 24) {
    if (name == "acc1" || name == "viv_acc")
      return {"mult_24x24_acc1", Domain::INT, 24,
              [](uint64_t a, uint64_t b) { return mult_24x24_acc1_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "acc2")
      return {"mult_24x24_acc2", Domain::INT, 24,
              [](uint64_t a, uint64_t b) { return mult_24x24_acc2_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "mxa1")
      return {"mult_24x24_mxa1", Domain::INT, 24,
              [](uint64_t a, uint64_t b) { return mult_24x24_mxa1_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "mxa2")
      return {"mult_24x24_mxa2", Domain::INT, 24,
              [](uint64_t a, uint64_t b) { return mult_24x24_mxa2_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "lxa")
      return {"mult_24x24_lxa", Domain::INT, 24,
              [](uint64_t a, uint64_t b) { return mult_24x24_lxa_u64((uint32_t)a, (uint32_t)b); }};
  }

  if (size_bits == 23) {
    if (name == "ssm_m12")
      return {"mult_23x23_ssm_m12", Domain::INT, 23,
              [](uint64_t a, uint64_t b) { return mult_23x23_ssm_m12_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "ssm_m12c")
      return {"mult_23x23_ssm_m12c", Domain::INT, 23,
              [](uint64_t a, uint64_t b) { return mult_23x23_ssm_m12c_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "ssm_m14")
      return {"mult_23x23_ssm_m14", Domain::INT, 23,
              [](uint64_t a, uint64_t b) { return mult_23x23_ssm_m14_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "ssm_m14c")
      return {"mult_23x23_ssm_m14c", Domain::INT, 23,
              [](uint64_t a, uint64_t b) { return mult_23x23_ssm_m14c_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "ssm_m16")
      return {"mult_23x23_ssm_m16", Domain::INT, 23,
              [](uint64_t a, uint64_t b) { return mult_23x23_ssm_m16_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "ssm_m16c")
      return {"mult_23x23_ssm_m16c", Domain::INT, 23,
              [](uint64_t a, uint64_t b) { return mult_23x23_ssm_m16c_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "ssm_m18")
      return {"mult_23x23_ssm_m18", Domain::INT, 23,
              [](uint64_t a, uint64_t b) { return mult_23x23_ssm_m18_u64((uint32_t)a, (uint32_t)b); }};
    if (name == "ssm_m18c")
      return {"mult_23x23_ssm_m18c", Domain::INT, 23,
              [](uint64_t a, uint64_t b) { return mult_23x23_ssm_m18c_u64((uint32_t)a, (uint32_t)b); }};
  }

  throw std::runtime_error("Unsupported model/size combination: " + name + " / " + std::to_string(size_bits));
}

static uint64_t exact_int_product(uint64_t a, uint64_t b, int size_bits) {
  uint64_t mask = (size_bits >= 64) ? ~0ULL : ((1ULL << size_bits) - 1ULL);
  return (a & mask) * (b & mask);
}

static void accumulateMetrics(uint64_t exact, uint64_t approx) {
  uint64_t ED = (exact > approx) ? (exact - approx) : (approx - exact);
  long double RED = (exact != 0ULL) ? ((long double)ED / (long double)exact) : 0.0L;

  std::lock_guard<std::mutex> lk(g_metrics_mutex);
  metrics.err_cnt += (ED != 0ULL);
  if (ED > metrics.ED_max) metrics.ED_max = ED;
  metrics.ED_total += ED;
  metrics.EDsq_total += (long double)ED * (long double)ED;
  metrics.RED_total += RED;
}

static void runIntegerChunk(uint64_t start_a, uint64_t end_a,
                            int size_bits, bool use_random,
                            uint64_t samples_per_chunk,
                            const ModelInfo &model) {
  thread_local std::mt19937 rng(12345U ^ (uint32_t)std::hash<std::thread::id>{}(std::this_thread::get_id()));
  uint64_t local_processed = 0;

  if (use_random) {
    for (uint64_t i = 0; i < samples_per_chunk; ++i) {
      uint32_t a = random_masked_u32(rng, size_bits);
      uint32_t b = random_masked_u32(rng, size_bits);

      uint64_t exact = exact_int_product(a, b, size_bits) >> size_bits;
      uint64_t approx = model.fn_u64(a, b) >> size_bits;
      accumulateMetrics(exact, approx);
      local_processed++;
    }
  } else {
    const uint64_t maxv = (1ULL << size_bits) - 1ULL;
    for (uint64_t a = start_a; a < end_a; ++a) {
      for (uint64_t b = 0; b <= maxv; ++b) {
        uint64_t exact = exact_int_product(a, b, size_bits) >> size_bits;
        uint64_t approx = model.fn_u64(a, b) >> size_bits;
        accumulateMetrics(exact, approx);
        local_processed++;
      }
    }
  }

  g_processed_count.fetch_add(local_processed, std::memory_order_relaxed);
}

// FP32 error evaluation uses normalized operands only: random sign, biased
// exponent in [1,254] and random fraction. Pairs whose exact product exponent
// leaves [2,253] are rejected, so no NaN, Inf, zero, subnormal, overflow or
// underflow case is evaluated. Every chunk has its own fixed seed, hence the
// result does not depend on the number of threads or on their scheduling.
static uint32_t random_normalized_fp32(std::mt19937_64 &rng) {
  const uint64_t r = rng();
  return ((uint32_t)(r & 1U) << 31) |
         ((1U + (uint32_t)((r >> 1) % 254U)) << 23) |
         (uint32_t)((r >> 9) & 0x7FFFFFU);
}

static void runFp32Chunk(uint64_t count, uint64_t chunk_id, const ModelInfo &model) {
  std::mt19937_64 rng(0x5EED0000ULL + chunk_id);
  uint64_t accepted = 0;

  while (accepted < count) {
    const uint32_t a = random_normalized_fp32(rng);
    const uint32_t b = random_normalized_fp32(rng);

    const uint32_t exact = fpmult_e8m23_viv_acc_u32(a, b);
    const uint32_t exact_exp = (exact >> 23) & 0xFFU;
    if (exact_exp < 2U || exact_exp > 253U) continue;

    const uint32_t approx = (uint32_t)model.fn_u64(a, b);
    accumulateMetrics(exact, approx);
    accepted++;
  }

  g_processed_count.fetch_add(count, std::memory_order_relaxed);
}

static void printProgressIfNeeded(time_t start,
                                  double &prev_elapsed,
                                  uint64_t total_count,
                                  unsigned long threadsCount,
                                  uint64_t totalThreads) {
  time_t now;
  time(&now);
  double elapsed = difftime(now, start);

  if (elapsed >= prev_elapsed + 5.0) {
    prev_elapsed = elapsed;

    uint64_t processed = g_processed_count.load(std::memory_order_relaxed);
    long double pct = (total_count == 0)
                          ? 0.0L
                          : (100.0L * (long double)processed / (long double)total_count);

    long double rate = (elapsed > 0.0)
                           ? ((long double)processed / elapsed)
                           : 0.0L;

    long double eta_sec = (rate > 0.0L && processed < total_count)
                              ? ((long double)(total_count - processed) / rate)
                              : 0.0L;

    printf("[Progress] chunks=%lu active_threads=%lu processed=%lu / %lu (%.9Lf%%), rate=%.2Lf ops/s, eta=%.1Lf s\n",
           totalThreads, threadsCount, processed, total_count, pct, rate, eta_sec);
    fflush(stdout);
  }
}

int main(int argc, char *argv[]) {
  try {
    if (argc != 3) {
      printUsage(argv[0]);
      return 1;
    }

    const std::string model_name = argv[1];
    const int size_bits = parseSize(argv[2]);
    const ModelInfo model = resolveModel(model_name, size_bits);

    long nproc = sysconf(_SC_NPROCESSORS_ONLN);
    if (nproc <= 0) nproc = 1;

    unsigned long threadsCount = 0;
    uint64_t totalThreads = 0;
    std::condition_variable threadsCv;
    std::mutex threadsMtx;

    time_t start, end;
    double elapsed = 0.0, prev_elapsed = 0.0;

    uint64_t total_count = 0;

    time(&start);

    if (model.domain == Domain::FP32) {
      const uint64_t total_samples = 1ULL << 26;
      const uint64_t chunk_size = 1ULL << 20;
      total_count = total_samples;

      for (uint64_t done = 0; done < total_samples; done += chunk_size) {
        uint64_t this_chunk = ((done + chunk_size) < total_samples)
                                  ? chunk_size
                                  : (total_samples - done);

        {
          std::lock_guard<std::mutex> lk(threadsMtx);
          threadsCount++;
        }

        const uint64_t chunk_id = done / chunk_size;
        std::thread([this_chunk, chunk_id, &model, &threadsMtx, &threadsCount, &threadsCv]() {
          runFp32Chunk(this_chunk, chunk_id, model);
          {
            std::lock_guard<std::mutex> lk(threadsMtx);
            threadsCount--;
          }
          threadsCv.notify_one();
        }).detach();

        totalThreads++;

        time(&end);
        elapsed = difftime(end, start);
        if (elapsed >= prev_elapsed + 5.0) {
          printProgressIfNeeded(start, prev_elapsed, total_count, threadsCount, totalThreads);
        }

        std::unique_lock<std::mutex> lk(threadsMtx);
        while (threadsCount >= (unsigned long)nproc) {
          threadsCv.wait_for(lk, std::chrono::seconds(1));
          printProgressIfNeeded(start, prev_elapsed, total_count, threadsCount, totalThreads);
        }
      }
    } else {
      const bool use_random = useRandomForSize(size_bits);

      if (use_random) {
        const uint64_t total_samples = 1ULL << 30;
        const uint64_t chunk_size = 1ULL << 16;
        total_count = total_samples;

        for (uint64_t done = 0; done < total_samples; done += chunk_size) {
          uint64_t this_chunk = ((done + chunk_size) < total_samples)
                                    ? chunk_size
                                    : (total_samples - done);

          {
            std::lock_guard<std::mutex> lk(threadsMtx);
            threadsCount++;
          }

          std::thread([this_chunk, size_bits, &model, &threadsMtx, &threadsCount, &threadsCv]() {
            runIntegerChunk(0, 0, size_bits, true, this_chunk, model);
            {
              std::lock_guard<std::mutex> lk(threadsMtx);
              threadsCount--;
            }
            threadsCv.notify_one();
          }).detach();

          totalThreads++;

          time(&end);
          elapsed = difftime(end, start);
          if (elapsed >= prev_elapsed + 5.0) {
            printProgressIfNeeded(start, prev_elapsed, total_count, threadsCount, totalThreads);
          }

          std::unique_lock<std::mutex> lk(threadsMtx);
          while (threadsCount >= (unsigned long)nproc) {
            threadsCv.wait_for(lk, std::chrono::seconds(1));
            printProgressIfNeeded(start, prev_elapsed, total_count, threadsCount, totalThreads);
          }
        }
      } else {
        const uint64_t maxv = (1ULL << size_bits) - 1ULL;
        const uint64_t total_a = maxv + 1ULL;
        uint64_t a_per_chunk = 1ULL << 6;

        if (size_bits >= 24) {
          a_per_chunk = 1;
        } else if (size_bits >= 12) {
          a_per_chunk = 4;
        }

        total_count = (maxv + 1ULL) * (maxv + 1ULL);

        for (uint64_t start_a = 0; start_a < total_a; start_a += a_per_chunk) {
          uint64_t end_a = ((start_a + a_per_chunk) < total_a)
                               ? (start_a + a_per_chunk)
                               : total_a;

          {
            std::lock_guard<std::mutex> lk(threadsMtx);
            threadsCount++;
          }

          std::thread([start_a, end_a, size_bits, &model, &threadsMtx, &threadsCount, &threadsCv]() {
            runIntegerChunk(start_a, end_a, size_bits, false, 0, model);
            {
              std::lock_guard<std::mutex> lk(threadsMtx);
              threadsCount--;
            }
            threadsCv.notify_one();
          }).detach();

          totalThreads++;

          time(&end);
          elapsed = difftime(end, start);
          if (elapsed >= prev_elapsed + 5.0) {
            printProgressIfNeeded(start, prev_elapsed, total_count, threadsCount, totalThreads);
          }

          std::unique_lock<std::mutex> lk(threadsMtx);
          while (threadsCount >= (unsigned long)nproc) {
            threadsCv.wait_for(lk, std::chrono::seconds(1));
            printProgressIfNeeded(start, prev_elapsed, total_count, threadsCount, totalThreads);
          }
        }
      }
    }

    {
      std::unique_lock<std::mutex> lk(threadsMtx);
      while (threadsCount != 0) {
        threadsCv.wait_for(lk, std::chrono::seconds(1));
        printProgressIfNeeded(start, prev_elapsed, total_count, threadsCount, totalThreads);
      }
    }

    long double ER = (long double)metrics.err_cnt / (long double)total_count;
    long double MED = (long double)metrics.ED_total / (long double)total_count;
    long double MSED = metrics.EDsq_total / (long double)total_count;
    long double NMED = (metrics.ED_max == 0) ? 0.0L : (MED / (long double)metrics.ED_max);
    long double MRED = metrics.RED_total / (long double)total_count;

    printf("Threads: %ld\n", nproc);
    printf("Total thread chunks launched: %lu\n", totalThreads);
    printf("Model: %s\n", model.canonical_name.c_str());
    printf("Domain: %s\n", (model.domain == Domain::FP32) ? "fp32" : "integer");
    if (size_bits == 32) {
      printf("Size: fp32\n");
    } else {
      printf("Size: %d\n", size_bits);
    }
    printf("CNT  | Max_Count                      | %lu\n", total_count);
    printf("ER   | Error_Ratio                    | %Lf\n", ER);
    printf("EDX  | Error_Distance_Max             | %lu\n", metrics.ED_max);
    printf("MED  | Mean_Error_Distance            | %Lf\n", MED);
    printf("MSED | Mean_Square_Error_Distance     | %Lf\n", MSED);
    printf("NMED | Normalized_Mean_Error_Distance | %Lf\n", NMED);
    printf("MRED | Mean_Relative_Error_Distance   | %Lg\n", MRED);
    fflush(stdout);
  } catch (const std::exception &e) {
    std::cerr << "Fatal error: " << e.what() << "\n";
    return 1;
  }

  return 0;
}

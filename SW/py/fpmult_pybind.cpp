#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>

#include "fpmult_e8m23.h"

#include <cstdint>
#include <cstring>
#include <stdexcept>
#include <string>
#include <vector>

namespace py = pybind11;

using ModelFnU32 = uint32_t (*)(uint32_t, uint32_t);

static inline uint32_t float_to_u32(float x) {
    uint32_t u;
    std::memcpy(&u, &x, sizeof(uint32_t));
    return u;
}

static inline float u32_to_float(uint32_t u) {
    float x;
    std::memcpy(&x, &u, sizeof(float));
    return x;
}

static ModelFnU32 resolve_model_u32(const std::string& name) {
    if (name == "fpmult_e8m23_viv_acc" || name == "viv_acc" || name == "acc")
        return fpmult_e8m23_viv_acc_u32;

    if (name == "fpmult_e8m23_mxa1" || name == "mxa1")
        return fpmult_e8m23_mxa1_u32;

    if (name == "fpmult_e8m23_mxa2" || name == "mxa2")
        return fpmult_e8m23_mxa2_u32;

    if (name == "fpmult_e8m23_lxa" || name == "lxa")
        return fpmult_e8m23_lxa_u32;

    if (name == "fpmult_e8m23_lmul" || name == "lmul")
        return fpmult_e8m23_lmul_u32;

    if (name == "fpmult_e8m23_ssm_m12" || name == "ssm_m12")
        return fpmult_e8m23_ssm_m12_u32;

    if (name == "fpmult_e8m23_ssm_m12c" || name == "ssm_m12c")
        return fpmult_e8m23_ssm_m12c_u32;

    if (name == "fpmult_e8m23_ssm_m14" || name == "ssm_m14")
        return fpmult_e8m23_ssm_m14_u32;

    if (name == "fpmult_e8m23_ssm_m14c" || name == "ssm_m14c")
        return fpmult_e8m23_ssm_m14c_u32;

    if (name == "fpmult_e8m23_ssm_m16" || name == "ssm_m16")
        return fpmult_e8m23_ssm_m16_u32;

    if (name == "fpmult_e8m23_ssm_m16c" || name == "ssm_m16c")
        return fpmult_e8m23_ssm_m16c_u32;

    if (name == "fpmult_e8m23_ssm_m18" || name == "ssm_m18")
        return fpmult_e8m23_ssm_m18_u32;

    if (name == "fpmult_e8m23_ssm_m18c" || name == "ssm_m18c")
        return fpmult_e8m23_ssm_m18c_u32;

    throw std::runtime_error(
        "Unknown model name: " + name +
        ". Supported models: viv_acc, mxa1, mxa2, lxa, lmul, "
        "ssm_m12, ssm_m12c, ssm_m14, ssm_m14c, "
        "ssm_m16, ssm_m16c, ssm_m18, ssm_m18c");
}

static uint32_t multiply_u32_scalar(uint32_t a, uint32_t b, const std::string& model) {
    auto fn = resolve_model_u32(model);
    return fn(a, b);
}

static float multiply_float_scalar(float a, float b, const std::string& model) {
    auto fn = resolve_model_u32(model);
    uint32_t ua = float_to_u32(a);
    uint32_t ub = float_to_u32(b);
    uint32_t ur = fn(ua, ub);
    return u32_to_float(ur);
}

static py::array_t<uint32_t> multiply_u32_array(
    py::array_t<uint32_t, py::array::c_style | py::array::forcecast> a,
    py::array_t<uint32_t, py::array::c_style | py::array::forcecast> b,
    const std::string& model) {

    auto fn = resolve_model_u32(model);

    if (a.ndim() != b.ndim()) {
        throw std::runtime_error("Input arrays must have the same number of dimensions.");
    }
    for (py::ssize_t i = 0; i < a.ndim(); ++i) {
        if (a.shape(i) != b.shape(i)) {
            throw std::runtime_error("Input arrays must have the same shape.");
        }
    }

    std::vector<py::ssize_t> shape(a.ndim());
    for (py::ssize_t i = 0; i < a.ndim(); ++i) {
        shape[i] = a.shape(i);
    }

    auto result = py::array_t<uint32_t>(shape);

    py::ssize_t total = 1;
    for (py::ssize_t i = 0; i < a.ndim(); ++i) {
        total *= a.shape(i);
    }

    const uint32_t* pa = static_cast<const uint32_t*>(a.data());
    const uint32_t* pb = static_cast<const uint32_t*>(b.data());
    uint32_t* pr = static_cast<uint32_t*>(result.mutable_data());

    for (py::ssize_t i = 0; i < total; ++i) {
        pr[i] = fn(pa[i], pb[i]);
    }

    return result;
}

static py::array_t<float> multiply_float_array(
    py::array_t<float, py::array::c_style | py::array::forcecast> a,
    py::array_t<float, py::array::c_style | py::array::forcecast> b,
    const std::string& model) {

    auto fn = resolve_model_u32(model);

    if (a.ndim() != b.ndim()) {
        throw std::runtime_error("Input arrays must have the same number of dimensions.");
    }
    for (py::ssize_t i = 0; i < a.ndim(); ++i) {
        if (a.shape(i) != b.shape(i)) {
            throw std::runtime_error("Input arrays must have the same shape.");
        }
    }

    std::vector<py::ssize_t> shape(a.ndim());
    for (py::ssize_t i = 0; i < a.ndim(); ++i) {
        shape[i] = a.shape(i);
    }

    auto result = py::array_t<float>(shape);

    py::ssize_t total = 1;
    for (py::ssize_t i = 0; i < a.ndim(); ++i) {
        total *= a.shape(i);
    }

    const float* pa = static_cast<const float*>(a.data());
    const float* pb = static_cast<const float*>(b.data());
    float* pr = static_cast<float*>(result.mutable_data());

    for (py::ssize_t i = 0; i < total; ++i) {
        uint32_t ua = float_to_u32(pa[i]);
        uint32_t ub = float_to_u32(pb[i]);
        uint32_t ur = fn(ua, ub);
        pr[i] = u32_to_float(ur);
    }

    return result;
}

static py::array_t<float> dot_lastdim_float_array(
    py::array_t<float, py::array::c_style | py::array::forcecast> a,
    py::array_t<float, py::array::c_style | py::array::forcecast> b,
    const std::string& model) {

    auto fn = resolve_model_u32(model);

    if (a.ndim() < 1 || b.ndim() < 1) {
        throw std::runtime_error("Inputs must have at least 1 dimension.");
    }

    if (a.shape(a.ndim() - 1) != b.shape(b.ndim() - 1)) {
        throw std::runtime_error("Last dimension of inputs must match.");
    }

    bool b_is_vector = (b.ndim() == 1);
    if (!b_is_vector) {
        if (a.ndim() != b.ndim()) {
            throw std::runtime_error("If b is not 1D, it must have same ndim as a.");
        }
        for (py::ssize_t i = 0; i < a.ndim(); ++i) {
            if (a.shape(i) != b.shape(i)) {
                throw std::runtime_error("If b is not 1D, it must have same shape as a.");
            }
        }
    }

    std::vector<py::ssize_t> out_shape;
    for (py::ssize_t i = 0; i < a.ndim() - 1; ++i) {
        out_shape.push_back(a.shape(i));
    }

    auto result = py::array_t<float>(out_shape);

    py::ssize_t outer = 1;
    py::ssize_t inner = a.shape(a.ndim() - 1);
    for (py::ssize_t i = 0; i < a.ndim() - 1; ++i) {
        outer *= a.shape(i);
    }

    const float* pa = static_cast<const float*>(a.data());
    const float* pb = static_cast<const float*>(b.data());
    float* pr = static_cast<float*>(result.mutable_data());

    for (py::ssize_t i = 0; i < outer; ++i) {
        float acc = 0.0f;
        for (py::ssize_t j = 0; j < inner; ++j) {
            float av = pa[i * inner + j];
            float bv = b_is_vector ? pb[j] : pb[i * inner + j];

            uint32_t ua = float_to_u32(av);
            uint32_t ub = float_to_u32(bv);
            uint32_t ur = fn(ua, ub);

            acc += u32_to_float(ur);
        }
        pr[i] = acc;
    }

    return result;
}

PYBIND11_MODULE(fpmult_py, m) {
    m.doc() = "Python wrapper for approximate FP32 multipliers using u32 core models";

    m.def("multiply_u32", &multiply_u32_scalar,
          py::arg("a"), py::arg("b"), py::arg("model"),
          "Multiply two uint32 IEEE-754 bit patterns using the selected model.");

    m.def("multiply_float", &multiply_float_scalar,
          py::arg("a"), py::arg("b"), py::arg("model"),
          "Multiply two float values by bit-casting through the u32 model.");

    m.def("multiply_u32_array", &multiply_u32_array,
          py::arg("a"), py::arg("b"), py::arg("model"),
          "Multiply two uint32 NumPy arrays of IEEE-754 bit patterns.");

    m.def("multiply_float_array", &multiply_float_array,
          py::arg("a"), py::arg("b"), py::arg("model"),
          "Multiply two float NumPy arrays by bit-casting through the u32 model.");

    m.def("dot_lastdim_float_array", &dot_lastdim_float_array,
          py::arg("a"), py::arg("b"), py::arg("model"),
          "Approximate dot-product along the last dimension using u32 multiplier models.");

    m.def("supported_models", []() {
        return std::vector<std::string>{
            "viv_acc",
            "mxa1",
            "mxa2",
            "lxa",
            "lmul",
            "ssm_m12",
            "ssm_m12c",
            "ssm_m14",
            "ssm_m14c",
            "ssm_m16",
            "ssm_m16c",
            "ssm_m18",
            "ssm_m18c"
        };
    });
}

#include "fpmult_e8m23.h"

#include <functional>
#include <tuple>
#include <type_traits>
#include <typeinfo>

#include <cstdint>
#include <iostream>
#include <stdexcept>

static inline uint8_t mult_3x3_mxa(uint8_t a, uint8_t b, bool half_precision) {
  uint8_t prod = a * b;
  return half_precision ? (prod & 0x38) : prod;
}

template <uint8_t N> struct TypeResolver {
  static_assert(N == 3U || N == 6U || N == 12U || N == 24U,
                "Error: N is only allowed with 3, 6, 12, or 24.");

  using InputType = typename std::conditional<
      N <= 8U, uint8_t,
      typename std::conditional<
          N <= 16U, uint16_t,
          typename std::conditional<N <= 32U, uint32_t,
                                    uint64_t>::type>::type>::type;

  using ReturnType = typename std::conditional<
      N <= 4U, uint8_t,
      typename std::conditional<
          N <= 8U, uint16_t,
          typename std::conditional<N <= 16U, uint32_t,
                                    uint64_t>::type>::type>::type;
};

template <uint8_t N>
static inline typename TypeResolver<N>::ReturnType
mult_NxN_mxa(typename TypeResolver<N>::InputType a,
             typename TypeResolver<N>::InputType b, bool half_precision) {
  typename TypeResolver<N>::InputType a_msb, a_lsb;
  typename TypeResolver<N>::InputType b_msb, b_lsb;
  typename TypeResolver<N>::ReturnType prod_LL, prod_LH, prod_HL, prod_HH, prod;

  a_msb = (a >> (N / 2)) & max_val(typename TypeResolver<N>::InputType, N / 2);
  a_lsb = a & max_val(typename TypeResolver<N>::InputType, N / 2);

  b_msb = (b >> (N / 2)) & max_val(typename TypeResolver<N>::InputType, N / 2);
  b_lsb = b & max_val(typename TypeResolver<N>::InputType, N / 2);

  std::function<typename TypeResolver<N / 2>::ReturnType(
      typename TypeResolver<N / 2>::InputType,
      typename TypeResolver<N / 2>::InputType, bool)>
      submult_approx;

  if constexpr (N == 6U) {
    submult_approx = mult_3x3_mxa;
  } else {
    submult_approx = mult_NxN_mxa<N / 2>;
  }

  prod_LL = half_precision ? 0 : submult_approx(a_lsb, b_lsb, false);
  prod_LH = submult_approx(a_lsb, b_msb, half_precision);
  prod_HL = submult_approx(a_msb, b_lsb, half_precision);
  prod_HH = submult_approx(a_msb, b_msb, false);

  prod_LH = prod_LH << (N / 2);
  prod_HL = prod_HL << (N / 2);
  prod_HH = prod_HH << N;

  prod = prod_HH + prod_HL + prod_LH + prod_LL;

  return prod & max_val(typename TypeResolver<N>::ReturnType, 2 * N);
}

static inline uint32_t extract_bits(uint32_t value, int high, int low) {
  return (value >> low) & ((1ULL << (high - low + 1)) - 1);
}

// ============================================================
// Accurate Vivado-aligned model
// ============================================================

uint32_t fpmult_e8m23_viv_acc_u32(uint32_t a, uint32_t b) {
  myfloat_t fa, fb, fprod;
  fa.value = a;
  fb.value = b;

  const uint32_t exp_all_ones = max_val(uint32_t, EXPONENT_BITS);

  const bool a_zero = (fa.exponent == 0) && (fa.mantissa == 0);
  const bool b_zero = (fb.exponent == 0) && (fb.mantissa == 0);
  const bool zero = a_zero || b_zero;

  const bool exception = (fa.exponent == exp_all_ones) || (fb.exponent == exp_all_ones);
  const bool exception_1 =
      (fa.exponent == exp_all_ones) && ((fa.mantissa != 0) || (fb.exponent == 0));
  const bool exception_2 =
      (fb.exponent == exp_all_ones) && ((fb.mantissa != 0) || (fa.exponent == 0));

  const uint32_t result_sign = fa.sign ^ fb.sign;

  if (exception_1 || exception_2) {
    fprod.sign = 0;
    fprod.exponent = exp_all_ones;
    fprod.mantissa = 1U << (MANTISSA_BITS - 1); // quiet NaN
    return fprod.value;
  }

  if (exception) {
    fprod.sign = result_sign;
    fprod.exponent = exp_all_ones;
    fprod.mantissa = 0;
    return fprod.value;
  }

  const uint64_t sig_a = (1ULL << MANTISSA_BITS) | fa.mantissa;
  const uint64_t sig_b = (1ULL << MANTISSA_BITS) | fb.mantissa;
  const uint64_t mantissa_result = sig_a * sig_b;

  const uint64_t round2 =
      ((((mantissa_result >> (MANTISSA_BITS - 1)) & 0x3ULL) == 0x3ULL) ? 1ULL : 0ULL) +
      (((((mantissa_result >> (MANTISSA_BITS - 1)) & 0x3ULL) == 0x1ULL) &&
        ((mantissa_result & max_val(uint64_t, MANTISSA_BITS - 1)) != 0)) ? 1ULL : 0ULL);

  const uint64_t round3 =
      ((((mantissa_result >> MANTISSA_BITS) & 0x3ULL) == 0x3ULL) ? 1ULL : 0ULL) +
      (((((mantissa_result >> MANTISSA_BITS) & 0x3ULL) == 0x1ULL) &&
        ((mantissa_result & max_val(uint64_t, MANTISSA_BITS)) != 0)) ? 1ULL : 0ULL);

  const uint64_t mantissa_rounded_2b =
      (mantissa_result >> MANTISSA_BITS) + round2;

  const uint64_t mantissa_rounded_3b =
      (mantissa_result >> (MANTISSA_BITS + 1)) + round3;

  const uint16_t exp_sum =
      (uint16_t)((int)fa.exponent + (int)fb.exponent - EXPONENT_BIAS);

  const bool normalized =
      ((mantissa_rounded_3b >> MANTISSA_BITS) & 0x1ULL);

  const uint32_t mantissa_final =
      normalized
          ? ((uint32_t)mantissa_rounded_3b & max_val(uint32_t, MANTISSA_BITS))
          : ((uint32_t)mantissa_rounded_2b & max_val(uint32_t, MANTISSA_BITS));

  const uint16_t exp_final = normalized ? (uint16_t)(exp_sum + 1) : exp_sum;

  const bool underflow =
      ((((exp_sum >> EXPONENT_BITS) & 1U) && ((exp_sum >> (EXPONENT_BITS - 1)) & 1U)) ||
       (fa.exponent == 0) || (fb.exponent == 0) || (exp_final == 0));

  const bool overflow =
      ((((exp_final >> EXPONENT_BITS) & 1U) && !((exp_final >> (EXPONENT_BITS - 1)) & 1U)) ||
       ((exp_final & exp_all_ones) == exp_all_ones));

  if (zero || underflow) {
    fprod.sign = result_sign;
    fprod.exponent = 0;
    fprod.mantissa = 0;
    return fprod.value;
  }

  if (overflow) {
    fprod.sign = result_sign;
    fprod.exponent = exp_all_ones;
    fprod.mantissa = 0;
    return fprod.value;
  }

  fprod.sign = result_sign;
  fprod.exponent = exp_final & exp_all_ones;
  fprod.mantissa = mantissa_final;
  return fprod.value;
}

float fpmult_e8m23_viv_acc(float a, float b) {
  myfloat_t fa, fb, fprod;
  fa.fvalue = a;
  fb.fvalue = b;
  fprod.value = fpmult_e8m23_viv_acc_u32(fa.value, fb.value);
  return fprod.fvalue;
}

// ============================================================
// MXA1
// ============================================================

uint32_t fpmult_e8m23_mxa1_u32(uint32_t a, uint32_t b) {
  myfloat_t fa;
  myfloat_t fb;
  myfloat_t fprod;

  fa.value = a;
  fb.value = b;

  bool zero = (fa.exponent == 0 && fa.mantissa == 0) ||
              (fb.exponent == 0 && fb.mantissa == 0);

  uint32_t operand_a = (1U << MANTISSA_BITS) | fa.mantissa;
  uint32_t operand_b = (1U << MANTISSA_BITS) | fb.mantissa;

  uint32_t product = (uint32_t)(mult_NxN_mxa<24>(operand_a, operand_b, true) >>
                                (MANTISSA_BITS + 1));

  bool normalize = !(product & (1U << MANTISSA_BITS));
  if (normalize) {
    product = product << 1;
  }

  fprod.mantissa = product & max_val(uint32_t, MANTISSA_BITS);
  uint32_t prod_exponent = (uint32_t)((int)fa.exponent + (int)fb.exponent -
                                      (normalize ? 0x7F : 0x7E));

  fprod.exponent = (uint8_t)prod_exponent;
  fprod.sign = fa.sign ^ fb.sign;

  if (zero) {
    fprod.mantissa = 0;
    fprod.exponent = 0;
  }

  return fprod.value;
}

float fpmult_e8m23_mxa1(float a, float b) {
  myfloat_t fa, fb, fprod;
  fa.fvalue = a;
  fb.fvalue = b;
  fprod.value = fpmult_e8m23_mxa1_u32(fa.value, fb.value);
  return fprod.fvalue;
}

// ============================================================
// MXA2
// ============================================================
static uint8_t mult_3x3_mxa2(uint8_t a, uint8_t b) {
  uint8_t result = 0;
  const uint8_t N = 3;
  uint8_t pp[N];
  a &= max_val(uint8_t, N);
  b &= max_val(uint8_t, N);
  for (int i = 0; i < N; i++) {
    if (b & (1U << i)) {
      pp[i] = (uint8_t)(a << i);
    } else {
      pp[i] = 0U;
    }
  }
  for (int i = 0; i < N; i++) {
    result += pp[i] & (max_val(uint8_t, 2 * N) - max_val(uint8_t, N));
  }
  return result;
}

static uint16_t mult_6x6_mxa2(uint8_t a, uint8_t b) {
  uint16_t result = 0;
  const uint8_t N = 6;
  uint16_t pp[N];
  a &= max_val(uint8_t, N);
  b &= max_val(uint8_t, N);
  for (int i = 0; i < N; i++) {
    if (b & (1U << i)) {
      pp[i] = (uint16_t)((uint16_t)a << i);
    } else {
      pp[i] = 0U;
    }
  }
  for (int i = 0; i < N; i++) {
    result += pp[i] & (max_val(uint16_t, 2 * N) - max_val(uint16_t, N));
  }
  return result;
}

static uint32_t mult_12x12_mxa2(uint16_t a, uint16_t b) {
  uint32_t result = 0;
  const uint8_t N = 12;
  uint32_t pp[N];
  a &= max_val(uint16_t, N);
  b &= max_val(uint16_t, N);
  for (int i = 0; i < N; i++) {
    if (b & (1U << i)) {
      pp[i] = (uint32_t)((uint32_t)a << i);
    } else {
      pp[i] = 0U;
    }
  }
  for (int i = 0; i < N; i++) {
    result += pp[i] & (max_val(uint32_t, 2 * N) - max_val(uint32_t, N));
  }
  return result;
}

static uint64_t mult_24x24_mxa2(uint32_t a, uint32_t b) {
  uint64_t result = 0;
  const uint8_t N = 24;
  uint64_t pp[N];

  for (int i = 0; i < N; i++) {
    if (b & (1ULL << i)) {
      pp[i] = (uint64_t)a << i;
    } else {
      pp[i] = 0ULL;
    }
  }

  for (int i = 0; i < N; i++) {
    result += pp[i] & (max_val(uint64_t, 2 * N) - max_val(uint64_t, N));
  }

  return result;
}

uint32_t fpmult_e8m23_mxa2_u32(uint32_t a, uint32_t b) {
  myfloat_t fa;
  myfloat_t fb;
  myfloat_t fprod;

  fa.value = a;
  fb.value = b;

  bool zero = (fa.exponent == 0 && fa.mantissa == 0) ||
              (fb.exponent == 0 && fb.mantissa == 0);

  uint32_t operand_a = (1U << MANTISSA_BITS) | fa.mantissa;
  uint32_t operand_b = (1U << MANTISSA_BITS) | fb.mantissa;

  uint32_t product =
      (uint32_t)(mult_24x24_mxa2(operand_a, operand_b) >> (MANTISSA_BITS + 1));

  bool normalize = !(product & (1U << MANTISSA_BITS));
  if (normalize) {
    product = product << 1;
  }

  fprod.mantissa = product & max_val(uint32_t, MANTISSA_BITS);
  uint32_t prod_exponent = (uint32_t)((int)fa.exponent + (int)fb.exponent -
                                      (normalize ? 0x7F : 0x7E));

  fprod.exponent = (uint8_t)prod_exponent;
  fprod.sign = fa.sign ^ fb.sign;

  if (zero) {
    fprod.mantissa = 0;
    fprod.exponent = 0;
  }

  return fprod.value;
}

float fpmult_e8m23_mxa2(float a, float b) {
  myfloat_t fa, fb, fprod;
  fa.fvalue = a;
  fb.fvalue = b;
  fprod.value = fpmult_e8m23_mxa2_u32(fa.value, fb.value);
  return fprod.fvalue;
}

// ============================================================
// LXA1
// ============================================================

static uint64_t mult_24x24_lxa(uint32_t a, uint32_t b) {
  uint64_t result = 0;
  const uint8_t N = 24;
  uint64_t pp[N];
  uint64_t pp_l1[N / 2];

  uint8_t sum_k5 = 0;

  for (int i = 0; i < N; i++) {
    if (b & (1ULL << i)) {
      pp[i] = (uint64_t)a << i;
    } else {
      pp[i] = 0ULL;
    }
  }

  for (int i = 0; i < N / 2; i++) {
    pp_l1[i] =
        (pp[2 * i] & (max_val(uint64_t, 2 * N) - max_val(uint64_t, N - 5))) +
        (pp[2 * i + 1] &
         (max_val(uint64_t, 2 * N) - max_val(uint64_t, N - 5)));
    if (i < 6) {
      pp_l1[i] += 1ULL << (N - 5);
    }
  }

  for (int i = 0; i < N / 2; i++) {
    result += pp_l1[i] & (max_val(uint64_t, 2 * N) - max_val(uint64_t, N - 4));
    sum_k5 += (pp_l1[i] >> (N - 5)) & 1ULL;
  }

  return (result + ((uint64_t)sum_k5 << (N - 4))) &
         (max_val(uint64_t, 2 * N) - max_val(uint64_t, N - 1));
}

uint32_t fpmult_e8m23_lxa_u32(uint32_t a, uint32_t b) {
  myfloat_t fa;
  myfloat_t fb;
  myfloat_t fprod;

  fa.value = a;
  fb.value = b;

  bool zero = (fa.exponent == 0 && fa.mantissa == 0) ||
              (fb.exponent == 0 && fb.mantissa == 0);

  uint32_t operand_a = (1U << MANTISSA_BITS) | fa.mantissa;
  uint32_t operand_b = (1U << MANTISSA_BITS) | fb.mantissa;

  uint32_t product =
      (uint32_t)(mult_24x24_lxa(operand_a, operand_b) >> MANTISSA_BITS);

  bool normalized = !!(product & (1U << (MANTISSA_BITS + 1)));
  if (normalized) {
    product = product >> 1;
  }

  fprod.mantissa = product & max_val(uint32_t, MANTISSA_BITS);
  uint32_t prod_exponent = (uint32_t)((int)fa.exponent + (int)fb.exponent -
                                      (normalized ? 0x7E : 0x7F));
  fprod.exponent = (uint8_t)prod_exponent;
  fprod.sign = fa.sign ^ fb.sign;

  if (zero) {
    fprod.mantissa = 0;
    fprod.exponent = 0;
  }

  return fprod.value;
}

float fpmult_e8m23_lxa(float a, float b) {
  myfloat_t fa, fb, fprod;
  fa.fvalue = a;
  fb.fvalue = b;
  fprod.value = fpmult_e8m23_lxa_u32(fa.value, fb.value);
  return fprod.fvalue;
}

// ============================================================
// LMUL
// ============================================================

uint32_t fpmult_e8m23_lmul_u32(uint32_t a, uint32_t b) {
  myfloat_t fa;
  myfloat_t fb;
  myfloat_t fprod;

  fa.value = a;
  fb.value = b;

  fprod.sign = fa.sign ^ fb.sign;
  fprod.mantissa = 0;
  fprod.exponent = 0;

  fa.sign = 0;
  fb.sign = 0;

  fprod.value |= (uint32_t)(fa.value + fb.value - 0x3F780000) & 0x7FFFFFFFU;

  return fprod.value;
}

float fpmult_e8m23_lmul(float a, float b) {
  myfloat_t fa, fb, fprod;
  fa.fvalue = a;
  fb.fvalue = b;
  fprod.value = fpmult_e8m23_lmul_u32(fa.value, fb.value);
  return fprod.fvalue;
}

// ============================================================
// SSM helpers
// ============================================================

template <int m, bool WithCorrection>
static uint32_t mult_23x23_ssm(uint32_t a, uint32_t b) {
  constexpr int m_min = 12;
  constexpr int m_max = 18;
  static_assert(m % 2 == 0, "m must be even");
  static_assert(m >= m_min && m <= m_max, "m must be 12, 14, 16 or 18");

  a &= 0x7FFFFF;
  b &= 0x7FFFFF;

  const int slice_hi = 22;
  const int slice_lo = 22 - (m - 1);
  const int m_half = m / 2;
  const int m_diff = m - m_min;

  uint8_t alfa_a = extract_bits(a, slice_hi, m) > 0;
  uint8_t alfa_b = extract_bits(b, slice_hi, m) > 0;
  int case_sel = (alfa_a << 1) | alfa_b;

  uint32_t assm = 0, bssm = 0, assum = 0, bssum = 0;

  switch (case_sel) {
  case 0:
    assm = m_diff > 0 ? extract_bits(a, m_min - 1 + m_diff, m_min) : 0;
    bssm = extract_bits(b, m_min - 1 + m_diff, m_min - 1);
    assum = extract_bits(a, m_min - 1 + m_diff, 0);
    bssum = extract_bits(b, m_min - 1 + m_diff, 0);
    break;
  case 1:
    assm = m_diff > 0 ? extract_bits(a, m_min - 1 + m_diff, m_min) : 0;
    bssm = extract_bits(b, slice_hi, slice_hi - m_diff);
    assum = extract_bits(a, m_min - 1 + m_diff, slice_lo);
    bssum = extract_bits(b, slice_hi, slice_lo);
    break;
  case 2:
    assm = m_diff > 0 ? extract_bits(a, slice_hi, slice_hi - m_diff + 1) : 0;
    bssm = extract_bits(b, m_min - 1 + m_diff, m_min - 1);
    assum = extract_bits(a, slice_hi, slice_lo);
    bssum = extract_bits(b, m_min - 1 + m_diff, slice_lo);
    break;
  case 3:
    assm = extract_bits(a, slice_hi, slice_lo + m_half);
    bssm = extract_bits(b, slice_hi, slice_lo + m_half);
    assum = extract_bits(a, slice_hi, slice_lo);
    bssum = extract_bits(b, slice_hi, slice_lo);
    break;
  }

  uint32_t correction_MSP = 0;
  if constexpr (WithCorrection) {
    bool f11 = alfa_a && alfa_b;

    int corr_bit1 = slice_lo + m_half - 1;
    int corr_bit2 = slice_hi;
    bool bit_H = ((((a >> corr_bit1) & 1) && ((b >> corr_bit2) & 1)) ||
                  (((b >> corr_bit1) & 1) && ((a >> corr_bit2) & 1))) &&
                 f11;
    bool bit_L = ((((a >> corr_bit1) & 1) && ((b >> (corr_bit2 - 1)) & 1)) ||
                  (((b >> corr_bit1) & 1) && ((a >> (corr_bit2 - 1)) & 1))) &&
                 f11;
    correction_MSP =
        ((uint32_t)bit_H << (m_half - 1)) | ((uint32_t)bit_L << (m_half - 2));
  }

  uint32_t mac_ssm = assm * bssm + assum + bssum + correction_MSP;

  uint32_t ris = 0;
  if (case_sel == 0) {
    ris = (mac_ssm << 1);
  } else {
    ris = (mac_ssm << (24 - m));
  }
  ris &= 0x3FFFFFF;
  return ris;
}

template <int m, bool WithCorrection>
static uint32_t fpmult_e8m23_ssm_impl_u32(uint32_t a, uint32_t b) {
  myfloat_t fa;
  myfloat_t fb;
  myfloat_t fprod;

  fa.value = a;
  fb.value = b;

  bool zero = (fa.exponent == 0 && fa.mantissa == 0) ||
              (fb.exponent == 0 && fb.mantissa == 0);

  uint32_t raw_product = mult_23x23_ssm<m, WithCorrection>(fa.mantissa, fb.mantissa);
  uint32_t product =
      extract_bits(raw_product, MANTISSA_BITS + 1, 0) ^ (1U << (MANTISSA_BITS + 1));

  bool normalized =
      extract_bits(raw_product, MANTISSA_BITS + 2, MANTISSA_BITS + 1) > 0;
  fprod.mantissa = normalized ? extract_bits(product, MANTISSA_BITS + 1, 2)
                              : extract_bits(product, MANTISSA_BITS, 1);

  uint32_t prod_exponent = (uint32_t)((int)fa.exponent + (int)fb.exponent -
                                      (normalized ? 0x7E : 0x7F));
  fprod.exponent = (uint8_t)prod_exponent;

  fprod.sign = fa.sign ^ fb.sign;

  if (zero) {
    fprod.mantissa = 0;
    fprod.exponent = 0;
  }

  return fprod.value;
}

template <int m, bool WithCorrection>
static float fpmult_e8m23_ssm_impl(float a, float b) {
  myfloat_t fa, fb, fprod;
  fa.fvalue = a;
  fb.fvalue = b;
  fprod.value = fpmult_e8m23_ssm_impl_u32<m, WithCorrection>(fa.value, fb.value);
  return fprod.fvalue;
}

// ============================================================
// SSM wrappers
// ============================================================

uint32_t fpmult_e8m23_ssm_m12_u32(uint32_t a, uint32_t b) {
  return fpmult_e8m23_ssm_impl_u32<12, false>(a, b);
}
float fpmult_e8m23_ssm_m12(float a, float b) {
  return fpmult_e8m23_ssm_impl<12, false>(a, b);
}

uint32_t fpmult_e8m23_ssm_m12c_u32(uint32_t a, uint32_t b) {
  return fpmult_e8m23_ssm_impl_u32<12, true>(a, b);
}
float fpmult_e8m23_ssm_m12c(float a, float b) {
  return fpmult_e8m23_ssm_impl<12, true>(a, b);
}

uint32_t fpmult_e8m23_ssm_m14_u32(uint32_t a, uint32_t b) {
  return fpmult_e8m23_ssm_impl_u32<14, false>(a, b);
}
float fpmult_e8m23_ssm_m14(float a, float b) {
  return fpmult_e8m23_ssm_impl<14, false>(a, b);
}

uint32_t fpmult_e8m23_ssm_m14c_u32(uint32_t a, uint32_t b) {
  return fpmult_e8m23_ssm_impl_u32<14, true>(a, b);
}
float fpmult_e8m23_ssm_m14c(float a, float b) {
  return fpmult_e8m23_ssm_impl<14, true>(a, b);
}

uint32_t fpmult_e8m23_ssm_m16_u32(uint32_t a, uint32_t b) {
  return fpmult_e8m23_ssm_impl_u32<16, false>(a, b);
}
float fpmult_e8m23_ssm_m16(float a, float b) {
  return fpmult_e8m23_ssm_impl<16, false>(a, b);
}

uint32_t fpmult_e8m23_ssm_m16c_u32(uint32_t a, uint32_t b) {
  return fpmult_e8m23_ssm_impl_u32<16, true>(a, b);
}
float fpmult_e8m23_ssm_m16c(float a, float b) {
  return fpmult_e8m23_ssm_impl<16, true>(a, b);
}

uint32_t fpmult_e8m23_ssm_m18_u32(uint32_t a, uint32_t b) {
  return fpmult_e8m23_ssm_impl_u32<18, false>(a, b);
}
float fpmult_e8m23_ssm_m18(float a, float b) {
  return fpmult_e8m23_ssm_impl<18, false>(a, b);
}

uint32_t fpmult_e8m23_ssm_m18c_u32(uint32_t a, uint32_t b) {
  return fpmult_e8m23_ssm_impl_u32<18, true>(a, b);
}
float fpmult_e8m23_ssm_m18c(float a, float b) {
  return fpmult_e8m23_ssm_impl<18, true>(a, b);
}

// ============================================================
// Integer exact helpers
// ============================================================
uint8_t mult_3x3_acc1_u8(uint8_t a, uint8_t b) { return (uint8_t)(a * b); }
uint8_t mult_3x3_acc2_u8(uint8_t a, uint8_t b) { return (uint8_t)(a * b); }
uint16_t mult_6x6_acc1_u16(uint8_t a, uint8_t b) { return (uint16_t)(a * b); }
uint16_t mult_6x6_acc2_u16(uint8_t a, uint8_t b) { return (uint16_t)(a * b); }
uint32_t mult_12x12_acc1_u32(uint16_t a, uint16_t b) { return (uint32_t)(a * b); }
uint32_t mult_12x12_acc2_u32(uint16_t a, uint16_t b) { return (uint32_t)(a * b); }
uint64_t mult_24x24_acc1_u64(uint32_t a, uint32_t b) {
  return ((uint64_t)(a & 0xFFFFFFU)) * ((uint64_t)(b & 0xFFFFFFU));
}
uint64_t mult_24x24_acc2_u64(uint32_t a, uint32_t b) {
  return ((uint64_t)(a & 0xFFFFFFU)) * ((uint64_t)(b & 0xFFFFFFU));
}
// ============================================================
// Integer MXA / LXA helpers
// ============================================================
uint8_t mult_3x3_mxa1_u8(uint8_t a, uint8_t b) {
  return mult_3x3_mxa(a & 0x7U, b & 0x7U, true);
}
uint16_t mult_6x6_mxa1_u16(uint8_t a, uint8_t b) {
  return mult_NxN_mxa<6>(a & 0x3FU, b & 0x3FU, true);
}
uint32_t mult_12x12_mxa1_u32(uint16_t a, uint16_t b) {
  return mult_NxN_mxa<12>(a & 0x0FFFU, b & 0x0FFFU, true);
}
uint64_t mult_24x24_mxa1_u64(uint32_t a, uint32_t b) {
  return mult_NxN_mxa<24>(a & 0xFFFFFFU, b & 0xFFFFFFU, true);
}
uint8_t mult_3x3_mxa2_u8(uint8_t a, uint8_t b) {
  return mult_3x3_mxa2(a & 0x7U, b & 0x7U);
}
uint16_t mult_6x6_mxa2_u16(uint8_t a, uint8_t b) {
  return mult_6x6_mxa2(a & 0x3FU, b & 0x3FU);
}
uint32_t mult_12x12_mxa2_u32(uint16_t a, uint16_t b) {
  return mult_12x12_mxa2(a & 0x0FFFU, b & 0x0FFFU);
}
uint64_t mult_24x24_mxa2_u64(uint32_t a, uint32_t b) {
  return mult_24x24_mxa2(a & 0xFFFFFFU, b & 0xFFFFFFU);
}
uint64_t mult_24x24_lxa_u64(uint32_t a, uint32_t b) {
  return mult_24x24_lxa(a & 0xFFFFFFU, b & 0xFFFFFFU);
}

// ============================================================
// SSM 23x23 helpers
// ============================================================
uint64_t mult_23x23_ssm_m12_u64(uint32_t a, uint32_t b) {
  return ((uint64_t)mult_23x23_ssm<12, false>(a, b)) << 20;
}
uint64_t mult_23x23_ssm_m12c_u64(uint32_t a, uint32_t b) {
  return ((uint64_t)mult_23x23_ssm<12, true>(a, b)) << 20;
}
uint64_t mult_23x23_ssm_m14_u64(uint32_t a, uint32_t b) {
  return ((uint64_t)mult_23x23_ssm<14, false>(a, b)) << 20;
}
uint64_t mult_23x23_ssm_m14c_u64(uint32_t a, uint32_t b) {
  return ((uint64_t)mult_23x23_ssm<14, true>(a, b)) << 20;
}
uint64_t mult_23x23_ssm_m16_u64(uint32_t a, uint32_t b) {
  return ((uint64_t)mult_23x23_ssm<16, false>(a, b)) << 20;
}
uint64_t mult_23x23_ssm_m16c_u64(uint32_t a, uint32_t b) {
  return ((uint64_t)mult_23x23_ssm<16, true>(a, b)) << 20;
}
uint64_t mult_23x23_ssm_m18_u64(uint32_t a, uint32_t b) {
  return ((uint64_t)mult_23x23_ssm<18, false>(a, b)) << 20;
}
uint64_t mult_23x23_ssm_m18c_u64(uint32_t a, uint32_t b) {
  return ((uint64_t)mult_23x23_ssm<18, true>(a, b)) << 20;
}

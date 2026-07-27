#ifndef FPMULT32_APPROX_H
#define FPMULT32_APPROX_H

#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

#ifndef EXPONENT_BITS
#define EXPONENT_BITS 8
#endif

#ifndef MANTISSA_BITS
#define MANTISSA_BITS 23
#endif

#define EXPONENT_BIAS ((1U << (EXPONENT_BITS - 1)) - 1)

#if EXPONENT_BITS + MANTISSA_BITS + 1 > 32
#error "EXPONENT_BITS + MANTISSA_BITS + 1 must be <= 32-bits!"
#endif

#define max_val(type, N) ((type)((1ULL << (N)) - 1))

struct myfloat {
  union {
    struct {
      uint32_t mantissa : MANTISSA_BITS;
      uint32_t exponent : EXPONENT_BITS;
      uint32_t sign : 1;
    };
    uint32_t value;
    float fvalue;
  };
} __attribute__((__packed__));

typedef struct myfloat myfloat_t;

// Canonical names
uint32_t fpmult_e8m23_viv_acc_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_viv_acc(float a, float b);

uint32_t fpmult_e8m23_mxa1_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_mxa1(float a, float b);

uint32_t fpmult_e8m23_mxa2_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_mxa2(float a, float b);

uint32_t fpmult_e8m23_lxa_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_lxa(float a, float b);

uint32_t fpmult_e8m23_lmul_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_lmul(float a, float b);

uint32_t fpmult_e8m23_ssm_m12_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_ssm_m12(float a, float b);

uint32_t fpmult_e8m23_ssm_m12c_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_ssm_m12c(float a, float b);

uint32_t fpmult_e8m23_ssm_m14_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_ssm_m14(float a, float b);

uint32_t fpmult_e8m23_ssm_m14c_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_ssm_m14c(float a, float b);

uint32_t fpmult_e8m23_ssm_m16_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_ssm_m16(float a, float b);

uint32_t fpmult_e8m23_ssm_m16c_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_ssm_m16c(float a, float b);

uint32_t fpmult_e8m23_ssm_m18_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_ssm_m18(float a, float b);

uint32_t fpmult_e8m23_ssm_m18c_u32(uint32_t a, uint32_t b);
float    fpmult_e8m23_ssm_m18c(float a, float b);

// ============================================================
// Integer exact helpers
// ============================================================
uint8_t  mult_3x3_acc1_u8(uint8_t a, uint8_t b);
uint8_t  mult_3x3_acc2_u8(uint8_t a, uint8_t b);
uint16_t mult_6x6_acc1_u16(uint8_t a, uint8_t b);
uint16_t mult_6x6_acc2_u16(uint8_t a, uint8_t b);
uint32_t mult_12x12_acc1_u32(uint16_t a, uint16_t b);
uint32_t mult_12x12_acc2_u32(uint16_t a, uint16_t b);
uint64_t mult_24x24_acc1_u64(uint32_t a, uint32_t b);
uint64_t mult_24x24_acc2_u64(uint32_t a, uint32_t b);
// ============================================================
// Integer MXA / LXA helpers
// ============================================================
uint8_t  mult_3x3_mxa1_u8(uint8_t a, uint8_t b);
uint8_t  mult_3x3_mxa2_u8(uint8_t a, uint8_t b);
uint16_t mult_6x6_mxa1_u16(uint8_t a, uint8_t b);
uint16_t mult_6x6_mxa2_u16(uint8_t a, uint8_t b);
uint32_t mult_12x12_mxa1_u32(uint16_t a, uint16_t b);
uint32_t mult_12x12_mxa2_u32(uint16_t a, uint16_t b);
uint64_t mult_24x24_mxa1_u64(uint32_t a, uint32_t b);
uint64_t mult_24x24_mxa2_u64(uint32_t a, uint32_t b);
uint64_t mult_24x24_lxa_u64(uint32_t a, uint32_t b);
// ============================================================
// SSM 23x23 helpers
// Returned as 64-bit values representing a 46-bit product domain
// ============================================================
uint64_t mult_23x23_ssm_m12_u64(uint32_t a, uint32_t b);
uint64_t mult_23x23_ssm_m12c_u64(uint32_t a, uint32_t b);
uint64_t mult_23x23_ssm_m14_u64(uint32_t a, uint32_t b);
uint64_t mult_23x23_ssm_m14c_u64(uint32_t a, uint32_t b);
uint64_t mult_23x23_ssm_m16_u64(uint32_t a, uint32_t b);
uint64_t mult_23x23_ssm_m16c_u64(uint32_t a, uint32_t b);
uint64_t mult_23x23_ssm_m18_u64(uint32_t a, uint32_t b);
uint64_t mult_23x23_ssm_m18c_u64(uint32_t a, uint32_t b);

#endif // FPMULT32_APPROX_H

/*
 * Apache_HW Instruction Set Architecture (ISA)
 * PE Core Instruction Format
 * 
 * Instruction Format (32 bits):
 * ┌────────────────────────────────────────┐
 * │ 31   28 │ 27    16 │ 15     8 │ 7    0 │
 * ├─────────┼──────────┼──────────┼────────┤
 * │  OPCODE │ Reserved │ Reserved │  TYPE  │
 * └─────────┴──────────┴──────────┴────────┘
 *
 * OPCODE (bits[31:28]):
 *   0x1 (0001) - MAC:   Multiply-Accumulate
 *   0x2 (0010) - ACT:   Activation Function
 *   0x3 (0011) - NORM:  Normalization
 *   0x4 (0100) - LOAD:  Load from memory
 *   0x5 (0101) - STORE: Store to memory
 *   0x6 (0110) - MOVE:  Move data
 *   0x7 (0111) - NOP:   No operation
 *
 * TYPE (bits[7:0]) - for ACT:
 *   0x00 - ReLU
 *   0x01 - GELU
 *   0x02 - Sigmoid
 *   0x03 - Tanh
 *   0x04 - LeakyReLU
 *   0x05 - SiLU
 *
 * TYPE (bits[7:0]) - for NORM:
 *   0x00 - LayerNorm
 *   0x01 - RMSNorm
 *   0x02 - GroupNorm
 */

#ifndef ISA_H
#define ISA_H

#include <stdint.h>
#include <string.h>

// ==========================================
// OPCODE Definitions
// ==========================================
#define OPCODE_MAC    0x1
#define OPCODE_ACT    0x2
#define OPCODE_NORM   0x3
#define OPCODE_LOAD   0x4
#define OPCODE_STORE  0x5
#define OPCODE_MOVE   0x6
#define OPCODE_NOP    0x7

// ==========================================
// Activation Function Types
// ==========================================
#define ACT_RELU      0x00
#define ACT_GELU      0x01
#define ACT_SIGMOID   0x02
#define ACT_TANH      0x03
#define ACT_LEAKY_RELU 0x04
#define ACT_SILU      0x05

// ==========================================
// Normalization Types
// ==========================================
#define NORM_LAYER    0x00
#define NORM_RMS      0x01
#define NORM_GROUP    0x02

// ==========================================
// Instruction Structure
// ==========================================
typedef struct {
    uint8_t  opcode;    // bits[31:28]
    uint8_t  type;     // bits[7:0]
    uint16_t reserved;  // bits[27:8]
} instruction_t;

// ==========================================
// Instruction Encoding Macros
// ==========================================
#define ENCODE(opcode, type) \
    ((((opcode) & 0xF) << 28) | ((type) & 0xFF))

// MAC Operations
#define INST_MAC()           ENCODE(OPCODE_MAC, 0x00)
#define INST_ACT(type)       ENCODE(OPCODE_ACT, type)
#define INST_NORM(type)      ENCODE(OPCODE_NORM, type)
#define INST_LOAD(addr)      ENCODE(OPCODE_LOAD, (addr) & 0xFF)
#define INST_STORE(addr)     ENCODE(OPCODE_STORE, (addr) & 0xFF)
#define INST_MOVE(src, dst)  ENCODE(OPCODE_MOVE, ((src) << 4) | ((dst) & 0xF))
#define INST_NOP()            ENCODE(OPCODE_NOP, 0x00)

// ==========================================
// Helper Functions
// ==========================================
static inline const char* opcode_to_str(uint8_t opcode) {
    switch (opcode) {
        case OPCODE_MAC:   return "MAC";
        case OPCODE_ACT:   return "ACT";
        case OPCODE_NORM:  return "NORM";
        case OPCODE_LOAD:  return "LOAD";
        case OPCODE_STORE: return "STORE";
        case OPCODE_MOVE:  return "MOVE";
        case OPCODE_NOP:   return "NOP";
        default:           return "UNKNOWN";
    }
}

static inline const char* act_type_to_str(uint8_t type) {
    switch (type) {
        case ACT_RELU:      return "ReLU";
        case ACT_GELU:      return "GELU";
        case ACT_SIGMOID:   return "Sigmoid";
        case ACT_TANH:      return "Tanh";
        case ACT_LEAKY_RELU: return "LeakyReLU";
        case ACT_SILU:      return "SiLU";
        default:           return "Unknown";
    }
}

static inline const char* norm_type_to_str(uint8_t type) {
    switch (type) {
        case NORM_LAYER:  return "LayerNorm";
        case NORM_RMS:    return "RMSNorm";
        case NORM_GROUP:  return "GroupNorm";
        default:         return "Unknown";
    }
}

#endif // ISA_H

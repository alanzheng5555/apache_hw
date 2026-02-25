/*
 * Apache_HW Test Program
 * Example: Matrix Multiply + Activation
 * 
 * This program demonstrates:
 * 1. Matrix multiplication (MAC operations)
 * 2. Activation function (ReLU/GELU)
 * 3. Normalization (LayerNorm)
 */

// ==========================================
// High-Level Syntax
// ==========================================
// The compiler accepts a C-like syntax:
//
// mac();              // Matrix multiply-accumulate
// act(relu);          // ReLU activation
// act(gelu);          // GELU activation
// norm(layernorm);    // Layer normalization
// norm(rmsnorm);      // RMS normalization
// load(0x00);         // Load from address 0x00
// store(0x10);        // Store to address 0x10
// nop();              // No operation

// ==========================================
// Example Programs
// ==========================================

// Program 1: Simple ReLU Activation
program_relu:
    act(relu);
    nop();

// Program 2: GELU Activation
program_gelu:
    act(gelu);
    nop();

// Program 3: LayerNorm
program_layernorm:
    norm(layernorm);
    nop();

// Program 4: Full Inference Step (Matrix Multiply -> Activation)
program_inference:
    mac();
    act(relu);
    norm(layernorm);
    nop();

// Program 5: Transformer Feed-Forward
program_ffn:
    mac();        // Linear 1
    act(gelu);    // GELU
    mac();        // Linear 2
    nop();

// ==========================================
// Equivalent Binary Output
// ==========================================
// This is what the compiler generates:
//
// Address  Opcode     Type      Binary
// 0x00     MAC        0x00      0x10000000
// 0x01     ACT        ReLU     0x20000000
// 0x02     NORM       Layer    0x30000000
// 0x03     NOP        0x00      0x70000000

/*
 * Compile with:
 *   gcc -o compiler compiler.c
 *   ./compiler matrix_test.c -o matrix_test.bin -a matrix_test.asm
 *
 * Or use the Makefile:
 *   make
 *   ./compiler examples/matrix_test.c -o output.bin
 */

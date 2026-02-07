# PE Core ESL Model (SystemC)

This directory contains the Electronic System Level (ESL) model of the PE Core,
implemented in SystemC for fast simulation and architectural exploration.

## Directory Structure

```
esl/
├── Makefile              # Build script
├── README.md             # This file
├── tb_pe_sc.cpp          # Main testbench
├── pe_top_sc.h           # PE Top module (integrates all sub-modules)
├── mac_array_sc.h        # MAC Array model
├── activation_unit_sc.h  # Activation functions (ReLU, GELU, Sigmoid, Tanh)
└── normalization_unit_sc.h # Normalization (LayerNorm, RMSNorm)
```

## Features

### Supported Operations
- **MAC (Multiply-Accumulate)**: Matrix multiplication with accumulation
- **Activation Functions**:
  - ReLU (Rectified Linear Unit)
  - GELU (Gaussian Error Linear Unit)
  - Sigmoid
  - Tanh
- **Normalization**:
  - Layer Normalization
  - RMS Normalization

### Configuration
| Parameter | Default | Description |
|-----------|---------|-------------|
| DATA_WIDTH | 32 | Data width in bits (FP32) |
| VECTOR_WIDTH | 16 | Vector size |
| MAC_ROWS | 8 | MAC array rows |
| MAC_COLS | 8 | MAC array columns |

## Requirements

- **SystemC**: Version 2.3.0 or later
- **C++ Compiler**: GCC with C++14 support

## Setup

Set the `SYSTEMC_HOME` environment variable to your SystemC installation path:

```bash
export SYSTEMC_HOME=/usr/local/systemc-2.3.3
```

## Building

```bash
cd esl
make
```

## Running Tests

```bash
make run
```

## Expected Output

```
========================================
PE Core ESL Model Testbench (SystemC)
========================================
Configuration: DATA_WIDTH=32, VECTOR_WIDTH=16, MAC=8x8
========================================

--- Test 0: MAC Operation ---
MAC Test completed

--- Test 1: ReLU Activation ---
ReLU Test completed

--- Test 2: Layer Normalization ---
Normalization Test completed

...

========================================
REGRESSION RESULTS
========================================
Total Tests:  6
Passed:       6
Failed:       0
Pass Rate:    100%
========================================
SUCCESS: All tests passed!
```

## Architecture

```
┌─────────────────────────────────────────┐
│            pe_top_sc (PE Top)           │
│  ┌─────────────────────────────────────┐│
│  │          mac_array_sc                 ││
│  │    (MAC_ROWS x MAC_COLS matrix)      ││
│  └─────────────────────────────────────┘│
│                   │                     │
│                   ▼                     │
│  ┌─────────────────────────────────────┐│
│  │       activation_unit_sc            ││
│  │   (ReLU/GELU/Sigmoid/Tanh)          ││
│  └─────────────────────────────────────┘│
│                   │                     │
│                   ▼                     │
│  ┌─────────────────────────────────────┐│
│  │     normalization_unit_sc           ││
│  │     (LayerNorm/RMSNorm)             ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

## Use Cases

1. **Architecture Exploration**: Quickly evaluate different MAC array sizes
2. **Algorithm Development**: Test new activation/norm functions
3. **Performance Modeling**: Estimate cycle counts and throughput
4. **Software Development**: Validate software stacks before RTL is ready

## Differences from RTL

| Aspect | RTL (Verilog) | ESL (SystemC) |
|--------|---------------|---------------|
| Precision | Bit-accurate | Functional only |
| Speed | Slow | Fast |
| Flexibility | Fixed | Parameterized |
| Use Case | Verification | Modeling |

## License

Same as Apache_HW project.

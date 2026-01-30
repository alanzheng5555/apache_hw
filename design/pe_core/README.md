# PE Core Design - Apache_HW

This directory contains the Processing Element (PE) core design for the Apache_HW inference-optimized architecture. The design is organized into three main subdirectories:

## Directory Structure

```
design/pe_core/
├── rtl/                 # Register Transfer Level source files
│   ├── pe_top_simple.v          # Top-level PE module
│   ├── mac_array.v              # Matrix multiply-accumulate array
│   ├── activation_unit_simple.v # Activation function unit
│   ├── normalization_unit_simple.v # Normalization unit
│   ├── register_file.v          # Register file implementation
│   ├── local_cache.v            # Local cache implementation
│   ├── pe_core_complete.v       # Complete PE core integration
│   ├── simple_pe_test.v         # Simple functionality test
│   ├── tb_pe_core.v            # Testbench for PE core
│   ├── tb_pe_complete.v        # Comprehensive testbench
│   └── basic_functionality_test.v # Additional test case
├── sim/                 # Simulation files and scripts
│   └── Makefile         # Makefile for PE core simulation
└── doc/                # Documentation
    ├── PE_CORE_DESIGN_REPORT.md # Design report
    └── README.md        # PE core documentation
```

## Key Features

- **Inference Optimized**: Designed specifically for AI inference workloads
- **Transformer Focused**: Optimized for Transformer model architectures
- **NUMA Compatible**: Designed for multi-node NUMA systems
- **High Performance**: Optimized floating-point operations (FP16/BF16)

## PE Core Design

The Processing Element (PE) core is the fundamental computing unit of Apache_HW, featuring:

- MAC (Multiply-Accumulate) array for matrix operations
- Specialized activation function units (ReLU, GELU, Sigmoid, etc.)
- Layer/RMS normalization units for Transformer models
- Hierarchical memory system with optimized caching
- NUMA-aware communication interfaces

## Getting Started

To simulate the PE core:

1. Navigate to the simulation directory: `cd sim/`
2. Run simulation: `make` (refer to Makefile for available targets)
3. View waveforms: (as defined in Makefile)
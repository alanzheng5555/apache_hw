# Apache_HW Project

Apache_HW is an inference-optimized architecture designed for AI workloads, with a focus on Transformer models. This repository contains the design files, simulations, test cases, and documentation for the project.

## Directory Structure

```
├── rtl/                 # Register Transfer Level source files
│   └── pe_core/         # PE (Processing Element) core design
│       ├── pe_top_simple.v          # Top-level PE module
│       ├── mac_array.v              # Matrix multiply-accumulate array
│       ├── activation_unit_simple.v # Activation function unit
│       ├── normalization_unit_simple.v # Normalization unit
│       ├── register_file.v          # Register file implementation
│       ├── local_cache.v            # Local cache implementation
│       ├── pe_core_complete.v       # Complete PE core integration
│       ├── simple_pe_test.v         # Simple functionality test
│       ├── tb_pe_core.v             # Testbench for PE core
│       └── tb_pe_complete.v         # Comprehensive testbench
├── sim/                 # Simulation files and scripts
│   └── pe_core/         # PE core simulation files
│       ├── Makefile     # Makefile for PE core simulation
│       ├── PE_CORE_DESIGN_REPORT.md # Design report
│       └── README.md    # PE core simulation README
├── test_case/          # Test cases for verification
│   └── pe_core/        # PE core specific test cases
│       ├── basic_functionality_test.v # Basic functionality verification
│       └── simple_test  # Compiled test binary
└── doc/                # Documentation
    ├── architecture_plan.md          # Overall architecture plan
    ├── pe_core_specification.md      # PE core technical specifications
    ├── gpu_architecture_research.md  # GPU architecture research
    ├── cuda_gpu_instruction_set.md   # CUDA instruction set reference
    ├── numa_optimization.md          # NUMA optimization strategies
    ├── APACHE_HW_ARCHITECTURE_OVERVIEW.md # Architecture overview
    └── other documentation files...
```

## Key Features

- **Inference Optimized**: Designed specifically for AI inference workloads
- **Transformer Focused**: Optimized for Transformer model architectures
- **NUMA Compatible**: Designed for multi-node NUMA systems
- **High Performance**: Optimized floating-point operations (FP16/BF16)
- **Modular Design**: Component-based architecture for scalability

## PE Core Design

The Processing Element (PE) core is the fundamental computing unit of Apache_HW, featuring:

- MAC (Multiply-Accumulate) array for matrix operations
- Specialized activation function units (ReLU, GELU, Sigmoid, etc.)
- Layer/RMS normalization units for Transformer models
- Hierarchical memory system with optimized caching
- NUMA-aware communication interfaces

## Getting Started

To simulate the PE core:

1. Navigate to the simulation directory: `cd sim/pe_core/`
2. Run simulation with Makefile: `make test_core` or `make test_complete`
3. View waveforms: `make view_core_wave` (requires GTKWave)

For detailed information about each component, refer to the documentation in the `doc/` directory.
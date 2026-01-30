# PE Core Design for Apache_HW

This directory contains the design files for the Processing Element (PE) core of the Apache_HW architecture, optimized for AI inference with focus on Transformer models.

## Directory Structure

- `pe_top_simple.v` - Top-level PE module
- `mac_array.v` - Matrix multiply-accumulate array
- `activation_unit_simple.v` - Activation function unit
- `normalization_unit_simple.v` - Normalization unit
- `register_file.v` - Register file implementation
- `local_cache.v` - Local cache implementation
- `pe_core_complete.v` - Complete PE core integration
- `simple_pe_test.v` - Simple test for functionality verification
- `tb_pe_core.v`, `tb_pe_complete.v` - Testbenches
- `Makefile` - Compilation and test management
- `PE_CORE_DESIGN_REPORT.md` - Design report

## Key Features

1. **Optimized for AI Inference**: Specialized for Transformer model inference
2. **High Performance MAC Operations**: Dedicated matrix multiplication units
3. **Multiple Activation Functions**: ReLU, GELU, Sigmoid, Tanh, Swish
4. **Normalization Support**: LayerNorm and RMSNorm for Transformer models
5. **NUMA Compatible**: Designed for multi-node architectures
6. **Energy Efficient**: Optimized for inference performance/energy ratio

## Verification

Basic functionality verified with `simple_pe_test.v` demonstrating:
- MAC operations (2×3+1=7 computed correctly)
- ReLU activation function
- Basic instruction decoding

## Architecture Focus

- **Floating Point Performance**: Optimized for FP16/BF16 operations
- **Transformer Optimization**: Specialized units for attention mechanisms
- **Scalability**: Designed for multi-PE systems
- **Memory Efficiency**: Optimized cache hierarchy

## Future Enhancements

- More sophisticated activation functions
- Quantization support (INT8, INT4)
- Sparse computation capabilities
- Advanced power management
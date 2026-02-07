# PE Top Design FileList Folder

This folder contains filelists for viewing PE top design in Verdi.

## FileList for Verdi

### `pe_top_design.f`
Complete filelist for viewing PE Top Enhanced design including:
- **pe_top_enhanced.v** - Main top module with full features
- **pe_core_complete.v** - Complete PE core integration
- **mac_array.v** - Matrix multiply-accumulate array
- **activation_unit_simple.v** - Activation functions (ReLU, GELU, Sigmoid)
- **normalization_unit_simple.v** - Layer/RMS normalization
- **register_file.v** - Scalar and vector register file
- **local_cache.v** - L1 cache implementation
- **Utility modules** - Clock buffers, dividers, sync cells

## Usage with Verdi

```bash
# Open design in Verdi with waveform
verdi -f pe_top_design.f -ssf tb_pe_enhanced.vcd &

# Or with custom waveform file
verdi -f pe_top_design.f -ssf your_waveform.fsdb &
```

## FileList Format

The filelist uses Synopsys-compatible format with:
- Full absolute paths for all files
- `+incdir+` directives for include directories
- Comments starting with `#`

## Related Files

- **Simulation**: `design/pe_core/sim/Makefile`
- **Testbench**: `design/pe_core/rtl/tb_pe_enhanced.v`

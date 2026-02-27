# Apache_HW Verification Plan

## 1. Overview

This verification plan defines the strategy for achieving 100% verification coverage of the Apache_HW chip design. The plan targets the integration of UCIe, PE Core, NoC Router, and Chip Top modules.

## 2. Design Under Test (DUT)

### 2.1 Module Hierarchy

```
chip_top
├── chip_top_ucie_integrated (Top Integration)
│   ├── mesh_router (8x8 NoC)
│   ├── pe_core[63:0] (64 PE Processing Elements)
│   └── ucsie_if[7:0] (8 UCIe Interfaces)
│       ├── ucsie_top
│       ├── ucsie_adapter
│       ├── ucsie_controller
│       └── ucsie_phy
└── core (RISC-V Control Core)
```

### 2.2 Key Interfaces

| Interface | Protocol | Width | Description |
|-----------|----------|-------|-------------|
| ext_m_AXI | AXI4 | 64-bit | External Master (DDR/Host) |
| ext_s_AXI | AXI4 | 64-bit | External Slave (NoC) |
| ucie_if | UCIe | 16-lane | Chiplet Interconnect |
| pe_internal | Native | 512-bit | PE Array Data Path |

## 3. Verification Goals

### 3.1 Functional Coverage Targets

| Module | Coverage Target | Priority |
|--------|-----------------|----------|
| PE Core | 100% | High |
| MAC Array | 100% | High |
| Activation Unit | 100% | High |
| Normalization Unit | 100% | High |
| Share Memory | 100% | High |
| UCIe Top | 100% | High |
| UCIe Adapter | 100% | High |
| UCIe Controller | 100% | High |
| UCIe PHY | 100% | Medium |
| Mesh Router | 100% | High |
| Chip Top Integration | 100% | High |

### 3.2 Verification Metrics

- **Code Coverage**: Line, Toggle, Branch, FSM
- **Functional Coverage**: All specified features
- **Assertion Coverage**: Protocol checks
- **Corner Cases**: Error conditions, boundary values

## 4. Test Plan

### 4.1 PE Core Tests

| Test Name | Description | Coverage |
|-----------|-------------|----------|
| pe_mac_basic | Basic MAC operation | MAC Array |
| pe_mac_stall | MAC with pipeline stall | MAC Array |
| pe_mac_continuous | Continuous MAC streaming | MAC Array |
| pe_act_relu | ReLU activation | Activation Unit |
| pe_act_gelu | GELU activation | Activation Unit |
| pe_act_sigmoid | Sigmoid activation | Activation Unit |
| pe_act_tanh | Tanh activation | Activation Unit |
| pe_norm_layernorm | LayerNorm operation | Normalization |
| pe_norm_rmsnorm | RMSNorm operation | Normalization |
| pe_load_store | Memory load/store | Share Memory |
| pe_concurrent_access | Concurrent PE/AXI access | Share Memory |

### 4.2 UCIe Tests

| Test Name | Description | Coverage |
|-----------|-------------|----------|
| ucie_init | UCIe initialization | PHY + Adapter |
| ucie_tx_packet | TX packet transfer | Adapter |
| ucie_rx_packet | RX packet transfer | Adapter |
| ucie_credit | Credit flow control | Controller |
| ucie_tlp | TLP packetization | Adapter |
| ucie_dllp | DLLP handling | Adapter |
| ucie_axi_to_ucie | AXI->UCIe conversion | Controller |
| ucie_ucie_to_axi | UCIe->AXI conversion | Controller |

### 4.3 NoC Router Tests

| Test Name | Description | Coverage |
|-----------|-------------|----------|
| router_routeXY | XY routing | Router |
| router_congestion | Congestion handling | Router |
| router_broadcast | Broadcast traffic | Router |
| router_unicast | Unicast traffic | Router |
| router_adaptive | Adaptive routing | Router |

### 4.4 Integration Tests

| Test Name | Description | Coverage |
|-----------|-------------|----------|
| chip_full | Full chip simulation | Top |
| chip_matrix_mult | 8x8 matrix multiplication | Top |
| chip_streaming | Continuous streaming | Top |
| chip_multi_tile | Multi-chiplet communication | Top |

## 5. UVM Testbench Architecture

```
verify/
├── tb/
│   ├── uvm_env.sv          # UVM Environment
│   ├── uvm_agent.sv        # UVM Agent (AXI/UCIe)
│   ├── uvm_driver.sv       # UVM Driver
│   ├── uvm_monitor.sv      # UVM Monitor
│   ├── uvm_sequencer.sv   # UVM Sequencer
│   ├── uvm_scoreboard.sv   # UVM Scoreboard
│   └── tb_top.sv          # Testbench Top
├── seq/
│   ├── axi_seq.sv         # AXI Sequences
│   ├── ucie_seq.sv        # UCIe Sequences
│   └── pe_seq.sv          # PE Sequences
├── cov/
│   ├── coverage.sv        # Functional Coverage
│   └── assert.sv          # Assertions
├── scripts/
│   ├── compile.sh         # Compilation script
│   └── run.sh             # Run script
└── doc/
    └── VERIFICATION_PLAN.md
```

## 6. Verification Flow

### 6.1 Phase 1: Unit Verification
- [ ] PE Core standalone verification
- [ ] UCIe standalone verification
- [ ] Router standalone verification

### 6.2 Phase 2: Integration Verification
- [ ] PE + Share Memory integration
- [ ] UCIe + AXI integration
- [ ] Router + PE integration

### 6.3 Phase 3: System Verification
- [ ] Full chip simulation
- [ ] Performance benchmarking
- [ ] Power estimation

## 7. Sign-off Criteria

- [ ] Code Coverage > 95%
- [ ] Functional Coverage 100%
- [ ] All assertions pass
- [ ] No high-severity bugs open
- [ ] Regression suite passes

## 8. Tool Requirements

- **Simulator**: VCS / Xcelium
- **UVM**: UVM 1.2+
- **Coverage**: VCS coverage / Verdi
- **Debug**: Verdi / DVE

---

**Author**: Walle (AI Assistant)
**Date**: 2026-02-27
**Version**: 1.0

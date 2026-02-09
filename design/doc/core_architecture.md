# Core Module Architecture

## Overview

The `core` module integrates a **6-port NoC router** with a **Processing Engine (PE)** to form a complete computation and communication subsystem. This module provides interfaces for NoC communication and external AXI4 connectivity.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                              Core                                    │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                    Router_6port                              │   │
│   │                                                             │   │
│   │    Port 0 ◄──┐                                              │   │
│   │    Port 1 ──►│    ┌─────────────────────────────────────┐   │   │
│   │    Port 2 ◄──│    │                                     │   │   │
│   │    Port 3 ◄──│    │         Crossbar / Routing          │   │   │
│   │    Port 4 ──►│    │         (Address-based)             │   │   │
│   │    Port 5 ──►│    │                                     │   │   │
│   │              │    └─────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────────┘   │
│              │                    │                                 │
│              ▼                    ▼                                 │
│   ┌──────────────────┐   ┌──────────────────┐                      │
│   │   NOC Slave      │   │       PE         │                      │
│   │   (Port 0)      │   │   (Internal)     │                      │
│   └──────────────────┘   └──────────────────┘                      │
│                                                                      │
│   External Interfaces:                                               │
│   ┌──────────┐ s0    ┌──────────┐ s1    ┌──────────┐ m0           │
│   │ AXI Slave├───────►│ AXI Slave├───────►│AXI Master├─────────────►│
│   └──────────┘        └──────────┘        └──────────┘              │
│                                               ┌──────────┐ m1       │
│                                               │AXI Master├─────────► │
│                                               └──────────┘          │
└─────────────────────────────────────────────────────────────────────┘
```

## Interface Summary

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `noc_s_*` | Input | AXI4 Slave | Receives transactions from NoC (Port 0) |
| `noc_m_*` | Output | AXI4 Master | Initiates transactions to NoC (Port 1) |
| `s0_*` | Input | AXI4 Slave | External master access (Port 2) |
| `s1_*` | Input | AXI4 Slave | External master access (Port 3) |
| `m0_*` | Output | AXI4 Master | Core access to external slave (Port 4) |
| `m1_*` | Output | AXI4 Master | Core access to external slave (Port 5) |
| `pe_*` | Bidirectional | Control | PE control signals |

## Signal Descriptions

### NOC Slave Interface (Port 0)

Receives read/write requests from the NoC network.

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `noc_s_awvalid` | Input | 1 | Write address valid |
| `noc_s_awready` | Output | 1 | Write address ready |
| `noc_s_awaddr` | Input | 32 | Write address |
| `noc_s_awlen` | Input | 8 | Burst length |
| `noc_s_awsize` | Input | 3 | Burst size |
| `noc_s_awburst` | Input | 2 | Burst type |
| `noc_s_wvalid` | Input | 1 | Write data valid |
| `noc_s_wready` | Output | 1 | Write data ready |
| `noc_s_wdata` | Input | 64 | Write data |
| `noc_s_wstrb` | Input | 8 | Write strobe |
| `noc_s_wlast` | Input | 1 | Last write transfer |
| `noc_s_arvalid` | Input | 1 | Read address valid |
| `noc_s_arready` | Output | 1 | Read address ready |
| `noc_s_araddr` | Input | 32 | Read address |
| `noc_s_arlen` | Input | 8 | Burst length |
| `noc_s_arsize` | Input | 3 | Burst size |
| `noc_s_arburst` | Input | 2 | Burst type |
| `noc_s_rvalid` | Output | 1 | Read response valid |
| `noc_s_rready` | Input | 1 | Read response ready |
| `noc_s_rdata` | Output | 64 | Read data |
| `noc_s_rlast` | Output | 1 | Last read transfer |

### NOC Master Interface (Port 1)

Initiates read/write transactions to the NoC network. Same signal naming convention as NOC Slave, but signals are output from core.

### AXI Slave Interfaces (Ports 2-3)

External masters can access the core through these slave ports.

**AXI Slave Port 0 (`s0_*`)** and **AXI Slave Port 1 (`s1_*`)** have identical signal interfaces.

### AXI Master Interfaces (Ports 4-5)

Core accesses external slaves through these master ports.

**AXI Master Port 0 (`m0_*`)** and **AXI Master Port 1 (`m1_*`)** have identical signal interfaces.

### PE Control Signals

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `pe_start` | Input | 1 | Start PE computation |
| `pe_instruction` | Input | 32 | Instruction opcode |
| `pe_done` | Output | 1 | Computation complete |

## Router Architecture

### 6-Port Configuration

The router has 6 independent ports:

| Port | ID | Type | Default Route |
|------|-----|------|---------------|
| 0 | `PORT_ID_NOC_SLAVE` | Slave | Input from NoC |
| 1 | `PORT_ID_NOC_MASTER` | Master | Output to NoC |
| 2 | `PORT_ID_AXI_SLAVE0` | Slave | Input from external master 0 |
| 3 | `PORT_ID_AXI_SLAVE1` | Slave | Input from external master 1 |
| 4 | `PORT_ID_AXI_MASTER0` | Master | Output to external slave 0 |
| 5 | `PORT_ID_AXI_MASTER1` | Master | Output to external slave 1 |

### Routing Table

The router uses an address-based routing table with 8 entries. Each entry contains:

| Field | Width | Description |
|-------|-------|-------------|
| `route_addr` | 32 | Base address for matching |
| `route_mask` | 32 | Address mask for range matching |
| `route_table` | 3 | Target port ID |

### Default Routing Configuration

| Address Range | Size | Target Port |
|---------------|------|-------------|
| `0x0000_0000` - `0x0FFF_FFFF` | 256 MB | NOC Master (Port 1) |
| `0x1000_0000` - `0x1FFF_FFFF` | 256 MB | AXI Master 0 (Port 4) |
| `0x2000_0000` - `0x2FFF_FFFF` | 256 MB | AXI Master 1 (Port 5) |
| `0x3000_0000` - `0x3FFF_FFFF` | 256 MB | AXI Master 0 (Port 4) |

### APB Configuration Interface

The routing table can be configured dynamically via APB interface:

| Signal | Direction | Description |
|--------|-----------|-------------|
| `paddr[11:8]` | Input | Route table entry index (0-7) |
| `paddr[3:2]` | Input | Field select: 00=addr, 01=mask, 10=port |
| `pwrite` | Input | Write enable |
| `pwdata` | Input | Write data |
| `pready` | Output | Transfer ready |
| `prdata` | Output | Read data |

## File Structure

```
apache_hw/design/
├── core/
│   └── rtl/
│       └── core.v              # Core top module
├── noc/
│   └── router/
│       └── rtl/
│           ├── router_top.v    # Original 3-port router
│           └── router_6port.v  # New 6-port router
└── doc/
    └── core_architecture.md    # This document
```

## Usage Example

```systemverilog
// Core instantiation
core #(
    .DATA_W(64),
    .ADDR_W(32)
) u_core (
    // System
    .clk(clk),
    .rst_n(rst_n),
    
    // NOC interfaces
    .noc_s_awvalid(noc_awvalid),
    .noc_s_awready(noc_awready),
    .noc_s_awaddr(noc_awaddr),
    // ... other NOC signals ...
    
    .noc_m_awvalid(core_awvalid),
    .noc_m_awready(core_awready),
    .noc_m_awaddr(core_awaddr),
    // ... other NOC signals ...
    
    // AXI Slave ports
    .s0_awvalid(ext0_awvalid),
    .s0_awready(ext0_awready),
    // ... other s0 signals ...
    
    .s1_awvalid(ext1_awvalid),
    .s1_awready(ext1_awready),
    // ... other s1 signals ...
    
    // AXI Master ports
    .m0_awvalid(core_awvalid),
    .m0_awready(mem0_awready),
    // ... other m0 signals ...
    
    .m1_awvalid(core_awvalid),
    .m1_awready(mem1_awready),
    // ... other m1 signals ...
    
    // PE control
    .pe_start(pe_start),
    .pe_instruction(pe_instr),
    .pe_done(pe_done)
);
```

## Key Features

1. **Independent AXI Ports**: All 4 AXI interfaces are independent (no sharing/multiplexing)
2. **Address-Based Routing**: Flexible routing based on address decode
3. **Configurable Routing Table**: Dynamic reconfiguration via APB
4. **PE Integration**: Built-in PE for compute operations
5. **NoC Connectivity**: Full duplex communication with NoC network

## Limitations and Future Work

- Current routing is address-based only; could add QoS/priority
- No flow control buffering at router inputs
- PE interface needs full AXI4 connection
- Could add interrupt handling for PE completion

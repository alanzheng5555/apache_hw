# UCIe Specification

## Universal Chiplet Interconnect Express

UCIe is an open standard for chiplet-to-chiplet interconnect, designed for high-bandwidth, low-latency communication between dies in a package.

## UCIe Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         UCIe Stack                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐     ┌─────────────────┐                           │
│  │   Protocol      │     │   Protocol      │                           │
│  │   Layer         │◄───►│   Layer         │                           │
│  │  (PCIe/CXL)     │     │  (PCIe/CXL)     │                           │
│  └────────┬────────┘     └────────┬────────┘                           │
│           │                       │                                     │
│  ┌────────▼────────┐     ┌────────▼────────┐                           │
│  │   Adapter       │     │   Adapter       │                           │
│  │   Layer         │◄───►│   Layer         │                           │
│  │                 │     │                 │                           │
│  └────────┬────────┘     └────────┬────────┘                           │
│           │                       │                                     │
│  ┌────────▼────────┐     ┌────────▼────────┐                           │
│  │   Physical      │     │   Physical     │                           │
│  │   Layer         │◄───►│   Layer        │                           │
│  │                 │     │                │                           │
│  └────────┬────────┘     └────────┬────────┘                           │
│           │                       │                                     │
│     ┌─────┴─────┐           ┌─────┴─────┐                             │
│     │  Analog    │           │  Analog   │                             │
│     │  Interface │           │  Interface │                             │
│     └─────┬─────┘           └─────┬─────┘                             │
│           │                       │                                     │
└───────────┼───────────────────────┼─────────────────────────────────────┘
            │                       │
     ┌──────┴──────┐          ┌─────┴──────┐
     │   Die A     │          │    Die B    │
     └─────────────┘          └─────────────┘
```

## UCIe Layer Specifications

### 1. Protocol Layer

Based on **PCIe 6.0** and **CXL** protocols:

| Feature | PCIe 6.0 | CXL 3.0 |
|---------|----------|---------|
| Bandwidth | Up to 64 GT/s | Up to 64 GT/s |
| Encoding | PAM-4 | PAM-4 |
| Flit Mode | Required | Required |
| Atomic Ops | Supported | Supported |

### 2. Adapter Layer

Key functions:

- **Packetization**: Split protocol packets into UCIe flits
- **Credit Management**: Flow control between dies
- **Ordering Rules**: Maintain PCIe/CXL ordering
- **Error Handling**: Retry and error reporting

### 3. Physical Layer

#### Electrical Specifications

| Parameter | Value |
|-----------|-------|
| Data Rate | 4-32 GT/s per lane |
| Modulation | PAM-4 (8 GT/s+) / NRZ (< 8 GT/s) |
| Voltage Swing | 800 mVppd (PAM-4) |
| Lane Count | 1-16 lanes (typ. 16) |
| Die-to-Die Distance | < 2mm |

#### Key Features

- **Lane Bonding**: Multiple lanes operate as single channel
- **Clock Data Recovery (CDR)**: Embedded clock in each lane
- **Link Training**: Initialization and negotiation
- **IDE (Integrity & Data Encryption)**: Security feature

### 4. Sideband Interface

1-wire management interface for:
- Link initialization
- Power management
- Reset control
- Error reporting

## UCIe Flit Format

```
┌───────────────────────────────────────────────────────────────────────┐
│                         UCIe Flit (256 bits)                          │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                    Flit Header (64 bits)                        │  │
│  ├────────────────────────────────────────────────────────────────┤  │
│  │  63:56 │ 55:48 │ 47:40 │ 39:32 │ 31:24 │ 23:16 │ 15:8 │ 7:0 │  │
│  │  ──────┴───────┴───────┴───────┴───────┴───────┴───────┴─────── │  │
│  │   Seq#  │ Retry │  Res  │ Length │  Type  │ Fmt   │  CRC       │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                    Payload (192 bits)                           │  │
│  │                                                                │  │
│  │   ┌─────────────────────────────────────────────────────────┐   │  │
│  │   │           Data / Header / Control Information           │   │  │
│  │   └─────────────────────────────────────────────────────────┘   │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

## Module Interfaces

### `ucsie_top` - Top Level

**Parameters:**
| Parameter | Default | Description |
|-----------|---------|-------------|
| `NUM_LANES` | 16 | Number of lanes (1-16) |
| `DATA_W` | 256 | Data path width |
| `IDE_ENABLE` | 1 | Enable encryption |
| `RETIMER_ENABLE` | 0 | Retimer support |

**Interfaces:**
- Protocol (PCIe/CXL compatible)
- Physical (analog lane interface)
- Sideband (1-wire management)

### `ucsie_adapter` - Adapter Layer

Handles:
- TLP/DLLP packetization
- Credit flow control
- Retry mechanism

### `ucsie_phy` - Physical Layer

Handles:
- Lane bonding
- Serializer/Deserializer
- Link training
- IDE encryption

## Address Space

| Range | Description |
|-------|-------------|
| 0x0000_0000 - 0x0FFF_FFFF | Standard PCIe/CXL |
| 0x1000_0000 - 0x1FFF_FFFF | UCIe-specific |
| 0x2000_0000 - 0x2FFF_FFFF | Vendor-specific |

## Bandwidth Calculations

### Raw Bandwidth

| Lanes | NRZ (8 GT/s) | PAM-4 (16 GT/s) | PAM-4 (32 GT/s) |
|-------|---------------|-----------------|-----------------|
| 1 | 8 GB/s | 16 GB/s | 32 GB/s |
| 4 | 32 GB/s | 64 GB/s | 128 GB/s |
| 8 | 64 GB/s | 128 GB/s | 256 GB/s |
| **16** | **128 GB/s** | **256 GB/s** | **512 GB/s** |

### Effective Bandwidth (with overhead)

| Lanes | Raw | 90% Efficient | 80% Efficient |
|-------|-----|---------------|---------------|
| 16 | 256 GB/s | 230 GB/s | 205 GB/s |

## Link Training States

```
                              ┌──────────┐
                              │  RESET   │
                              └────┬─────┘
                                   │
                                   ▼
                              ┌──────────┐
                    ┌────────►│ DETECT   │
                    │         └────┬─────┘
                    │              │
                    │              ▼
                    │         ┌──────────┐
                    │         │ POLLING  │
                    │         └────┬─────┘
                    │              │
                    │              ▼
                    │         ┌──────────┐
                    │         │ CONFIG   │
                    │         └────┬─────┘
                    │              │
                    │              ▼
                    │         ┌──────────┐
                    │         │LANESETUP │
                    │         └────┬─────┘
                    │              │
                    │              ▼
                    │         ┌──────────┐
                    │         │  FULL    │
                    │         └────┬─────┘
                    │              │
                    │              ▼
                    │         ┌──────────┐
                    │         │  IDLE    │◄──────┐
                    │         └──────────┘       │
                    │              ▲            │
                    │              │            │
                    └──────────────┘            │
                                          (link down)
```

## Usage Example

```systemverilog
// Instantiate UCIe link
ucsie_top #(
    .NUM_LANES(16),
    .DATA_W(256),
    .IDE_ENABLE(1)
) u_ucsie (
    .clk(clk),
    .rst_n(rst_n),
    
    // Protocol interface
    .tx_valid(tx_valid),
    .tx_ready(tx_ready),
    .tx_data(tx_data),
    .tx_sop(tx_sop),
    .tx_eop(tx_eop),
    
    .rx_valid(rx_valid),
    .rx_ready(rx_ready),
    .rx_data(rx_data),
    .rx_sop(rx_sop),
    .rx_eop(rx_eop),
    
    // Physical interface (to package)
    .tx_lane_p(tx_lane_p),
    .tx_lane_n(tx_lane_n),
    .rx_lane_p(rx_lane_p),
    .rx_lane_n(rx_lane_n),
    
    // Status
    .link_status(link_status),
    .lane_status(lane_status)
);
```

## File Structure

```
design/ucsie/
├── rtl/
│   ├── ucsie_top.v       # Top-level wrapper
│   ├── ucsie_adapter.v   # Adapter layer
│   └── ucsie_phy.v      # Physical layer
├── tb/
│   └── tb_ucsie.v       # Testbench
└── doc/
    └── ucsie_spec.md    # This document
```

## References

1. UCIe 1.0 Specification (Universal Chiplet Interconnect Express)
2. PCIe 6.0 Specification
3. CXL 3.0 Specification

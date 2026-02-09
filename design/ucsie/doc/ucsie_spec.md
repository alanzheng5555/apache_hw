# UCIe Specification

## Universal Chiplet Interconnect Express

UCIe is an open standard for chiplet-to-chiplet interconnect, designed for high-bandwidth, low-latency communication between dies in a package.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         UCIe Stack                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐     ┌─────────────────────────────────────────┐  │
│  │   AXI4          │     │             UCIe Controller            │  │
│  │   Interface     │◄───►│  ┌─────────────┐   ┌─────────────┐    │  │
│  │                 │     │  │ AXI Master  │   │ AXI Slave   │    │  │
│  └────────┬────────┘     │  │ (Initiator) │   │(Responder)  │    │  │
│           │              │  └──────┬──────┘   └──────┬──────┘    │  │
│  ┌────────▼────────┐     │         │                │           │  │
│  │   Adapter      │     │         └───────┬────────┘           │  │
│  │   Layer        │◄──────────────────────┼───────────────────►│  │
│  │                 │                      │                    │  │
│  └────────┬────────┘                      │                    │  │
│           │                               │                    │  │
│  ┌────────▼────────┐                       │                    │  │
│  │   Physical     │◄──────────────────────┼───────────────────►│  │
│  │   Layer        │                      │                    │  │
│  │                │                      │                    │  │
│  └────────┬────────┘                      │                    │  │
│           │                               │                    │  │
│     ┌─────┴─────┐                         │                    │  │
│     │  Analog    │                         │                    │  │
│     │  Interface │◄────────────────────────┴──────────────────►│  │
│     └─────┬─────┘                                                  │
│           │                                                        │
└───────────┼────────────────────────────────────────────────────────┘
            │
     ┌──────┴──────┐
     │   Remote     │
     │   Chiplet    │
     └──────────────┘
```

## UCIe Controller (AXI Interface)

The UCIe Controller provides AXI4 interface to the chiplet's internal system.

### Features

- **AXI4 Master Interface**: Initiate transactions to remote chiplet
- **AXI4 Slave Interface**: Respond to requests from remote chiplet
- **Credit Management**: Flow control between initiator and responder
- **Transaction Reordering**: Support for out-of-order transactions
- **Error Handling**: Retry and error reporting

### AXI4 Interface Signals

#### Master Interface (Initiator)

| Channel | Signal | Direction | Width | Description |
|---------|--------|-----------|-------|-------------|
| **AW** | `m_awid` | Output | ID_W | Write transaction ID |
| | `m_awaddr` | Output | 64 | Write address |
| | `m_awlen` | Output | 8 | Burst length (1-256) |
| | `m_awsize` | Output | 3 | Burst size (1/2/4/8/16/32/64/128 bytes) |
| | `m_awburst` | Output | 2 | Burst type (FIXED/INCR/WRAP) |
| | `m_awvalid` | Output | 1 | Address valid |
| | `m_awready` | Input | 1 | Address ready |
| **W** | `m_wdata` | Output | 256 | Write data |
| | `m_wstrb` | Output | 32 | Write strobe |
| | `m_wlast` | Output | 1 | Last beat |
| | `m_wvalid` | Output | 1 | Data valid |
| | `m_wready` | Input | 1 | Data ready |
| **B** | `m_bid` | Input | ID_W | Response ID |
| | `m_bresp` | Input | 2 | Response (OKAY/EXOKAY/SLVERR/DECERR) |
| | `m_bvalid` | Input | 1 | Response valid |
| | `m_bready` | Output | 1 | Response ready |
| **AR** | `m_arid` | Output | ID_W | Read transaction ID |
| | `m_araddr` | Output | 64 | Read address |
| | `m_arlen` | Output | 8 | Burst length |
| | `m_arsize` | Output | 3 | Burst size |
| | `m_arburst` | Output | 2 | Burst type |
| | `m_arvalid` | Output | 1 | Address valid |
| | `m_arready` | Input | 1 | Address ready |
| **R** | `m_rid` | Input | ID_W | Read ID |
| | `m_rdata` | Input | 256 | Read data |
| | `m_rresp` | Input | 2 | Read response |
| | `m_rlast` | Input | 1 | Last beat |
| | `m_rvalid` | Input | 1 | Data valid |
| | `m_rready` | Output | 1 | Data ready |

#### Slave Interface (Responder)

Same signal mapping as Master Interface, but directions reversed.

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DATA_W` | 256 | Data bus width |
| `ADDR_W` | 64 | Address bus width |
| `ID_W` | 4 | AXI transaction ID width |
| `NUM_LANES` | 16 | Number of UCIe lanes |
| `IDE_ENABLE` | 1 | Enable encryption |

## Usage Example

```systemverilog
// Instantiate UCIe link with AXI interface
ucsie_top #(
    .NUM_LANES(16),
    .DATA_W(256),
    .ADDR_W(64),
    .ID_W(4),
    .IDE_ENABLE(1)
) u_ucsie (
    .clk(clk),
    .rst_n(rst_n),
    
    // AXI Master (initiate remote requests)
    .m_awid(m_awid),
    .m_awaddr(m_awaddr),
    .m_awlen(m_awlen),
    .m_awsize(m_awsize),
    .m_awburst(m_awburst),
    .m_awvalid(m_awvalid),
    .m_awready(m_awready),
    .m_wdata(m_wdata),
    .m_wstrb(m_wstrb),
    .m_wlast(m_wlast),
    .m_wvalid(m_wvalid),
    .m_wready(m_wready),
    .m_bid(m_bid),
    .m_bresp(m_bresp),
    .m_bvalid(m_bvalid),
    .m_bready(m_bready),
    .m_arid(m_arid),
    .m_araddr(m_araddr),
    .m_arlen(m_arlen),
    .m_arsize(m_arsize),
    .m_arburst(m_arburst),
    .m_arvalid(m_arvalid),
    .m_arready(m_arready),
    .m_rid(m_rid),
    .m_rdata(m_rdata),
    .m_rresp(m_rresp),
    .m_rlast(m_rlast),
    .m_rvalid(m_rvalid),
    .m_rready(m_rready),
    
    // AXI Slave (respond to remote requests)
    .s_awid(s_awid),
    .s_awaddr(s_awaddr),
    // ... (same pattern as master)
    
    // Physical interface
    .tx_lane_p(tx_lane_p),
    .tx_lane_n(tx_lane_n),
    .rx_lane_p(rx_lane_p),
    .rx_lane_n(rx_lane_n),
    
    // Status
    .link_status(link_status),
    .lane_status(lane_status)
);

// Simple write transaction
always @(posedge clk) begin
    if (write_enable) begin
        m_awaddr <= remote_addr;
        m_awlen <= 8'd15;           // 16-beat burst
        m_awsize <= 3'd5;           // 32 bytes per beat
        m_awvalid <= 1'b1;
        
        if (m_awready) begin
            m_awvalid <= 1'b0;
        end
    end
end
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

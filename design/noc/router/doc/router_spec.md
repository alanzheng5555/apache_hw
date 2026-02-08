# NoC Router Module Design Specification

## 1. Overview

A Network-on-Chip (NoC) router module with:
- **3 AXI4 Input Ports** (ingress)
- **3 AXI4 Output Ports** (egress)
- **APB Configuration Interface** for routing rules
- **Traffic Monitoring** for performance analysis

## 2. Block Diagram

```
                    +------------------+
                    |   Router Table   |
                    |  (APB Config)   |
                    +--------+---------+
                             |
+--------+    +--------+    v    +--------+    +--------+
| Port 0 |---->| Arbiter|<------>| Filter |---->| Port 0 |
| AXI4   |    +--------+         +--------+     | AXI4   |
| Input  |                          ^          | Output |
+--------+                          |          +--------+
                                       |
+--------+    +--------+         +--------+    +--------+
| Port 1 |---->| Arbiter|<------>| Filter |---->| Port 1 |
| AXI4   |    +--------+         +--------+     | AXI4   |
| Input  |                          ^          | Output |
+--------+                          |          +--------+
                                       |
+--------+    +--------+         +--------+    +--------+
| Port 2 |---->| Arbiter|<------>| Filter |---->| Port 2 |
| AXI4   |    +--------+         +--------+     | AXI4   |
| Input  |                          ^          | Output |
+--------+                          |          +--------+
                                       |
                    +--------+---------+
                    | Traffic Monitor |
                    | (APB Read)     |
                    +----------------+
```

## 3. Features

### 3.1 AXI4 Interfaces
- **3 Input Ports**: Receive transactions from masters
- **3 Output Ports**: Forward transactions to slaves
- **Full AXI4**: AW, W, AR, R channels (no B channel for simplicity)
- **Burst Support**: INCR, FIXED, WRAP

### 3.2 APB Configuration Interface
- **Address-Based Routing**: Configure which output port for each address range
- **Mask Support**: Configure which address bits are "don't care"
- **Default Route**: Fallback port when no match
- **Routing Table Size**: 8 entries

### 3.3 Traffic Monitoring
- **Packet Counter**: Count packets per port
- **Byte Counter**: Count bytes per port
- **Latency Measurement**: First/Last beat timestamps
- **APB Accessible**: Read counters via APB interface

## 4. Routing Algorithm

### 4.1 Address Matching
```
For each routing entry:
  IF (addr[31:24] & mask[31:24]) == (entry[31:24] & mask[31:24]) AND
     (addr[23:16] & mask[23:16]) == (entry[23:16] & mask[23:16]) AND
     (addr[15:8]  & mask[15:8])  == (entry[15:8]  & mask[15:8])  AND
     (addr[7:0]   & mask[7:0])   == (entry[7:0]   & mask[7:0])
  THEN
     Route to specified output port
```

### 4.2 Priority
- Entry 0 has highest priority
- Entries checked in order (0 → 7)
- Default route used if no match

## 5. Register Map (APB)

### 5.1 Routing Table Entries (0x00 - 0x3F)
| Offset | Register | Description |
|--------|----------|-------------|
| 0x00 | ROUTE_ADDR0 | Base address for matching |
| 0x04 | ROUTE_MASK0 | Address mask (1=don't care) |
| 0x08 | ROUTE_PORT0 | Output port (0, 1, 2, or 0xFF=default) |
| ... | ... | ... |
| 0x1C | ROUTE_ADDR3 | |
| 0x20 | ROUTE_MASK3 | |
| 0x24 | ROUTE_PORT3 | |
| ... | ... | ... |
| 0x3C | ROUTE_ADDR7 | |
| 0x40 | ROUTE_MASK7 | |
| 0x44 | ROUTE_PORT7 | |

### 5.2 Traffic Monitor Registers (0x100 - 0x1FF)
| Offset | Register | Description |
|--------|----------|-------------|
| 0x100 | PKT_CNT_IN0 | Packets in port 0 |
| 0x104 | BYTE_CNT_IN0 | Bytes in port 0 |
| 0x108 | LAT_MIN_IN0 | Min latency port 0 |
| 0x10C | LAT_MAX_IN0 | Max latency port 0 |
| ... | ... | ... |
| 0x180 | PKT_CNT_OUT0 | Packets out port 0 |
| ... | ... | ... |

### 5.3 Control Registers
| Offset | Register | Description |
|--------|----------|-------------|
| 0x200 | CTRL | Bit 0: enable, Bit 1: reset counters |
| 0x204 | STATUS | Bit 0: busy |

## 6. Interface Signals

### 6.1 Clock and Reset
| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| clk | 1 | Input | System clock |
| rst_n | 1 | Input | Active low reset |

### 6.2 AXI4 Input Ports (3 ports)
| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| s_axis_awaddr | 32*3 | Input | Write address |
| s_axis_awlen | 8*3 | Input | Burst length |
| s_axis_awvalid | 3 | Input | Address valid |
| s_axis_awready | 3 | Output | Address ready |
| s_axis_wdata | 512*3 | Input | Write data (64-bit * 8) |
| s_axis_wlast | 3 | Input | Last beat |
| s_axis_wvalid | 3 | Input | Write valid |
| s_axis_wready | 3 | Output | Write ready |
| s_axis_araddr | 32*3 | Input | Read address |
| s_axis_arlen | 8*3 | Input | Burst length |
| s_axis_arvalid | 3 | Input | Read valid |
| s_axis_arready | 3 | Output | Read ready |
| s_axis_rdata | 512*3 | Output | Read data |
| s_axis_rlast | 3 | Output | Last beat |
| s_axis_rvalid | 3 | Output | Read valid |
| s_axis_rready | 3 | Input | Read ready |

### 6.3 AXI4 Output Ports (3 ports)
| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| m_axis_awaddr | 32*3 | Output | Write address |
| m_axis_awlen | 8*3 | Output | Burst length |
| m_axis_awvalid | 3 | Output | Address valid |
| m_axis_awready | 3 | Input | Address ready |
| ... | ... | ... | ... |

### 6.4 APB Interface
| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| paddr | 12 | Input | Address |
| pwrite | 1 | Input | Write enable |
| pwdata | 32 | Input | Write data |
| psel | 1 | Input | Select |
| penable | 1 | Input | Enable |
| pready | 1 | Output | Ready |
| prdata | 32 | Output | Read data |
| pslverr | 1 | Output | Slave error |

## 7. Timing Diagrams

### 7.1 Routing Decision
```
Cycle 0:  AWVALID + AWADDR[31:0]  → Router latches address
Cycle 1:  AWREADY                  → Address accepted
Cycle 2:  Decision made (based on routing table)
Cycle 3+: WVALID + WDATA           → Data forwarded to output port
```

### 7.2 APB Write
```
Cycle 0:  PSEL + PENABLE + PWRITE + PADDR + PWDATA
Cycle 1:  PREADY + (update routing table)
```

## 8. Performance Metrics

- **Throughput**: 1 transaction per cycle per port
- **Latency**: 1 cycle routing decision
- **FIFO Depth**: 16 beats per port

## 9. Use Cases

### 9.1 Basic Routing
```
APB Config:
  ROUTE_ADDR0 = 0x40000000
  ROUTE_MASK0 = 0xFF000000  // Top 8 bits matter
  ROUTE_PORT0 = 0           // Port 0

Traffic:
  Master writes to 0x40001234 → Route to Port 0
  Master writes to 0x50005678 → No match → Default port
```

### 9.2 Broadcast Mode
```
APB Config:
  ROUTE_ADDR0 = 0x00000000
  ROUTE_MASK0 = 0x00000000  // All don't care
  ROUTE_PORT0 = 0xFF        // Broadcast

Traffic:
  All transactions → All output ports
```

## 10. Implementation Notes

- Use synthesized for FPGA/ASIC
- Streaming interface (AXI4-Stream style) for internal data path
- Registered outputs for timing closure
- Gray coding for FIFO pointers

## 11. Verification Plan

### 11.1 Test Cases
1. Basic routing (single port)
2. Multi-port routing
3. Mask matching
4. Default Broadcast
 route
5.6. Traffic AP monitoring
7.
8. CornerB configuration cases (boundary addresses, all mask bits set)

### 11.2 Simulation Parameters
- Random traffic generation
- 10000+ transactions per test
- Coverage: 100% routing table entries
- Backpressure testing

## 12. Revision History

| Version | Date | Author | Description |
|---------|------|--------|------------|
| 1.0 | 2026-02-08 | Walle | Initial version |

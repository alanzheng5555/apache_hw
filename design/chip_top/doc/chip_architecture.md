# Chip Top-Level Architecture - 8×8 Core Mesh with UCIe

## Overview

The chip consists of **64 cores** arranged in an **8×8 2D mesh topology**. Each core contains a processing engine (PE) and a 6-port NoC router. Cores are interconnected horizontally and vertically through dedicated AXI interfaces.

**UCIe Integration**: Each row ends with a UCIe (Universal Chiplet Interconnect Express) interface for chiplet-to-chiplet communication. Total 8 UCIe interfaces (one per row).

## Architecture Diagram

```
                        North Boundary
    ┌─────────────────────────────────────────────────────────────────┐
    │                                                                 │
 W  │  ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐    │  E
 E  │  │[0,7]│[1,7]│[2,7]│[3,7]│[4,7]│[5,7]│[6,7]│[7,7]│UCIe7│    │  A
 S  │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤    │  S
 T  │  │[0,6]│[1,6]│[2,6]│[3,6]│[4,6]│[5,6]│[6,6]│[7,6]│UCIe6│    │  T
    │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤    │
    │  │[0,5]│[1,5]│[2,5]│[3,5]│[4,5]│[5,5]│[6,5]│[7,5]│UCIe5│    │
    │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤    │
    │  │[0,4]│[1,4]│[2,4]│[3,4]│[4,4]│[5,4]│[6,4]│[7,4]│UCIe4│    │
    │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤    │
    │  │[0,3]│[1,3]│[2,3]│[3,3]│[4,3]│[5,3]│[6,3]│[7,3]│UCIe3│    │
    │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤    │
    │  │[0,2]│[1,2]│[2,2]│[3,2]│[4,2]│[5,2]│[6,2]│[7,2]│UCIe2│    │
    │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤    │
    │  │[0,1]│[1,1]│[2,1]│[3,1]│[4,1]│[5,1]│[6,1]│[7,1]│UCIe1│    │
    │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤    │
    │  │[0,0]│[1,0]│[2,0]│[3,0]│[4,0]│[5,0]│[6,0]│[7,0]│UCIe0│    │
    │  └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘    │
    │                                                                 │
    └─────────────────────────────────────────────────────────────────┘
                        South Boundary

    Core [x,y]: x = column (0-7, left to right)
                y = row (0-7, bottom to top)
    
    UCIe[y]: UCIe interface for row y (connected to core[7][y])
```

## Core Interconnection

### Core Port Mapping

Each core has 6 router ports:

| Port | ID | Type | Connection |
|------|-----|------|------------|
| 0 | `PORT_ID_NOC_SLAVE` | Slave | Receives from external NoC |
| 1 | `PORT_ID_NOC_MASTER` | Master | Sends to external NoC |
| 2 | `PORT_ID_AXI_SLAVE0` | Slave | Receives from left neighbor (West) |
| 3 | `PORT_ID_AXI_SLAVE1` | Slave | Receives from bottom neighbor (South) |
| 4 | `PORT_ID_AXI_MASTER0` | Master | Sends to right neighbor (East) |
| 5 | `PORT_ID_AXI_MASTER1` | Master | Sends to top neighbor (North) |

### Mesh Connection Pattern

```
        [x,y+1] (North)
            ▲
            │ m1 (master, port 5)
            ▼
    [x-1,y] ◄──► [x,y] ◄──► [x+1,y]
            ▲             ▲
            │             │
     s1 (slave,    s0 (slave, 
        port 3)        port 2)
            │             │
            ▼             ▼
        [x,y-1]       [x+1,y] (South)
```

For core at position **[x,y]**:
- **West neighbor [x-1,y]** → connected to **s0 (slave port 2)**
- **East neighbor [x+1,y]** → connected to **m0 (master port 4)**
- **South neighbor [x,y-1]** → connected to **s1 (slave port 3)**
- **North neighbor [x,y+1]** → connected to **m1 (master port 5)**

## Address Routing

### Address Format

```
┌────────────────────────────────────────────────────────────────┐
│  31   30   29   28   27   26   25   24   23   22   21   20 ... │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                    Reserved (22 bits)                          │
├────────────────────────────────────────────────────────────────┤
│    9       8       7       6       5       4       3      2...0│
│  ━━━━━━┬───────┬────────────────────────────────────────────────│
│  Res   │ Row   │ Col  │             Offset within core          │
│   (3)  │ (3)   │ (3)  │                                         │
└────────────────────────────────────────────────────────────────┘
```

| Field | Bits | Width | Range | Description |
|-------|------|-------|-------|-------------|
| Reserved | 31:9 | 23 | - | Reserved for future use |
| **Row** | 8:6 | 3 | 0-7 | Destination row (Y coordinate) |
| **Col** | 5:3 | 3 | 0-7 | Destination column (X coordinate) |
| Offset | 2:0 | 3 | 0-7 | Local address offset within core |

### Routing Algorithm

1. **Extract destination coordinates** from address bits [8:6] (row) and [5:3] (col)
2. **Compare with local position** (my_x, my_y)
3. **Route decision**:
   - If `dest_col == my_x` and `dest_row == my_y` → **Local** (deliver to local core)
   - If `dest_col < my_x` → **West** (route to left neighbor)
   - If `dest_col > my_x` → **East** (route to right neighbor)
   - If `dest_row < my_y` → **South** (route to bottom neighbor)
   - If `dest_row > my_y` → **North** (route to top neighbor)

### Routing Priority

When both horizontal and vertical directions are needed:
- **Horizontal first**: Route to correct column, then adjust row
- **Vertical first**: Route to correct row, then adjust column

*Current implementation uses horizontal-first strategy.*

### Example Routing

**From core [2,3] to core [5,6]:**
```
Step 1: Route East from [2,3] → [3,3] (col mismatch: 5 > 2)
Step 2: Route East from [3,3] → [4,3] (col mismatch: 5 > 3)
Step 3: Route East from [4,3] → [5,3] (col mismatch resolved: 5 = 5)
Step 4: Route North from [5,3] → [5,4] (row mismatch: 6 > 3)
Step 5: Route North from [5,4] → [5,5] (row mismatch: 6 > 4)
Step 6: Route North from [5,5] → [5,6] (row mismatch resolved: 6 = 6)
Deliver to core [5,6]
```

## File Structure

```
apache_hw/design/
├── chip_top/
│   ├── rtl/
│   │   ├── chip_top.v          # 8x8 mesh top-level
│   │   └── mesh_router.v       # Mesh routing logic per core
│   ├── tb/
│   │   └── tb_chip_top.v       # Testbench
│   └── doc/
│       └── chip_architecture.md # This document
├── core/
│   └── rtl/
│       └── core.v              # Core module (router + PE)
└── noc/
    └── router/
        └── rtl/
            └── router_6port.v  # 6-port router
```

## Interface Signals

### External NoC Interface

| Signal | Direction | Description |
|--------|-----------|-------------|
| `ext_m_*` | Output | AXI Master to external NoC |
| `ext_s_*` | Input | AXI Slave from external NoC |

### PE Control Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `pe_start` | Input | 64 | Start signal per core |
| `pe_instruction` | Input | 32 | Shared instruction |
| `pe_done` | Output | 64 | Done status per core |

## Core Instances

Total: **64 cores** (8 columns × 8 rows)

| Row\Col | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---------|---|---|---|---|---|---|---|---|
| **7** | [0,7] | [1,7] | [2,7] | [3,7] | [4,7] | [5,7] | [6,7] | [7,7] |
| **6** | [0,6] | [1,6] | [2,6] | [3,6] | [4,6] | [5,6] | [6,6] | [7,6] |
| **5** | [0,5] | [1,5] | [2,5] | [3,5] | [4,5] | [5,5] | [6,5] | [7,5] |
| **4** | [0,4] | [1,4] | [2,4] | [3,4] | [4,4] | [5,4] | [6,4] | [7,4] |
| **3** | [0,3] | [1,3] | [2,3] | [3,3] | [4,3] | [5,3] | [6,3] | [7,3] |
| **2** | [0,2] | [1,2] | [2,2] | [3,2] | [4,2] | [5,2] | [6,2] | [7,2] |
| **1** | [0,1] | [1,1] | [2,1] | [3,1] | [4,1] | [5,1] | [6,1] | [7,1] |
| **0** | [0,0] | [1,0] | [2,0] | [3,0] | [4,0] | [5,0] | [6,0] | [7,0] |

## Usage Example

```systemverilog
// Chip top-level instantiation
chip_top #(
    .CORES_X(8),
    .CORES_Y(8),
    .DATA_W(64),
    .ADDR_W(32)
) u_chip (
    .clk(clk),
    .rst_n(rst_n),
    
    // External NoC interface
    .ext_m_awvalid(noc_awvalid),
    .ext_m_awready(noc_awready),
    .ext_m_awaddr(noc_awaddr),
    // ... other NoC signals ...
    
    .ext_s_awvalid(noc_s_awvalid),
    .ext_s_awready(noc_s_awready),
    .ext_s_awaddr(noc_s_awaddr),
    // ... other NoC signals ...
    
    // PE control
    .pe_start({64{1'b0}}),        // All cores idle
    .pe_instruction(32'h00000000),
    .pe_done()                     // Status output
);
```

## Boundary Conditions

### West Boundary (Column 0, Left)
- Inputs tied LOW (no external master)
- Outputs unconnected (no external slave)

### East Boundary (Column 7, Right)
- Inputs tied LOW
- Outputs unconnected

### South Boundary (Row 0, Bottom)
- Inputs tied LOW
- Outputs unconnected

### North Boundary (Row 7, Top)
- Inputs tied LOW
- Outputs unconnected

## Key Features

1. **64-core mesh**: 8×8 grid topology
2. **XY Routing**: Deterministic routing based on destination coordinates
3. **NoC integration**: External NoC connectivity via core [0,0]
4. **Independent connections**: No shared AXI interfaces between cores
5. **Scalable**: Parameterized dimensions (CORES_X, CORES_Y)
6. **UCIe Integration**: 8 UCIe interfaces (one per row) for chiplet-to-chiplet communication

## UCIe Interface

Each row ends with a UCIe interface for high-bandwidth chiplet interconnection:

| UCIe | Connected Core | Description |
|------|----------------|-------------|
| UCIe0 | Core[7][0] | Row 0 (bottom) |
| UCIe1 | Core[7][1] | Row 1 |
| UCIe2 | Core[7][2] | Row 2 |
| UCIe3 | Core[7][3] | Row 3 |
| UCIe4 | Core[7][4] | Row 4 |
| UCIe5 | Core[7][5] | Row 5 |
| UCIe6 | Core[7][6] | Row 6 |
| UCIe7 | Core[7][7] | Row 7 (top) |

### UCIe Specifications
- **Lanes**: 16 (parameterizable)
- **Data Width**: 256-bit
- **Address Width**: 64-bit
- **Protocol**: UCIe 1.0 compatible

## File Structure

```
apache_hw/design/
├── chip_top/
│   ├── rtl/
│   │   ├── chip_top.v              # Original 8x8 mesh top-level
│   │   ├── chip_top_ucie_integrated.v  # New: 8x8 + UCIe
│   │   └── mesh_router.v           # Mesh routing logic per core
│   ├── tb/
│   │   └── tb_chip_top.v            # Testbench
│   └── doc/
│       └── chip_architecture.md     # This document
├── core/
│   └── rtl/
│       └── core.v                  # Core module (router + PE)
├── noc/
│   └── router/
│       └── rtl/
│           └── router_6port.v      # 6-port router
└── ucsie/
    ├── rtl/
    │   ├── ucsie_top.v             # UCIe top-level
    │   ├── ucsie_controller.v       # UCIe AXI bridge
    │   ├── ucsie_adapter.v         # UCIe adapter layer
    │   └── ucsie_phy.v             # UCIe physical layer
    └── tb/
```

## Limitations and Future Work

- Current routing doesn't support deadlock avoidance
- No virtual channels for congestion management
- Boundary interfaces are untagged (could add I/O controllers)
- No global arbitration for external NoC access

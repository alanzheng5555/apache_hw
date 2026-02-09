// Chip Top-Level - 8x8 Core Mesh Network
// 64 cores arranged in 8 rows x 8 columns
// Address routing: bits[5:3]=column, bits[8:6]=row

`timescale 1ns/1ps

module chip_top #(
    parameter CORES_X = 8,        // Columns
    parameter CORES_Y = 8,        // Rows
    parameter DATA_W = 64,
    parameter ADDR_W = 32
)(
    // System signals
    input  wire                 clk,
    input  wire                 rst_n,
    
    // ==========================================
    // External AXI Master Interface (to NoC)
    // ==========================================
    output wire                 ext_m_awvalid,
    input  wire                 ext_m_awready,
    output wire [ADDR_W-1:0]    ext_m_awaddr,
    output wire [7:0]          ext_m_awlen,
    output wire [2:0]           ext_m_awsize,
    output wire [1:0]           ext_m_awburst,
    
    output wire                 ext_m_wvalid,
    input  wire                 ext_m_wready,
    output wire [DATA_W-1:0]    ext_m_wdata,
    output wire [(DATA_W/8)-1:0] ext_m_wstrb,
    output wire                 ext_m_wlast,
    
    output wire                 ext_m_arvalid,
    input  wire                 ext_m_arready,
    output wire [ADDR_W-1:0]    ext_m_araddr,
    output wire [7:0]           ext_m_arlen,
    output wire [2:0]           ext_m_arsize,
    output wire [1:0]           ext_m_arburst,
    
    input  wire                 ext_m_rvalid,
    output wire                 ext_m_rready,
    input  wire [DATA_W-1:0]    ext_m_rdata,
    input  wire                 ext_m_rlast,
    
    // ==========================================
    // External AXI Slave Interface (from NoC)
    // ==========================================
    input  wire                 ext_s_awvalid,
    output wire                 ext_s_awready,
    input  wire [ADDR_W-1:0]    ext_s_awaddr,
    input  wire [7:0]          ext_s_awlen,
    input  wire [2:0]           ext_s_awsize,
    input  wire [1:0]           ext_s_awburst,
    
    input  wire                 ext_s_wvalid,
    output wire                 ext_s_wready,
    input  wire [DATA_W-1:0]    ext_s_wdata,
    input  wire [(DATA_W/8)-1:0] ext_s_wstrb,
    input  wire                 ext_s_wlast,
    
    input  wire                 ext_s_arvalid,
    output wire                 ext_s_arready,
    input  wire [ADDR_W-1:0]    ext_s_araddr,
    input  wire [7:0]           ext_s_arlen,
    input  wire [2:0]           ext_s_arsize,
    input  wire [1:0]           ext_s_arburst,
    
    output wire                 ext_s_rvalid,
    input  wire                 ext_s_rready,
    output wire [DATA_W-1:0]    ext_s_rdata,
    output wire                 ext_s_rlast,
    
    // ==========================================
    // PE Control Interface
    // ==========================================
    input  wire [CORES_X*CORES_Y-1:0]  pe_start,
    input  wire [31:0]                 pe_instruction,
    output wire [CORES_X*CORES_Y-1:0]  pe_done
);

    // ==========================================
    // Mesh Network Parameters
    // ==========================================
    localparam NUM_CORES = CORES_X * CORES_Y;  // 64
    
    // Port indices for core interfaces
    localparam PORT_ID_NOC_SLAVE = 0;
    localparam PORT_ID_NOC_MASTER = 1;
    localparam PORT_ID_AXI_SLAVE0 = 2;
    localparam PORT_ID_AXI_SLAVE1 = 3;
    localparam PORT_ID_AXI_MASTER0 = 4;
    localparam PORT_ID_AXI_MASTER1 = 5;
    
    // ==========================================
    // Core Grid Signals
    // ==========================================
    // Generate 2D array of core instances
    genvar x, y;
    integer i, j;
    
    // Core instances: core[x][y] where x=column (0-7), y=row (0-7)
    // [0][0] = bottom-left, [7][7] = top-right
    
    // ==========================================
    // Mesh Interconnect Signals
    // ==========================================
    
    // Horizontal connections (east-west between adjacent cores)
    // hcon_left[x][y] = signals from core[x-1][y] to core[x][y]
    // hcon_right[x][y] = signals from core[x+1][y] to core[x][y]
    
    wire [DATA_W-1:0]   hcon_wdata [CORES_X:0][CORES_Y-1:0];
    wire [(DATA_W/8)-1:0] hcon_wstrb [CORES_X:0][CORES_Y-1:0];
    wire                 hcon_wvalid [CORES_X:0][CORES_Y-1:0];
    wire                 hcon_wready [CORES_X:0][CORES_Y-1:0];
    wire                 hcon_wlast [CORES_X:0][CORES_Y-1:0];
    
    wire [ADDR_W-1:0]   hcon_awaddr [CORES_X:0][CORES_Y-1:0];
    wire [7:0]          hcon_awlen [CORES_X:0][CORES_Y-1:0];
    wire [2:0]          hcon_awsize [CORES_X:0][CORES_Y-1:0];
    wire [1:0]          hcon_awburst [CORES_X:0][CORES_Y-1:0];
    wire                 hcon_awvalid [CORES_X:0][CORES_Y-1:0];
    wire                 hcon_awready [CORES_X:0][CORES_Y-1:0];
    
    wire [ADDR_W-1:0]   hcon_araddr [CORES_X:0][CORES_Y-1:0];
    wire [7:0]          hcon_arlen [CORES_X:0][CORES_Y-1:0];
    wire [2:0]          hcon_arsize [CORES_X:0][CORES_Y-1:0];
    wire [1:0]          hcon_arburst [CORES_X:0][CORES_Y-1:0];
    wire                 hcon_arvalid [CORES_X:0][CORES_Y-1:0];
    wire                 hcon_arready [CORES_X:0][CORES_Y-1:0];
    
    wire [DATA_W-1:0]   hcon_rdata [CORES_X:0][CORES_Y-1:0];
    wire                 hcon_rvalid [CORES_X:0][CORES_Y-1:0];
    wire                 hcon_rready [CORES_X:0][CORES_Y-1:0];
    wire                 hcon_rlast [CORES_X:0][CORES_Y-1:0];
    
    // Vertical connections (north-south between adjacent cores)
    // vcon_bottom[x][y] = signals from core[x][y-1] to core[x][y]
    // vcon_top[x][y] = signals from core[x][y+1] to core[x][y]
    
    wire [DATA_W-1:0]   vcon_wdata [CORES_X-1:0][CORES_Y:0];
    wire [(DATA_W/8)-1:0] vcon_wstrb [CORES_X-1:0][CORES_Y:0];
    wire                 vcon_wvalid [CORES_X-1:0][CORES_Y:0];
    wire                 vcon_wready [CORES_X-1:0][CORES_Y:0];
    wire                 vcon_wlast [CORES_X-1:0][CORES_Y:0];
    
    wire [ADDR_W-1:0]   vcon_awaddr [CORES_X-1:0][CORES_Y:0];
    wire [7:0]          vcon_awlen [CORES_X-1:0][CORES_Y:0];
    wire [2:0]          vcon_awsize [CORES_X-1:0][CORES_Y:0];
    wire [1:0]          vcon_awburst [CORES_X-1:0][CORES_Y:0];
    wire                 vcon_awvalid [CORES_X-1:0][CORES_Y:0];
    wire                 vcon_awready [CORES_X-1:0][CORES_Y:0];
    
    wire [ADDR_W-1:0]   vcon_araddr [CORES_X-1:0][CORES_Y:0];
    wire [7:0]          vcon_arlen [CORES_X-1:0][CORES_Y:0];
    wire [2:0]          vcon_arsize [CORES_X-1:0][CORES_Y:0];
    wire [1:0]          vcon_arburst [CORES_X-1:0][CORES_Y:0];
    wire                 vcon_arvalid [CORES_X-1:0][CORES_Y:0];
    wire                 vcon_arready [CORES_X-1:0][CORES_Y:0];
    
    wire [DATA_W-1:0]   vcon_rdata [CORES_X-1:0][CORES_Y:0];
    wire                 vcon_rvalid [CORES_X-1:0][CORES_Y:0];
    wire                 vcon_rready [CORES_X-1:0][CORES_Y:0];
    wire                 vcon_rlast [CORES_X-1:0][CORES_Y:0];
    
    // ==========================================
    // Boundary Interface Signals
    // ==========================================
    // West boundary (column 0 left side)
    wire [DATA_W-1:0]   west_wdata [CORES_Y-1:0];
    wire [(DATA_W/8)-1:0] west_wstrb [CORES_Y-1:0];
    wire                 west_wvalid [CORES_Y-1:0];
    wire                 west_wready [CORES_Y-1:0];
    wire                 west_wlast [CORES_Y-1:0];
    wire [ADDR_W-1:0]   west_awaddr [CORES_Y-1:0];
    wire [7:0]          west_awlen [CORES_Y-1:0];
    wire [2:0]          west_awsize [CORES_Y-1:0];
    wire [1:0]          west_awburst [CORES_Y-1:0];
    wire                 west_awvalid [CORES_Y-1:0];
    wire                 west_awready [CORES_Y-1:0];
    wire [ADDR_W-1:0]   west_araddr [CORES_Y-1:0];
    wire [7:0]          west_arlen [CORES_Y-1:0];
    wire [2:0]          west_arsize [CORES_Y-1:0];
    wire [1:0]          west_arburst [CORES_Y-1:0];
    wire                 west_arvalid [CORES_Y-1:0];
    wire                 west_arready [CORES_Y-1:0];
    wire [DATA_W-1:0]   west_rdata [CORES_Y-1:0];
    wire                 west_rvalid [CORES_Y-1:0];
    wire                 west_rready [CORES_Y-1:0];
    wire                 west_rlast [CORES_Y-1:0];
    
    // East boundary (column 7 right side)
    wire [DATA_W-1:0]   east_wdata [CORES_Y-1:0];
    wire [(DATA_W/8)-1:0] east_wstrb [CORES_Y-1:0];
    wire                 east_wvalid [CORES_Y-1:0];
    wire                 east_wready [CORES_Y-1:0];
    wire                 east_wlast [CORES_Y-1:0];
    wire [ADDR_W-1:0]   east_awaddr [CORES_Y-1:0];
    wire [7:0]          east_awlen [CORES_Y-1:0];
    wire [2:0]          east_awsize [CORES_Y-1:0];
    wire [1:0]          east_awburst [CORES_Y-1:0];
    wire                 east_awvalid [CORES_Y-1:0];
    wire                 east_awready [CORES_Y-1:0];
    wire [ADDR_W-1:0]   east_araddr [CORES_Y-1:0];
    wire [7:0]          east_arlen [CORES_Y-1:0];
    wire [2:0]          east_arsize [CORES_Y-1:0];
    wire [1:0]          east_arburst [CORES_Y-1:0];
    wire                 east_arvalid [CORES_Y-1:0];
    wire                 east_arready [CORES_Y-1:0];
    wire [DATA_W-1:0]   east_rdata [CORES_Y-1:0];
    wire                 east_rvalid [CORES_Y-1:0];
    wire                 east_rready [CORES_Y-1:0];
    wire                 east_rlast [CORES_Y-1:0];
    
    // South boundary (row 0 bottom side)
    wire [DATA_W-1:0]   south_wdata [CORES_X-1:0];
    wire [(DATA_W/8)-1:0] south_wstrb [CORES_X-1:0];
    wire                 south_wvalid [CORES_X-1:0];
    wire                 south_wready [CORES_X-1:0];
    wire                 south_wlast [CORES_X-1:0];
    wire [ADDR_W-1:0]   south_awaddr [CORES_X-1:0];
    wire [7:0]          south_awlen [CORES_X-1:0];
    wire [2:0]          south_awsize [CORES_X-1:0];
    wire [1:0]          south_awburst [CORES_X-1:0];
    wire                 south_awvalid [CORES_X-1:0];
    wire                 south_awready [CORES_X-1:0];
    wire [ADDR_W-1:0]   south_araddr [CORES_X-1:0];
    wire [7:0]          south_arlen [CORES_X-1:0];
    wire [2:0]          south_arsize [CORES_X-1:0];
    wire [1:0]          south_arburst [CORES_X-1:0];
    wire                 south_arvalid [CORES_X-1:0];
    wire                 south_arready [CORES_X-1:0];
    wire [DATA_W-1:0]   south_rdata [CORES_X-1:0];
    wire                 south_rvalid [CORES_X-1:0];
    wire                 south_rready [CORES_X-1:0];
    wire                 south_rlast [CORES_X-1:0];
    
    // North boundary (row 7 top side)
    wire [DATA_W-1:0]   north_wdata [CORES_X-1:0];
    wire [(DATA_W/8)-1:0] north_wstrb [CORES_X-1:0];
    wire                 north_wvalid [CORES_X-1:0];
    wire                 north_wready [CORES_X-1:0];
    wire                 north_wlast [CORES_X-1:0];
    wire [ADDR_W-1:0]   north_awaddr [CORES_X-1:0];
    wire [7:0]          north_awlen [CORES_X-1:0];
    wire [2:0]          north_awsize [CORES_X-1:0];
    wire [1:0]          north_awburst [CORES_X-1:0];
    wire                 north_awvalid [CORES_X-1:0];
    wire                 north_awready [CORES_X-1:0];
    wire [ADDR_W-1:0]   north_araddr [CORES_X-1:0];
    wire [7:0]          north_arlen [CORES_X-1:0];
    wire [2:0]          north_arsize [CORES_X-1:0];
    wire [1:0]          north_arburst [CORES_X-1:0];
    wire                 north_arvalid [CORES_X-1:0];
    wire                 north_arready [CORES_X-1:0];
    wire [DATA_W-1:0]   north_rdata [CORES_X-1:0];
    wire                 north_rvalid [CORES_X-1:0];
    wire                 north_rready [CORES_X-1:0];
    wire                 north_rlast [CORES_X-1:0];
    
    // ==========================================
    // Generate Core Array
    // ==========================================
    generate
        for (y = 0; y < CORES_Y; y = y + 1) begin : row_gen
            for (x = 0; x < CORES_X; x = x + 1) begin : col_gen
                
                // Core ID: [x][y]
                // Position: column x, row y
                
                // Calculate PE done bit position
                localparam CORE_IDX = y * CORES_X + x;
                
                core #(
                    .DATA_W(DATA_W),
                    .ADDR_W(ADDR_W)
                ) u_core (
                    .clk(clk),
                    .rst_n(rst_n),
                    
                    // NOC interfaces (connected to external NoC)
                    // Port 0: NOC Slave (receives from NoC)
                    .noc_s_awvalid(ext_s_awvalid && (CORE_IDX == 0)),
                    .noc_s_awready(),
                    .noc_s_awaddr(ext_s_awaddr),
                    .noc_s_awlen(ext_s_awlen),
                    .noc_s_awsize(ext_s_awsize),
                    .noc_s_awburst(ext_s_awburst),
                    .noc_s_wvalid(ext_s_wvalid && (CORE_IDX == 0)),
                    .noc_s_wready(),
                    .noc_s_wdata(ext_s_wdata),
                    .noc_s_wstrb(ext_s_wstrb),
                    .noc_s_wlast(ext_s_wlast),
                    .noc_s_arvalid(ext_s_arvalid && (CORE_IDX == 0)),
                    .noc_s_arready(),
                    .noc_s_araddr(ext_s_araddr),
                    .noc_s_arlen(ext_s_arlen),
                    .noc_s_arsize(ext_s_arsize),
                    .noc_s_arburst(ext_s_arburst),
                    .noc_s_rvalid(),
                    .noc_s_rready(ext_s_rready),
                    .noc_s_rdata(),
                    .noc_s_rlast(),
                    
                    // Port 1: NOC Master (sends to NoC)
                    .noc_m_awvalid(ext_m_awvalid && (CORE_IDX == 0)),
                    .noc_m_awready(ext_m_awready),
                    .noc_m_awaddr(ext_m_awaddr),
                    .noc_m_awlen(ext_m_awlen),
                    .noc_m_awsize(ext_m_awsize),
                    .noc_m_awburst(ext_m_awburst),
                    .noc_m_wvalid(ext_m_wvalid && (CORE_IDX == 0)),
                    .noc_m_wready(ext_m_wready),
                    .noc_m_wdata(ext_m_wdata),
                    .noc_m_wstrb(ext_m_wstrb),
                    .noc_m_wlast(ext_m_wlast),
                    .noc_m_arvalid(ext_m_arvalid && (CORE_IDX == 0)),
                    .noc_m_arready(ext_m_arready),
                    .noc_m_araddr(ext_m_araddr),
                    .noc_m_arlen(ext_m_arlen),
                    .noc_m_arsize(ext_m_arsize),
                    .noc_m_arburst(ext_m_arburst),
                    .noc_m_rvalid(ext_m_rvalid),
                    .noc_m_rready(),
                    .noc_m_rdata(ext_m_rdata),
                    .noc_m_rlast(ext_m_rlast),
                    
                    // Port 2: AXI Slave 0 (horizontal left - receives from left neighbor)
                    .s0_awvalid(hcon_awvalid[x][y]),
                    .s0_awready(hcon_awready[x][y]),
                    .s0_awaddr(hcon_awaddr[x][y]),
                    .s0_awlen(hcon_awlen[x][y]),
                    .s0_awsize(hcon_awsize[x][y]),
                    .s0_awburst(hcon_awburst[x][y]),
                    .s0_wvalid(hcon_wvalid[x][y]),
                    .s0_wready(hcon_wready[x][y]),
                    .s0_wdata(hcon_wdata[x][y]),
                    .s0_wstrb(hcon_wstrb[x][y]),
                    .s0_wlast(hcon_wlast[x][y]),
                    .s0_arvalid(hcon_arvalid[x][y]),
                    .s0_arready(hcon_arready[x][y]),
                    .s0_araddr(hcon_araddr[x][y]),
                    .s0_arlen(hcon_arlen[x][y]),
                    .s0_arsize(hcon_arsize[x][y]),
                    .s0_arburst(hcon_arburst[x][y]),
                    .s0_rvalid(hcon_rvalid[x][y]),
                    .s0_rready(hcon_rready[x][y]),
                    .s0_rdata(hcon_rdata[x][y]),
                    .s0_rlast(hcon_rlast[x][y]),
                    
                    // Port 3: AXI Slave 1 (vertical bottom - receives from bottom neighbor)
                    .s1_awvalid(vcon_awvalid[x][y]),
                    .s1_awready(vcon_awready[x][y]),
                    .s1_awaddr(vcon_awaddr[x][y]),
                    .s1_awlen(vcon_awlen[x][y]),
                    .s1_awsize(vcon_awsize[x][y]),
                    .s1_awburst(vcon_awburst[x][y]),
                    .s1_wvalid(vcon_wvalid[x][y]),
                    .s1_wready(vcon_wready[x][y]),
                    .s1_wdata(vcon_wdata[x][y]),
                    .s1_wstrb(vcon_wstrb[x][y]),
                    .s1_wlast(vcon_wlast[x][y]),
                    .s1_arvalid(vcon_arvalid[x][y]),
                    .s1_arready(vcon_arready[x][y]),
                    .s1_araddr(vcon_araddr[x][y]),
                    .s1_arlen(vcon_arlen[x][y]),
                    .s1_arsize(vcon_arsize[x][y]),
                    .s1_arburst(vcon_arburst[x][y]),
                    .s1_rvalid(vcon_rvalid[x][y]),
                    .s1_rready(vcon_rready[x][y]),
                    .s1_rdata(vcon_rdata[x][y]),
                    .s1_rlast(vcon_rlast[x][y]),
                    
                    // Port 4: AXI Master 0 (horizontal right - sends to right neighbor)
                    .m0_awvalid(hcon_awvalid[x+1][y]),
                    .m0_awready(hcon_awready[x+1][y]),
                    .m0_awaddr(hcon_awaddr[x+1][y]),
                    .m0_awlen(hcon_awlen[x+1][y]),
                    .m0_awsize(hcon_awsize[x+1][y]),
                    .m0_awburst(hcon_awburst[x+1][y]),
                    .m0_wvalid(hcon_wvalid[x+1][y]),
                    .m0_wready(hcon_wready[x+1][y]),
                    .m0_wdata(hcon_wdata[x+1][y]),
                    .m0_wstrb(hcon_wstrb[x+1][y]),
                    .m0_wlast(hcon_wlast[x+1][y]),
                    .m0_arvalid(hcon_arvalid[x+1][y]),
                    .m0_arready(hcon_arready[x+1][y]),
                    .m0_araddr(hcon_araddr[x+1][y]),
                    .m0_arlen(hcon_arlen[x+1][y]),
                    .m0_arsize(hcon_arsize[x+1][y]),
                    .m0_arburst(hcon_arburst[x+1][y]),
                    .m0_rvalid(hcon_rvalid[x+1][y]),
                    .m0_rready(hcon_rready[x+1][y]),
                    .m0_rdata(hcon_rdata[x+1][y]),
                    .m0_rlast(hcon_rlast[x+1][y]),
                    
                    // Port 5: AXI Master 1 (vertical top - sends to top neighbor)
                    .m1_awvalid(vcon_awvalid[x][y+1]),
                    .m1_awready(vcon_awready[x][y+1]),
                    .m1_awaddr(vcon_awaddr[x][y+1]),
                    .m1_awlen(vcon_awlen[x][y+1]),
                    .m1_awsize(vcon_awsize[x][y+1]),
                    .m1_awburst(vcon_awburst[x][y+1]),
                    .m1_wvalid(vcon_wvalid[x][y+1]),
                    .m1_wready(vcon_wready[x][y+1]),
                    .m1_wdata(vcon_wdata[x][y+1]),
                    .m1_wstrb(vcon_wstrb[x][y+1]),
                    .m1_wlast(vcon_wlast[x][y+1]),
                    .m1_arvalid(vcon_arvalid[x][y+1]),
                    .m1_arready(vcon_arready[x][y+1]),
                    .m1_araddr(vcon_araddr[x][y+1]),
                    .m1_arlen(vcon_arlen[x][y+1]),
                    .m1_arsize(vcon_arsize[x][y+1]),
                    .m1_arburst(vcon_arburst[x][y+1]),
                    .m1_rvalid(vcon_rvalid[x][y+1]),
                    .m1_rready(vcon_rready[x][y+1]),
                    .m1_rdata(vcon_rdata[x][y+1]),
                    .m1_rlast(vcon_rlast[x][y+1]),
                    
                    // PE control
                    .pe_start(pe_start[CORE_IDX]),
                    .pe_instruction(pe_instruction),
                    .pe_done(pe_done[CORE_IDX])
                );
                
            end
        end
    endgenerate
    
    // ==========================================
    // Boundary Connections
    // ==========================================
    
    // West boundary (column 0, left side)
    // hcon[0][y] connects to west[y]
    for (y = 0; y < CORES_Y; y = y + 1) begin : west_bound
        assign west_awvalid[y] = 1'b0;
        assign west_awaddr[y] = {ADDR_W{1'b0}};
        assign west_awlen[y] = 8'd0;
        assign west_awsize[y] = 3'd0;
        assign west_awburst[y] = 2'd0;
        assign west_wvalid[y] = 1'b0;
        assign west_wdata[y] = {DATA_W{1'b0}};
        assign west_wstrb[y] = {(DATA_W/8){1'b0}};
        assign west_wlast[y] = 1'b0;
        assign west_arvalid[y] = 1'b0;
        assign west_araddr[y] = {ADDR_W{1'b0}};
        assign west_arlen[y] = 8'd0;
        assign west_arsize[y] = 3'd0;
        assign west_arburst[y] = 2'd0;
    end
    
    // East boundary (column 7, right side)
    // hcon[8][y] connects to east[y]
    for (y = 0; y < CORES_Y; y = y + 1) begin : east_bound
        assign east_awvalid[y] = 1'b0;
        assign east_awaddr[y] = {ADDR_W{1'b0}};
        assign east_awlen[y] = 8'd0;
        assign east_awsize[y] = 3'd0;
        assign east_awburst[y] = 2'd0;
        assign east_wvalid[y] = 1'b0;
        assign east_wdata[y] = {DATA_W{1'b0}};
        assign east_wstrb[y] = {(DATA_W/8){1'b0}};
        assign east_wlast[y] = 1'b0;
        assign east_arvalid[y] = 1'b0;
        assign east_araddr[y] = {ADDR_W{1'b0}};
        assign east_arlen[y] = 8'd0;
        assign east_arsize[y] = 3'd0;
        assign east_arburst[y] = 2'd0;
    end
    
    // South boundary (row 0, bottom side)
    // vcon[x][0] connects to south[x]
    for (x = 0; x < CORES_X; x = x + 1) begin : south_bound
        assign south_awvalid[x] = 1'b0;
        assign south_awaddr[x] = {ADDR_W{1'b0}};
        assign south_awlen[x] = 8'd0;
        assign south_awsize[x] = 3'd0;
        assign south_awburst[x] = 2'd0;
        assign south_wvalid[x] = 1'b0;
        assign south_wdata[x] = {DATA_W{1'b0}};
        assign south_wstrb[x] = {(DATA_W/8){1'b0}};
        assign south_wlast[x] = 1'b0;
        assign south_arvalid[x] = 1'b0;
        assign south_araddr[x] = {ADDR_W{1'b0}};
        assign south_arlen[x] = 8'd0;
        assign south_arsize[x] = 3'd0;
        assign south_arburst[x] = 2'd0;
    end
    
    // North boundary (row 7, top side)
    // vcon[x][8] connects to north[x]
    for (x = 0; x < CORES_X; x = x + 1) begin : north_bound
        assign north_awvalid[x] = 1'b0;
        assign north_awaddr[x] = {ADDR_W{1'b0}};
        assign north_awlen[x] = 8'd0;
        assign north_awsize[x] = 3'd0;
        assign north_awburst[x] = 2'd0;
        assign north_wvalid[x] = 1'b0;
        assign north_wdata[x] = {DATA_W{1'b0}};
        assign north_wstrb[x] = {(DATA_W/8){1'b0}};
        assign north_wlast[x] = 1'b0;
        assign north_arvalid[x] = 1'b0;
        assign north_araddr[x] = {ADDR_W{1'b0}};
        assign north_arlen[x] = 8'd0;
        assign north_arsize[x] = 3'd0;
        assign north_arburst[x] = 2'd0;
    end
    
    // Tie-off unused boundary ready signals
    for (y = 0; y < CORES_Y; y = y + 1) begin : west_ready
        assign hcon_awready[0][y] = west_awready[y];
        assign hcon_wready[0][y] = west_wready[y];
        assign hcon_arready[0][y] = west_arready[y];
        assign hcon_rready[0][y] = west_rready[y];
        assign west_rvalid[y] = hcon_rvalid[0][y];
        assign west_rdata[y] = hcon_rdata[0][y];
        assign west_rlast[y] = hcon_rlast[0][y];
        
        assign hcon_awready[CORES_X][y] = east_awready[y];
        assign hcon_wready[CORES_X][y] = east_wready[y];
        assign hcon_arready[CORES_X][y] = east_arready[y];
        assign hcon_rready[CORES_X][y] = east_rready[y];
        assign east_rvalid[y] = hcon_rvalid[CORES_X][y];
        assign east_rdata[y] = hcon_rdata[CORES_X][y];
        assign east_rlast[y] = hcon_rlast[CORES_X][y];
    end
    
    for (x = 0; x < CORES_X; x = x + 1) begin : south_ready
        assign vcon_awready[x][0] = south_awready[x];
        assign vcon_wready[x][0] = south_wready[x];
        assign vcon_arready[x][0] = south_arready[x];
        assign vcon_rready[x][0] = south_rready[x];
        assign south_rvalid[x] = vcon_rvalid[x][0];
        assign south_rdata[x] = vcon_rdata[x][0];
        assign south_rlast[x] = vcon_rlast[x][0];
        
        assign vcon_awready[x][CORES_Y] = north_awready[x];
        assign vcon_wready[x][CORES_Y] = north_wready[x];
        assign vcon_arready[x][CORES_Y] = north_arready[x];
        assign vcon_rready[x][CORES_Y] = north_rready[x];
        assign north_rvalid[x] = vcon_rvalid[x][CORES_Y];
        assign north_rdata[x] = vcon_rdata[x][CORES_Y];
        assign north_rlast[x] = vcon_rlast[x][CORES_Y];
    end

endmodule

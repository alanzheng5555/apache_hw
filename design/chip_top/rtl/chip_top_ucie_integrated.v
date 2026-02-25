// Chip Top with UCIE Integration - 8x8 Cores + Row-Ended UCIEs
// Simplified version: 每行(8个core)末尾放置1个UCIE,共8个UCIE

`timescale 1ns/1ps

module chip_top_ucie_integrated #(
    parameter CORES_X = 8,
    parameter CORES_Y = 8,
    parameter DATA_W = 64,
    parameter ADDR_W = 32,
    parameter UCIE_LANES = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    
    // UCIE物理接口 (8个UCIE, 每行一个)
    output wire [UCIE_LANES-1:0]  ucie_tx_p [CORES_Y-1:0],
    output wire [UCIE_LANES-1:0]  ucie_tx_n [CORES_Y-1:0],
    output wire                    ucie_tx_clk_p [CORES_Y-1:0],
    output wire                    ucie_tx_clk_n [CORES_Y-1:0],
    output wire                    ucie_tx_strobe [CORES_Y-1:0],
    
    input  wire [UCIE_LANES-1:0]  ucie_rx_p [CORES_Y-1:0],
    input  wire [UCIE_LANES-1:0]  ucie_rx_n [CORES_Y-1:0],
    input  wire                    ucie_rx_clk_p [CORES_Y-1:0],
    input  wire                    ucie_rx_clk_n [CORES_Y-1:0],
    input  wire                    ucie_rx_strobe [CORES_Y-1:0],
    
    output wire                    ucie_sb_tx [CORES_Y-1:0],
    input  wire                    ucie_sb_rx [CORES_Y-1:0],
    output wire                    ucie_ctrl_enable [CORES_Y-1:0],
    input  wire                    ucie_ctrl_ready [CORES_Y-1:0],
    output wire [31:0]             ucie_status [CORES_Y-1:0],
    
    // 外部AXI接口
    output wire                 ext_m_awvalid, input ext_m_awready, output [ADDR_W-1:0] ext_m_awaddr,
    output [7:0] ext_m_awlen, output [2:0] ext_m_awsize, output [1:0] ext_m_awburst,
    output wire ext_m_wvalid, input ext_m_wready, output [DATA_W-1:0] ext_m_wdata,
    output [(DATA_W/8)-1:0] ext_m_wstrb, output ext_m_wlast,
    output wire ext_m_arvalid, input ext_m_arready, output [ADDR_W-1:0] ext_m_araddr,
    output [7:0] ext_m_arlen, output [2:0] ext_m_arsize, output [1:0] ext_m_arburst,
    input ext_m_rvalid, output ext_m_rready, input [DATA_W-1:0] ext_m_rdata, input ext_m_rlast,
    
    input ext_s_awvalid, output ext_s_awready, input [ADDR_W-1:0] ext_s_awaddr,
    input [7:0] ext_s_awlen, input [2:0] ext_s_awsize, input [1:0] ext_s_awburst,
    input ext_s_wvalid, output ext_s_wready, input [DATA_W-1:0] ext_s_wdata,
    input [(DATA_W/8)-1:0] ext_s_wstrb, input ext_s_wlast,
    input ext_s_arvalid, output ext_s_arready, input [ADDR_W-1:0] ext_s_araddr,
    input [7:0] ext_s_arlen, input [2:0] ext_s_arsize, input [1:0] ext_s_arburst,
    output ext_s_rvalid, input ext_s_rready, output [DATA_W-1:0] ext_s_rdata, output ext_s_rlast,
    
    // PE控制
    input [CORES_X*CORES_Y-1:0] pe_start, input [31:0] pe_instruction,
    output [CORES_X*CORES_Y-1:0] pe_done
);

    localparam NUM_CORES = CORES_X * CORES_Y;
    localparam UCIE_DATA_W = 256;
    localparam UCIE_ADDR_W = 64;
    localparam UCIE_ID_W = 4;
    
    genvar x, y;
    
    // 网格互联信号 (Horizontal)
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
    
    // 网格互联信号 (Vertical)
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
    
    // UCIE AXI桥接信号
    wire [UCIE_ID_W-1:0]    ucie_m_awid [CORES_Y-1:0];
    wire [UCIE_ADDR_W-1:0]  ucie_m_awaddr [CORES_Y-1:0];
    wire [7:0]             ucie_m_awlen [CORES_Y-1:0];
    wire [2:0]             ucie_m_awsize [CORES_Y-1:0];
    wire [1:0]             ucie_m_awburst [CORES_Y-1:0];
    wire                   ucie_m_awvalid [CORES_Y-1:0];
    wire                   ucie_m_awready [CORES_Y-1:0];
    
    wire [UCIE_DATA_W-1:0] ucie_m_wdata [CORES_Y-1:0];
    wire [(UCIE_DATA_W/8)-1:0] ucie_m_wstrb [CORES_Y-1:0];
    wire                   ucie_m_wlast [CORES_Y-1:0];
    wire                   ucie_m_wvalid [CORES_Y-1:0];
    wire                   ucie_m_wready [CORES_Y-1:0];
    
    wire [UCIE_ID_W-1:0]   ucie_m_bid [CORES_Y-1:0];
    wire [1:0]            ucie_m_bresp [CORES_Y-1:0];
    wire                   ucie_m_bvalid [CORES_Y-1:0];
    wire                   ucie_m_bready [CORES_Y-1:0];
    
    wire [UCIE_ID_W-1:0]   ucie_m_arid [CORES_Y-1:0];
    wire [UCIE_ADDR_W-1:0] ucie_m_araddr [CORES_Y-1:0];
    wire [7:0]            ucie_m_arlen [CORES_Y-1:0];
    wire [2:0]            ucie_m_arsize [CORES_Y-1:0];
    wire [1:0]            ucie_m_arburst [CORES_Y-1:0];
    wire                   ucie_m_arvalid [CORES_Y-1:0];
    wire                   ucie_m_arready [CORES_Y-1:0];
    
    wire [UCIE_ID_W-1:0]   ucie_m_rid [CORES_Y-1:0];
    wire [UCIE_DATA_W-1:0] ucie_m_rdata [CORES_Y-1:0];
    wire [1:0]            ucie_m_rresp [CORES_Y-1:0];
    wire                   ucie_m_rlast [CORES_Y-1:0];
    wire                   ucie_m_rvalid [CORES_Y-1:0];
    wire                   ucie_m_rready [CORES_Y-1:0];
    
    wire [UCIE_ID_W-1:0]   ucie_s_awid [CORES_Y-1:0];
    wire [UCIE_ADDR_W-1:0] ucie_s_awaddr [CORES_Y-1:0];
    wire [7:0]            ucie_s_awlen [CORES_Y-1:0];
    wire [2:0]            ucie_s_awsize [CORES_Y-1:0];
    wire [1:0]            ucie_s_awburst [CORES_Y-1:0];
    wire                   ucie_s_awvalid [CORES_Y-1:0];
    wire                   ucie_s_awready [CORES_Y-1:0];
    
    wire [UCIE_DATA_W-1:0] ucie_s_wdata [CORES_Y-1:0];
    wire [(UCIE_DATA_W/8)-1:0] ucie_s_wstrb [CORES_Y-1:0];
    wire                   ucie_s_wlast [CORES_Y-1:0];
    wire                   ucie_s_wvalid [CORES_Y-1:0];
    wire                   ucie_s_wready [CORES_Y-1:0];
    
    wire [UCIE_ID_W-1:0]   ucie_s_bid [CORES_Y-1:0];
    wire [1:0]            ucie_s_bresp [CORES_Y-1:0];
    wire                   ucie_s_bvalid [CORES_Y-1:0];
    wire                   ucie_s_bready [CORES_Y-1:0];
    
    wire [UCIE_ID_W-1:0]   ucie_s_arid [CORES_Y-1:0];
    wire [UCIE_ADDR_W-1:0] ucie_s_araddr [CORES_Y-1:0];
    wire [7:0]            ucie_s_arlen [CORES_Y-1:0];
    wire [2:0]            ucie_s_arsize [CORES_Y-1:0];
    wire [1:0]            ucie_s_arburst [CORES_Y-1:0];
    wire                   ucie_s_arvalid [CORES_Y-1:0];
    wire                   ucie_s_arready [CORES_Y-1:0];
    
    wire [UCIE_ID_W-1:0]   ucie_s_rid [CORES_Y-1:0];
    wire [UCIE_DATA_W-1:0] ucie_s_rdata [CORES_Y-1:0];
    wire [1:0]            ucie_s_rresp [CORES_Y-1:0];
    wire                   ucie_s_rlast [CORES_Y-1:0];
    wire                   ucie_s_rvalid [CORES_Y-1:0];
    wire                   ucie_s_rready [CORES_Y-1:0];

    // ==========================================
    // 生成8x8 Core数组
    // ==========================================
    generate
        for (y = 0; y < CORES_Y; y = y + 1) begin : row_gen
            for (x = 0; x < CORES_X; x = x + 1) begin : col_gen
                
                localparam CORE_IDX = y * CORES_X + x;
                localparam IS_LAST_COL = (x == CORES_X - 1);  // Column 7
                
                core #(
                    .DATA_W(DATA_W),
                    .ADDR_W(ADDR_W)
                ) u_core (
                    .clk(clk),
                    .rst_n(rst_n),
                    
                    // NOC接口
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
                    
                    // Port 2: AXI Slave 0 (West)
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
                    
                    // Port 3: AXI Slave 1 (South)
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
                    
                    // Port 4: AXI Master 0 (East -> UCIE for last column)
                    .m0_awvalid(IS_LAST_COL ? ucie_s_awvalid[y] : hcon_awvalid[x+1][y]),
                    .m0_awready(IS_LAST_COL ? ucie_s_awready[y] : hcon_awready[x+1][y]),
                    .m0_awaddr(IS_LAST_COL ? ucie_s_awaddr[y][ADDR_W-1:0] : hcon_awaddr[x+1][y]),
                    .m0_awlen(IS_LAST_COL ? ucie_s_awlen[y] : hcon_awlen[x+1][y]),
                    .m0_awsize(IS_LAST_COL ? ucie_s_awsize[y] : hcon_awsize[x+1][y]),
                    .m0_awburst(IS_LAST_COL ? ucie_s_awburst[y] : hcon_awburst[x+1][y]),
                    .m0_wvalid(IS_LAST_COL ? ucie_s_wvalid[y] : hcon_wvalid[x+1][y]),
                    .m0_wready(IS_LAST_COL ? ucie_s_wready[y] : hcon_wready[x+1][y]),
                    .m0_wdata(IS_LAST_COL ? ucie_s_wdata[y][DATA_W-1:0] : hcon_wdata[x+1][y]),
                    .m0_wstrb(IS_LAST_COL ? ucie_s_wstrb[y][(DATA_W/8)-1:0] : hcon_wstrb[x+1][y]),
                    .m0_wlast(IS_LAST_COL ? ucie_s_wlast[y] : hcon_wlast[x+1][y]),
                    .m0_arvalid(IS_LAST_COL ? ucie_s_arvalid[y] : hcon_arvalid[x+1][y]),
                    .m0_arready(IS_LAST_COL ? ucie_s_arready[y] : hcon_arready[x+1][y]),
                    .m0_araddr(IS_LAST_COL ? ucie_s_araddr[y][ADDR_W-1:0] : hcon_araddr[x+1][y]),
                    .m0_arlen(IS_LAST_COL ? ucie_s_arlen[y] : hcon_arlen[x+1][y]),
                    .m0_arsize(IS_LAST_COL ? ucie_s_arsize[y] : hcon_arsize[x+1][y]),
                    .m0_arburst(IS_LAST_COL ? ucie_s_arburst[y] : hcon_arburst[x+1][y]),
                    .m0_rvalid(IS_LAST_COL ? ucie_s_rvalid[y] : hcon_rvalid[x+1][y]),
                    .m0_rready(IS_LAST_COL ? ucie_s_rready[y] : hcon_rready[x+1][y]),
                    .m0_rdata(IS_LAST_COL ? {{(UCIE_DATA_W-DATA_W){1'b0}}, ucie_s_rdata[y]} : hcon_rdata[x+1][y]),
                    .m0_rlast(IS_LAST_COL ? ucie_s_rlast[y] : hcon_rlast[x+1][y]),
                    
                    // Port 5: AXI Master 1 (North)
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
                    
                    .pe_start(pe_start[CORE_IDX]),
                    .pe_instruction(pe_instruction),
                    .pe_done(pe_done[CORE_IDX])
                );
                
            end
        end
    endgenerate
    
    // ==========================================
    // 边界连接 (West - 置零)
    // ==========================================
    generate
        for (y = 0; y < CORES_Y; y = y + 1) begin : west_bound
            assign hcon_awvalid[0][y] = 1'b0;
            assign hcon_awaddr[0][y] = {ADDR_W{1'b0}};
            assign hcon_awlen[0][y] = 8'd0;
            assign hcon_awsize[0][y] = 3'd0;
            assign hcon_awburst[0][y] = 2'd0;
            assign hcon_wvalid[0][y] = 1'b0;
            assign hcon_wdata[0][y] = {DATA_W{1'b0}};
            assign hcon_wstrb[0][y] = {(DATA_W/8){1'b0}};
            assign hcon_wlast[0][y] = 1'b0;
            assign hcon_arvalid[0][y] = 1'b0;
            assign hcon_araddr[0][y] = {ADDR_W{1'b0}};
            assign hcon_arlen[0][y] = 8'd0;
            assign hcon_arsize[0][y] = 3'd0;
            assign hcon_arburst[0][y] = 2'd0;
            
            assign hcon_awready[0][y] = 1'b1;
            assign hcon_wready[0][y] = 1'b1;
            assign hcon_arready[0][y] = 1'b1;
            assign hcon_rready[0][y] = 1'b1;
            assign hcon_rvalid[0][y] = 1'b0;
            assign hcon_rdata[0][y] = {DATA_W{1'b0}};
            assign hcon_rlast[0][y] = 1'b0;
        end
    endgenerate
    
    // ==========================================
    // 边界连接 (South - 置零)
    // ==========================================
    generate
        for (x = 0; x < CORES_X; x = x + 1) begin : south_bound
            assign vcon_awvalid[x][0] = 1'b0;
            assign vcon_awaddr[x][0] = {ADDR_W{1'b0}};
            assign vcon_awlen[x][0] = 8'd0;
            assign vcon_awsize[x][0] = 3'd0;
            assign vcon_awburst[x][0] = 2'd0;
            assign vcon_wvalid[x][0] = 1'b0;
            assign vcon_wdata[x][0] = {DATA_W{1'b0}};
            assign vcon_wstrb[x][0] = {(DATA_W/8){1'b0}};
            assign vcon_wlast[x][0] = 1'b0;
            assign vcon_arvalid[x][0] = 1'b0;
            assign vcon_araddr[x][0] = {ADDR_W{1'b0}};
            assign vcon_arlen[x][0] = 8'd0;
            assign vcon_arsize[x][0] = 3'd0;
            assign vcon_arburst[x][0] = 2'd0;
            
            assign vcon_awready[x][0] = 1'b1;
            assign vcon_wready[x][0] = 1'b1;
            assign vcon_arready[x][0] = 1'b1;
            assign vcon_rready[x][0] = 1'b1;
            assign vcon_rvalid[x][0] = 1'b0;
            assign vcon_rdata[x][0] = {DATA_W{1'b0}};
            assign vcon_rlast[x][0] = 1'b0;
        end
    endgenerate
    
    // ==========================================
    // 8个UCIE实例 (每行一个)
    // ==========================================
    generate
        for (y = 0; y < CORES_Y; y = y + 1) begin : ucie_inst
            
            // UCIE Top实例
            ucsie_top #(
                .NUM_LANES(UCIE_LANES),
                .DATA_W(UCIE_DATA_W),
                .ADDR_W(UCIE_ADDR_W),
                .ID_W(UCIE_ID_W)
            ) u_ucie (
                .clk(clk),
                .rst_n(rst_n),
                
                // AXI Master (连接到外部chiplet)
                .m_awid(ucie_m_awid[y]),
                .m_awaddr(ucie_m_awaddr[y]),
                .m_awlen(ucie_m_awlen[y]),
                .m_awsize(ucie_m_awsize[y]),
                .m_awburst(ucie_m_awburst[y]),
                .m_awvalid(ucie_m_awvalid[y]),
                .m_awready(ucie_m_awready[y]),
                .m_wdata(ucie_m_wdata[y]),
                .m_wstrb(ucie_m_wstrb[y]),
                .m_wlast(ucie_m_wlast[y]),
                .m_wvalid(ucie_m_wvalid[y]),
                .m_wready(ucie_m_wready[y]),
                .m_bid(ucie_m_bid[y]),
                .m_bresp(ucie_m_bresp[y]),
                .m_bvalid(ucie_m_bvalid[y]),
                .m_bready(ucie_m_bready[y]),
                .m_arid(ucie_m_arid[y]),
                .m_araddr(ucie_m_araddr[y]),
                .m_arlen(ucie_m_arlen[y]),
                .m_arsize(ucie_m_arsize[y]),
                .m_arburst(ucie_m_arburst[y]),
                .m_arvalid(ucie_m_arvalid[y]),
                .m_arready(ucie_m_arready[y]),
                .m_rid(ucie_m_rid[y]),
                .m_rdata(ucie_m_rdata[y]),
                .m_rresp(ucie_m_rresp[y]),
                .m_rlast(ucie_m_rlast[y]),
                .m_rvalid(ucie_m_rvalid[y]),
                .m_rready(ucie_m_rready[y]),
                
                // AXI Slave (连接到Core[7][y])
                .s_awid(ucie_s_awid[y]),
                .s_awaddr(ucie_s_awaddr[y]),
                .s_awlen(ucie_s_awlen[y]),
                .s_awsize(ucie_s_awsize[y]),
                .s_awburst(ucie_s_awburst[y]),
                .s_awvalid(ucie_s_awvalid[y]),
                .s_awready(ucie_s_awready[y]),
                .s_wdata(ucie_s_wdata[y]),
                .s_wstrb(ucie_s_wstrb[y]),
                .s_wlast(ucie_s_wlast[y]),
                .s_wvalid(ucie_s_wvalid[y]),
                .s_wready(ucie_s_wready[y]),
                .s_bid(ucie_s_bid[y]),
                .s_bresp(ucie_s_bresp[y]),
                .s_bvalid(ucie_s_bvalid[y]),
                .s_bready(ucie_s_bready[y]),
                .s_arid(ucie_s_arid[y]),
                .s_araddr(ucie_s_araddr[y]),
                .s_arlen(ucie_s_arlen[y]),
                .s_arsize(ucie_s_arsize[y]),
                .s_arburst(ucie_s_arburst[y]),
                .s_arvalid(ucie_s_arvalid[y]),
                .s_arready(ucie_s_arready[y]),
                .s_rid(ucie_s_rid[y]),
                .s_rdata(ucie_s_rdata[y]),
                .s_rresp(ucie_s_rresp[y]),
                .s_rlast(ucie_s_rlast[y]),
                .s_rvalid(ucie_s_rvalid[y]),
                .s_rready(ucie_s_rready[y]),
                
                // 物理接口
                .tx_lane_p(ucie_tx_p[y]),
                .tx_lane_n(ucie_tx_n[y]),
                .tx_clk_p(ucie_tx_clk_p[y]),
                .tx_clk_n(ucie_tx_clk_n[y]),
                .tx_strobe(ucie_tx_strobe[y]),
                .rx_lane_p(ucie_rx_p[y]),
                .rx_lane_n(ucie_rx_n[y]),
                .rx_clk_p(ucie_rx_clk_p[y]),
                .rx_clk_n(ucie_rx_clk_n[y]),
                .rx_strobe(ucie_rx_strobe[y]),
                .sb_tx(ucie_sb_tx[y]),
                .sb_rx(ucie_sb_rx[y]),
                
                // 控制
                .ctrl_enable(ucie_ctrl_enable[y]),
                .ctrl_ready(ucie_ctrl_ready[y]),
                .ctrl_status(ucie_status[y]),
                .link_status(),
                .lane_status()
            );
        end
    endgenerate

endmodule

// Simplified Router 6-Port - Fixed for Icarus Verilog

`timescale 1ns/1ps

module router_6port #(
    parameter PORTS = 6,
    parameter DATA_W = 64,
    parameter ADDR_W = 32,
    parameter ROUTE_ENTRIES = 8,
    parameter FIFO_DEPTH = 16
)(
    input clk, input rst_n,
    
    // AXI input ports (from masters)
    input [PORTS-1:0] s_awvalid, input [PORTS-1:0] s_arvalid,
    input [PORTS-1:0] [ADDR_W-1:0] s_awaddr, input [PORTS-1:0] [ADDR_W-1:0] s_araddr,
    input [DATA_W-1:0] s_wdata [PORTS-1:0],
    input [(DATA_W/8)-1:0] s_wstrb [PORTS-1:0],
    input s_wlast [PORTS-1:0],
    input [PORTS-1:0] s_bready,
    input [PORTS-1:0] s_rready,
    
    output reg [PORTS-1:0] s_awready, output reg [PORTS-1:0] s_arready,
    output reg [DATA_W-1:0] s_rdata [PORTS-1:0],
    output reg s_rlast [PORTS-1:0], output reg [PORTS-1:0] s_rvalid,
    output reg [PORTS-1:0] s_bvalid, output reg [1:0] s_bresp [PORTS-1:0],
    
    // AXI output ports (to slaves)
    output [PORTS-1:0] m_awvalid, output [PORTS-1:0] m_arvalid,
    output [PORTS-1:0] [ADDR_W-1:0] m_awaddr, output [PORTS-1:0] [ADDR_W-1:0] m_araddr,
    output [DATA_W-1:0] m_wdata [PORTS-1:0],
    output [(DATA_W/8)-1:0] m_wstrb [PORTS-1:0],
    output m_wlast [PORTS-1:0],
    input [PORTS-1:0] m_bready, input [PORTS-1:0] m_rready,
    
    input [PORTS-1:0] m_awready, input [PORTS-1:0] m_arready,
    input [DATA_W-1:0] m_rdata [PORTS-1:0], input m_rlast [PORTS-1:0],
    input [PORTS-1:0] m_rvalid, input [1:0] m_bresp [PORTS-1:0]
);
    
    localparam PORT_ID_NOC_SLAVE = 0;
    localparam PORT_ID_NOC_MASTER = 1;
    localparam PORT_ID_AXI_MASTER0 = 4;
    
    // Simplified routing using generate
    genvar i;
    
    // Ready signals - always ready for now
    always @(*) begin
        s_awready = {PORTS{1'b1}};
        s_arready = {PORTS{1'b1}};
    end
    
    // Generate loop for routing (Standard Verilog)
    generate
        for (i = 0; i < PORTS; i = i + 1) begin : route_loop
            always @(*) begin
                s_rvalid[i] = m_rvalid[4];
                s_rdata[i] = m_rdata[4];
                s_rlast[i] = m_rlast[4];
                s_bvalid[i] = m_bvalid[4] && (i == 0);
                s_bresp[i] = m_bresp[4];
            end
        end
    endgenerate
    
    // Route all masters to UCIE (port 4)
    assign m_awvalid = s_awvalid;
    assign m_arvalid = s_arvalid;
    assign m_awaddr = s_awaddr;
    assign m_araddr = s_araddr;
    assign m_wdata = s_wdata;
    assign m_wstrb = s_wstrb;
    assign m_wlast = s_wlast;
    assign m_bready = s_bready;
    assign m_rready = s_rready;

endmodule

// NoC Router Module - Top Level
// 3-port AXI4 router with APB configuration and traffic monitoring

`timescale 1ns/1ps

module router_top #(
    parameter PORTS = 3,
    parameter DATA_W = 64,
    parameter ADDR_W = 32,
    parameter FIFO_DEPTH = 16,
    parameter ROUTE_ENTRIES = 8
)(
    // System
    input  wire                 clk,
    input  wire                 rst_n,
    
    // ==========================================
    // AXI4 Input Ports (3 ports)
    // ==========================================
    // Write Address Channel
    input  wire [PORTS-1:0]     s_awvalid,
    output wire [PORTS-1:0]     s_awready,
    input  wire [ADDR_W-1:0]    s_awaddr [PORTS-1:0],
    input  wire [7:0]           s_awlen [PORTS-1:0],
    input  wire [2:0]          s_awsize [PORTS-1:0],
    input  wire [1:0]          s_awburst [PORTS-1:0],
    
    // Write Data Channel
    input  wire [PORTS-1:0]     s_wvalid,
    output wire [PORTS-1:0]     s_wready,
    input  wire [DATA_W-1:0]   s_wdata [PORTS-1:0],
    input  wire [(DATA_W/8)-1:0] s_wstrb [PORTS-1:0],
    input  wire [PORTS-1:0]     s_wlast,
    
    // Read Address Channel
    input  wire [PORTS-1:0]     s_arvalid,
    output wire [PORTS-1:0]     s_arready,
    input  wire [ADDR_W-1:0]    s_araddr [PORTS-1:0],
    input  wire [7:0]           s_arlen [PORTS-1:0],
    input  wire [2:0]          s_arsize [PORTS-1:0],
    input  wire [1:0]          s_arburst [PORTS-1:0],
    
    // Read Data Channel
    output wire [PORTS-1:0]     s_rvalid,
    input  wire [PORTS-1:0]     s_rready,
    output wire [DATA_W-1:0]   s_rdata [PORTS-1:0],
    output wire [PORTS-1:0]     s_rlast,
    
    // ==========================================
    // AXI4 Output Ports (3 ports)
    // ==========================================
    // Write Address Channel
    output wire [PORTS-1:0]     m_awvalid,
    input  wire [PORTS-1:0]     m_awready,
    output wire [ADDR_W-1:0]    m_awaddr [PORTS-1:0],
    output wire [7:0]           m_awlen [PORTS-1:0],
    output wire [2:0]          m_awsize [PORTS-1:0],
    output wire [1:0]          m_awburst [PORTS-1:0],
    
    // Write Data Channel
    output wire [PORTS-1:0]     m_wvalid,
    input  wire [PORTS-1:0]     m_wready,
    output wire [DATA_W-1:0]   m_wdata [PORTS-1:0],
    output wire [(DATA_W/8)-1:0] m_wstrb [PORTS-1:0],
    output wire [PORTS-1:0]     m_wlast,
    
    // Read Address Channel
    output wire [PORTS-1:0]     m_arvalid,
    input  wire [PORTS-1:0]     m_arready,
    output wire [ADDR_W-1:0]    m_araddr [PORTS-1:0],
    output wire [7:0]           m_arlen [PORTS-1:0],
    output wire [2:0]          m_arsize [PORTS-1:0],
    output wire [1:0]          m_arburst [PORTS-1:0],
    
    // Read Data Channel
    input  wire [PORTS-1:0]     m_rvalid,
    output wire [PORTS-1:0]     m_rready,
    input  wire [DATA_W-1:0]   m_rdata [PORTS-1:0],
    input  wire [PORTS-1:0]     m_rlast,
    
    // ==========================================
    // APB Configuration Interface
    // ==========================================
    input  wire [11:0]          paddr,
    input  wire                 pwrite,
    input  wire [31:0]         pwdata,
    input  wire                 psel,
    input  wire                 penable,
    output wire                 pready,
    output wire [31:0]         prdata
);
    
    // ==========================================
    // Signals
    // ==========================================
    wire [1:0] route_port [PORTS-1:0];  // Output port per input
    wire route_hit [PORTS-1:0];
    
    // FIFO signals
    wire [DATA_W-1:0] fifo_wdata [PORTS-1:0];
    wire fifo_wvalid [PORTS-1:0];
    wire fifo_wready [PORTS-1:0];
    wire fifo_rvalid [PORTS-1:0];
    wire [DATA_W-1:0] fifo_rdata [PORTS-1:0];
    wire fifo_rlast [PORTS-1:0];
    
    // Control signals
    wire [31:0] latency_in [PORTS-1:0];
    wire [63:0] byte_cnt_in [PORTS-1:0];
    wire [31:0] latency_out [PORTS-1:0];
    wire [63:0] byte_cnt_out [PORTS-1:0];
    
    // ==========================================
    // Instantiate Router Table
    // ==========================================
    router_table #(
        .ENTRIES(ROUTE_ENTRIES)
    ) u_router_table (
        .clk(clk),
        .rst_n(rst_n),
        .paddr(paddr),
        .pwdata(pwdata),
        .pwrite(pwrite),
        .psel(psel),
        .penable(penable),
        .pready(pready),
        .prdata(prdata),
        .lookup_addr(),  // To be connected
        .output_port(),
        .hit()
    );
    
    // ==========================================
    // Instantiate Traffic Monitor
    // ==========================================
    traffic_monitor #(
        .PORTS(PORTS)
    ) u_monitor (
        .clk(clk),
        .rst_n(rst_n),
        .paddr(paddr),
        .pwdata(pwdata),
        .pwrite(pwrite),
        .psel(psel),
        .penable(penable),
        .pready(pready),
        .prdata(prdata),
        .in_pkt_valid(),
        .in_pkt_last(),
        .in_byte_cnt(),
        .in_latency(),
        .out_pkt_valid(),
        .out_pkt_last(),
        .out_byte_cnt(),
        .out_latency()
    );
    
    // ==========================================
    // Port FIFOs and Routing Logic (Per Port)
    // ==========================================
    genvar port_idx;
    generate
        for (port_idx = 0; port_idx < PORTS; port_idx = port_idx + 1) begin : port_gen
            
            // Simplified: Just pass through for now
            // In full implementation, add FIFO and routing decision
            
            // Pass write channel
            assign s_awready[port_idx] = m_awready[route_port[port_idx]];
            assign m_awvalid[port_idx] = s_awvalid[port_idx];
            assign m_awaddr[port_idx] = s_awaddr[port_idx];
            assign m_awlen[port_idx] = s_awlen[port_idx];
            assign m_awsize[port_idx] = s_awsize[port_idx];
            assign m_awburst[port_idx] = s_awburst[port_idx];
            
            assign s_wready[port_idx] = m_wready[route_port[port_idx]];
            assign m_wvalid[port_idx] = s_wvalid[port_idx];
            assign m_wdata[port_idx] = s_wdata[port_idx];
            assign m_wstrb[port_idx] = s_wstrb[port_idx];
            assign m_wlast[port_idx] = s_wlast[port_idx];
            
            // Pass read channel
            assign s_arready[port_idx] = m_arready[route_port[port_idx]];
            assign m_arvalid[port_idx] = s_arvalid[port_idx];
            assign m_araddr[port_idx] = s_araddr[port_idx];
            assign m_arlen[port_idx] = s_arlen[port_idx];
            assign m_arsize[port_idx] = s_arsize[port_idx];
            assign m_arburst[port_idx] = s_arburst[port_idx];
            
            assign s_rvalid[port_idx] = m_rvalid[route_port[port_idx]];
            assign m_rready[port_idx] = s_rready[port_idx];
            assign s_rdata[port_idx] = m_rdata[route_port[port_idx]];
            assign s_rlast[port_idx] = m_rlast[route_port[port_idx]];
            
        end
    endgenerate
    
endmodule

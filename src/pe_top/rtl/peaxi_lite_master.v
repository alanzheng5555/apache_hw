//===================================================================
// PE AXI Lite Master - Simple AXI4-Lite interface wrapper
//===================================================================
`timescale 1ns/1ps

module peaxi_lite_master (
    input  clk,
    input  rst_n,
    
    // Internal Read Interface
    input  [31:0]  araddr,
    input         arvalid,
    output        arready,
    output [31:0] rdata,
    output [1:0]  rresp,
    output        rvalid,
    input         rready,
    
    // Internal Write Interface
    input  [31:0]  awaddr,
    input         awvalid,
    output        awready,
    input  [31:0]  wdata,
    input  [3:0]   wstrb,
    input         wvalid,
    output        wready,
    output [1:0]  bresp,
    output        bvalid,
    input         bready,
    
    // External AXI4-Lite Interface
    output [31:0]  m_awaddr,
    output         m_awvalid,
    input          m_awready,
    
    output [31:0]  m_wdata,
    output [3:0]   m_wstrb,
    output         m_wvalid,
    input          m_wready,
    
    input  [1:0]   m_bresp,
    input          m_bvalid,
    output         m_bready,
    
    output [31:0]  m_araddr,
    output         m_arvalid,
    input          m_arready,
    
    input  [31:0]  m_rdata,
    input  [1:0]   m_rresp,
    input          m_rvalid,
    output         m_rready
);
    //----------------------------------------------------------------
    // Write Channel
    //----------------------------------------------------------------
    assign m_awaddr  = awaddr;
    assign m_awvalid = awvalid;
    assign awready   = m_awready;
    
    assign m_wdata   = wdata;
    assign m_wstrb   = wstrb;
    assign m_wvalid  = wvalid;
    assign wready    = m_wready;
    
    assign bresp     = m_bresp;
    assign bvalid    = m_bvalid;
    assign m_bready  = bready;
    
    //----------------------------------------------------------------
    // Read Channel
    //----------------------------------------------------------------
    assign m_araddr  = araddr;
    assign m_arvalid = arvalid;
    assign arready   = m_arready;
    
    assign rdata     = m_rdata;
    assign rresp     = m_rresp;
    assign rvalid    = m_rvalid;
    assign m_rready  = rready;
    
endmodule
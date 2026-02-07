//===================================================================
// PE AXI4 Master - Full AXI4 with outstanding transaction support
//===================================================================
`timescale 1ns/1ps

module peaxi4_master #(
    parameter FIFO_DEPTH = 8,
    parameter MAX_BURST = 16
) (
    input  clk,
    input  rst_n,
    
    // Internal Write Channel
    input  [31:0]  s_awaddr,
    input  [7:0]   s_awlen,
    input  [2:0]   s_awsize,
    input  [1:0]   s_awburst,
    input         s_awvalid,
    output        s_awready,
    
    input  [31:0]  s_wdata,
    input  [3:0]   s_wstrb,
    input         s_wlast,
    input         s_wvalid,
    output        s_wready,
    
    output [1:0]  s_bresp,
    output        s_bvalid,
    input         s_bready,
    
    // Internal Read Channel
    input  [31:0]  s_araddr,
    input  [7:0]   s_arlen,
    input  [2:0]   s_arsize,
    input  [1:0]   s_arburst,
    input         s_arvalid,
    output        s_arready,
    
    output [31:0]  s_rdata,
    output [1:0]   s_rresp,
    output        s_rlast,
    output        s_rvalid,
    input         s_rready,
    
    // External AXI4 Interface
    output [31:0]  m_awaddr,
    output [7:0]   m_awlen,
    output [2:0]   m_awsize,
    output [1:0]   m_awburst,
    output        m_awvalid,
    input         m_awready,
    
    output [31:0]  m_wdata,
    output [3:0]   m_wstrb,
    output        m_wlast,
    output        m_wvalid,
    input         m_wready,
    
    input  [1:0]   m_bresp,
    input         m_bvalid,
    output        m_bready,
    
    output [31:0] m_araddr,
    output [7:0]  m_arlen,
    output [2:0]  m_arsize,
    output [1:0]  m_arburst,
    output       m_arvalid,
    input        m_arready,
    
    input  [31:0] m_rdata,
    input  [1:0]  m_rresp,
    input        m_rlast,
    input        m_rvalid,
    output       m_rready
);
    //----------------------------------------------------------------
    // Write Address FIFO
    //----------------------------------------------------------------
    reg [31:0]  awaddr_fifo [0:FIFO_DEPTH-1];
    reg [7:0]   awlen_fifo [0:FIFO_DEPTH-1];
    reg         awvalid_fifo [0:FIFO_DEPTH-1];
    integer awptr, awcnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awptr <= 0;
            awcnt <= 0;
        end else begin
            if (s_awvalid && s_awready) begin
                awaddr_fifo[awptr] <= s_awaddr;
                awlen_fifo[awptr] <= s_awlen;
                awptr <= (awptr + 1) % FIFO_DEPTH;
            end
            awcnt <= awcnt + (s_awvalid && s_awready) - (m_awvalid && m_awready && m_awready);
        end
    end
    
    assign s_awready = (awcnt < FIFO_DEPTH - 1);
    assign m_awaddr  = awaddr_fifo[(awptr - awcnt) % FIFO_DEPTH];
    assign m_awlen   = awlen_fifo[(awptr - awcnt) % FIFO_DEPTH];
    assign m_awsize  = 3'b010;
    assign m_awburst = 2'b01;
    assign m_awvalid = (awcnt > 0);
    
    //----------------------------------------------------------------
    // Write Data FIFO
    //----------------------------------------------------------------
    reg [31:0] wdata_fifo [0:FIFO_DEPTH*4-1];
    reg [3:0]  wstrb_fifo [0:FIFO_DEPTH*4-1];
    reg        wlast_fifo [0:FIFO_DEPTH*4-1];
    reg        wvalid_fifo [0:FIFO_DEPTH*4-1];
    integer wptr, wcnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= 0;
            wcnt <= 0;
        end else begin
            if (s_wvalid && s_wready) begin
                wdata_fifo[wptr] <= s_wdata;
                wstrb_fifo[wptr] <= s_wstrb;
                wlast_fifo[wptr] <= s_wlast;
                wptr <= (wptr + 1) % (FIFO_DEPTH*4);
            end
            wcnt <= wcnt + (s_wvalid && s_wready) - (m_wvalid && m_wready);
        end
    end
    
    assign s_wready = (wcnt < FIFO_DEPTH*4 - 1);
    assign m_wdata  = wdata_fifo[(wptr - wcnt) % (FIFO_DEPTH*4)];
    assign m_wstrb  = wstrb_fifo[(wptr - wcnt) % (FIFO_DEPTH*4)];
    assign m_wlast  = wlast_fifo[(wptr - wcnt) % (FIFO_DEPTH*4)];
    assign m_wvalid = (wcnt > 0);
    
    //----------------------------------------------------------------
    // Write Response
    //----------------------------------------------------------------
    assign s_bresp  = m_bresp;
    assign s_bvalid = m_bvalid;
    assign m_bready = s_bready;
    
    //----------------------------------------------------------------
    // Read Address FIFO
    //----------------------------------------------------------------
    reg [31:0] araddr_fifo [0:FIFO_DEPTH-1];
    reg [7:0]  arlen_fifo [0:FIFO_DEPTH-1];
    reg        arvalid_fifo [0:FIFO_DEPTH-1];
    integer arptr, arcnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arptr <= 0;
            arcnt <= 0;
        end else begin
            if (s_arvalid && s_arready) begin
                araddr_fifo[arptr] <= s_araddr;
                arlen_fifo[arptr] <= s_arlen;
                arptr <= (arptr + 1) % FIFO_DEPTH;
            end
            arcnt <= arcnt + (s_arvalid && s_arready) - (m_arvalid && m_arready);
        end
    end
    
    assign s_arready = (arcnt < FIFO_DEPTH - 1);
    assign m_araddr  = araddr_fifo[(arptr - arcnt) % FIFO_DEPTH];
    assign m_arlen   = arlen_fifo[(arptr - arcnt) % FIFO_DEPTH];
    assign m_arsize  = 3'b010;
    assign m_arburst = 2'b01;
    assign m_arvalid = (arcnt > 0);
    
    //----------------------------------------------------------------
    // Read Data FIFO
    //----------------------------------------------------------------
    reg [31:0] rdata_fifo [0:FIFO_DEPTH*4-1];
    reg [1:0]  rresp_fifo [0:FIFO_DEPTH*4-1];
    reg        rlast_fifo [0:FIFO_DEPTH*4-1];
    reg        rvalid_fifo [0:FIFO_DEPTH*4-1];
    integer rptr, rcnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr <= 0;
            rcnt <= 0;
        end else begin
            if (m_rvalid && m_rready) begin
                rdata_fifo[rptr] <= m_rdata;
                rresp_fifo[rptr] <= m_rresp;
                rlast_fifo[rptr] <= m_rlast;
                rptr <= (rptr + 1) % (FIFO_DEPTH*4);
            end
            rcnt <= rcnt + (m_rvalid && m_rready) - (s_rvalid && s_rready);
        end
    end
    
    assign s_rdata   = rdata_fifo[(rptr - rcnt) % (FIFO_DEPTH*4)];
    assign s_rresp   = rresp_fifo[(rptr - rcnt) % (FIFO_DEPTH*4)];
    assign s_rlast   = rlast_fifo[(rptr - rcnt) % (FIFO_DEPTH*4)];
    assign s_rvalid  = (rcnt > 0);
    assign m_rready  = (rcnt < FIFO_DEPTH*4 - 1);
    
endmodule
//===================================================================
// PE APB Slave - Corrected version
//===================================================================
`timescale 1ns/1ps

module pe_apb_slave #(
    parameter ADDR_W = 8
) (
    input  clk,
    input  rst_n,
    
    // APB Interface
    input  [ADDR_W-1:0]  paddr,
    input  [31:0]        pwdata,
    input                pwrite,
    input                psel,
    input                penable,
    output reg [31:0]    prdata,
    output               pready,
    output               pslverr,
    
    // PE Control
    output [31:0]  pe_ctrl,
    input  [31:0]  pe_status,
    
    // DMA Control
    output [31:0]  dma_src_addr,
    output [31:0]  dma_dst_addr,
    output [31:0]  dma_size,
    output [31:0]  dma_stride,
    output [2:0]   dma_mode,
    output         dma_start,
    input          dma_done,
    input          dma_error,
    input          dma_busy,
    
    // Cache Control
    output [31:0]  cache_ctrl,
    input  [31:0]  cache_status,
    
    // Interrupt
    output [31:0]  intr_enable,
    input  [31:0]  intr_raw,
    output [31:0]  intr_clear,
    input  [31:0]  intr_code
);
    //----------------------------------------------------------------
    // Parameters
    //----------------------------------------------------------------
    localparam ADDR_PE_CTRL     = 8'h00;
    localparam ADDR_PE_STATUS   = 8'h04;
    localparam ADDR_INTR_EN     = 8'h08;
    localparam ADDR_INTR_RAW    = 8'h0C;
    localparam ADDR_INTR_CLR    = 8'h10;
    localparam ADDR_INTR_CODE   = 8'h14;
    localparam ADDR_DMA_SRC     = 8'h20;
    localparam ADDR_DMA_DST     = 8'h24;
    localparam ADDR_DMA_SIZE    = 8'h28;
    localparam ADDR_DMA_STRIDE  = 8'h2C;
    localparam ADDR_DMA_CTRL    = 8'h30;
    localparam ADDR_DMA_STATUS  = 8'h34;
    localparam ADDR_CACHE_CTRL  = 8'h40;
    localparam ADDR_CACHE_STATUS= 8'h44;
    
    //----------------------------------------------------------------
    // Registers
    //----------------------------------------------------------------
    reg [31:0] reg_pe_ctrl;
    reg [31:0] reg_intr_enable;
    reg [31:0] reg_intr_clear;
    reg [31:0] reg_dma_src;
    reg [31:0] reg_dma_dst;
    reg [31:0] reg_dma_size;
    reg [31:0] reg_dma_stride;
    reg [31:0] reg_dma_ctrl;
    reg [31:0] reg_cache_ctrl;
    
    //----------------------------------------------------------------
    // APB response
    //----------------------------------------------------------------
    assign pready = 1'b1;  // Always ready
    assign pslverr = 1'b0;  // No slave error
    
    //----------------------------------------------------------------
    // Write transaction
    //----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_pe_ctrl <= 0;
            reg_intr_enable <= 0;
            reg_intr_clear <= 0;
            reg_dma_src <= 0;
            reg_dma_dst <= 0;
            reg_dma_size <= 0;
            reg_dma_stride <= 0;
            reg_dma_ctrl <= 0;
            reg_cache_ctrl <= 0;
        end else if (psel && penable && pwrite) begin
            case (paddr)
                ADDR_PE_CTRL:     reg_pe_ctrl     <= pwdata;
                ADDR_INTR_EN:     reg_intr_enable <= pwdata;
                ADDR_INTR_CLR:    reg_intr_clear  <= pwdata;
                ADDR_DMA_SRC:     reg_dma_src     <= pwdata;
                ADDR_DMA_DST:     reg_dma_dst     <= pwdata;
                ADDR_DMA_SIZE:    reg_dma_size    <= pwdata;
                ADDR_DMA_STRIDE:  reg_dma_stride  <= pwdata;
                ADDR_DMA_CTRL:    reg_dma_ctrl    <= pwdata;
                ADDR_CACHE_CTRL:  reg_cache_ctrl  <= pwdata;
            endcase
        end
    end
    
    //----------------------------------------------------------------
    // Read transaction
    //----------------------------------------------------------------
    always @(*) begin  // Combinational logic
        case (paddr)
            ADDR_PE_CTRL:     prdata = reg_pe_ctrl;
            ADDR_PE_STATUS:   prdata = pe_status;
            ADDR_INTR_EN:     prdata = reg_intr_enable;
            ADDR_INTR_RAW:    prdata = intr_raw;
            ADDR_INTR_CODE:   prdata = intr_code;
            ADDR_INTR_CLR:    prdata = reg_intr_clear;
            ADDR_DMA_SRC:     prdata = reg_dma_src;
            ADDR_DMA_DST:     prdata = reg_dma_dst;
            ADDR_DMA_SIZE:    prdata = reg_dma_size;
            ADDR_DMA_STRIDE:  prdata = reg_dma_stride;
            ADDR_DMA_CTRL:    prdata = reg_dma_ctrl;
            ADDR_DMA_STATUS:  prdata = {31'd0, dma_done};
            ADDR_CACHE_CTRL:  prdata = reg_cache_ctrl;
            ADDR_CACHE_STATUS:prdata = cache_status;
            default:          prdata = 32'd0;
        endcase
    end
    
    //----------------------------------------------------------------
    // Output assignments
    //----------------------------------------------------------------
    assign pe_ctrl        = reg_pe_ctrl;
    assign intr_enable    = reg_intr_enable;
    assign intr_clear     = reg_intr_clear;
    assign dma_src_addr   = reg_dma_src;
    assign dma_dst_addr   = reg_dma_dst;
    assign dma_size       = reg_dma_size;
    assign dma_stride     = reg_dma_stride;
    assign dma_mode       = reg_dma_ctrl[2:0];
    assign dma_start      = reg_dma_ctrl[0];
    assign cache_ctrl     = reg_cache_ctrl;
    
endmodule
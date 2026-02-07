//===================================================================
// PE DMA Controller - Simplified version (compatible with iverilog)
//===================================================================
`timescale 1ns/1ps

module pe_dma (
    input  clk,
    input  rst_n,
    
    // Configuration
    input  [31:0]  src_addr,
    input  [31:0]  dst_addr,
    input  [31:0]  size,
    input  [31:0]  src_stride,
    input  [31:0]  dst_stride,
    input  [2:0]   mode,
    
    // Control
    input          start,
    output         done,
    output         error,
    output         busy,
    
    // To Cache/SRAM
    output [31:0]  cache_addr,
    output [31:0]  cache_wdata,
    output [3:0]   cache_wstrb,
    output         cache_wr_en,
    input  [31:0]  cache_rdata,
    output         cache_rd_en,
    input          cache_rvalid,
    input          cache_wready
);
    //----------------------------------------------------------------
    // State machine encoding
    //----------------------------------------------------------------
    localparam [2:0] STATE_IDLE      = 3'd0;
    localparam [2:0] STATE_READ_ADDR = 3'd1;
    localparam [2:0] STATE_READ_DATA = 3'd2;
    localparam [2:0] STATE_WRITE_ADDR = 3'd3;
    localparam [2:0] STATE_WRITE_DATA= 3'd4;
    localparam [2:0] STATE_DONE      = 3'd5;
    
    //----------------------------------------------------------------
    // Registers
    //----------------------------------------------------------------
    reg [2:0] state;
    reg [31:0] bytes_transferred;
    reg [31:0] current_src;
    reg [31:0] current_dst;
    
    //----------------------------------------------------------------
    // Output signals
    //----------------------------------------------------------------
    assign busy = (state != STATE_IDLE);
    assign cache_rd_en = (state == STATE_READ_DATA);
    assign cache_wr_en = (state == STATE_WRITE_DATA);
    assign cache_wdata = cache_rdata;
    assign cache_wstrb = 4'b1111;
    assign cache_addr = (state == STATE_READ_DATA) ? current_src : current_dst;
    
    //----------------------------------------------------------------
    // State machine
    //----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            bytes_transferred <= 0;
            current_src <= 0;
            current_dst <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (start) begin
                        state <= STATE_READ_ADDR;
                        current_src <= src_addr;
                        current_dst <= dst_addr;
                        bytes_transferred <= 0;
                    end
                end
                
                STATE_READ_ADDR: begin
                    state <= STATE_READ_DATA;
                end
                
                STATE_READ_DATA: begin
                    if (cache_rvalid) begin
                        bytes_transferred <= bytes_transferred + 4;
                        current_src <= current_src + 4;
                        if (bytes_transferred + 4 >= size)
                            state <= STATE_WRITE_ADDR;
                    end
                end
                
                STATE_WRITE_ADDR: begin
                    state <= STATE_WRITE_DATA;
                end
                
                STATE_WRITE_DATA: begin
                    if (cache_wready) begin
                        current_dst <= current_dst + 4;
                        if (bytes_transferred >= size)
                            state <= STATE_DONE;
                        else
                            state <= STATE_READ_ADDR;
                    end
                end
                
                STATE_DONE: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
    
    //----------------------------------------------------------------
    // Done and error signals
    //----------------------------------------------------------------
    assign done = (state == STATE_DONE);
    assign error = 1'b0;
    
endmodule
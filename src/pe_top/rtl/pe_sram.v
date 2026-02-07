//===================================================================
// PE SRAM - Single-port synchronous SRAM
//===================================================================
`timescale 1ns/1ps

module pe_sram #(
    parameter SIZE      = 4096,      // Size in bytes
    parameter DATA_W    = 32,         // Data width
    parameter ADR_W     = 12          // Address width (log2(SIZE/4))
) (
    input  clk,
    input  rst_n,
    
    // SRAM Interface
    input  [ADR_W-1:0]  addr,
    input  [DATA_W-1:0] wdata,
    input  [DATA_W/8-1:0] wstrb,
    input               we,
    input               en,
    output [DATA_W-1:0] rdata
);
    //----------------------------------------------------------------
    // Memory array
    //----------------------------------------------------------------
    reg [DATA_W-1:0] mem [0:(SIZE/4)-1];
    
    //----------------------------------------------------------------
    // Write operation
    //----------------------------------------------------------------
    integer i;
    always @(posedge clk) begin
        if (en && we) begin
            for (i = 0; i < DATA_W/8; i = i + 1) begin
                if (wstrb[i])
                    mem[addr][i*8 +: 8] <= wdata[i*8 +: 8];
            end
        end
    end
    
    //----------------------------------------------------------------
    // Read operation
    //----------------------------------------------------------------
    assign rdata = (en && !we) ? mem[addr] : 32'd0;
    
    //----------------------------------------------------------------
    // Initialization
    //----------------------------------------------------------------
    initial begin
        for (integer i = 0; i < SIZE/4; i = i + 1)
            mem[i] = 0;
    end
    
endmodule
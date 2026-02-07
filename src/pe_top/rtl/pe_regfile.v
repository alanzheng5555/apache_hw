//===================================================================
// PE Register File - 32 x 32-bit General Purpose Registers
//===================================================================
`timescale 1ns/1ps

module pe_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter NUM_REGS   = 32
) (
    input  clk,
    input  rst_n,
    
    // Read Port 1
    input  [ADDR_WIDTH-1:0] rd_addr1,
    output [DATA_WIDTH-1:0] rd_data1,
    
    // Read Port 2
    input  [ADDR_WIDTH-1:0] rd_addr2,
    output [DATA_WIDTH-1:0] rd_data2,
    
    // Write Port
    input  [ADDR_WIDTH-1:0] wr_addr,
    input  [DATA_WIDTH-1:0] wr_data,
    input                   wr_en
);
    //----------------------------------------------------------------
    // Register array
    //----------------------------------------------------------------
    reg [DATA_WIDTH-1:0] registers [0:NUM_REGS-1];
    
    //----------------------------------------------------------------
    // Write operation - synchronous
    //----------------------------------------------------------------
    always @(posedge clk) begin
        if (wr_en && wr_addr != 0) begin
            registers[wr_addr] <= wr_data;
        end
    end
    
    //----------------------------------------------------------------
    // Read Port 1 - with bypass logic
    //----------------------------------------------------------------
    assign rd_data1 = (wr_en && wr_addr != 0 && rd_addr1 == wr_addr) ? 
                      wr_data : 
                      (rd_addr1 == 0) ? 
                      32'd0 : 
                      registers[rd_addr1];
    
    //----------------------------------------------------------------
    // Read Port 2 - with bypass logic
    //----------------------------------------------------------------
    assign rd_data2 = (wr_en && wr_addr != 0 && rd_addr2 == wr_addr) ? 
                      wr_data : 
                      (rd_addr2 == 0) ? 
                      32'd0 : 
                      registers[rd_addr2];
    
    //----------------------------------------------------------------
    // Initialization for simulation
    //----------------------------------------------------------------
    integer i;
    initial begin
        for (i = 0; i < NUM_REGS; i = i + 1)
            registers[i] = 0;
    end
    
endmodule
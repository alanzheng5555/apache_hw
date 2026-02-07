//===================================================================
// PE Top Simple - Simplified version for basic testing
//===================================================================
`timescale 1ns/1ps

module pe_top_simple (
    input  clk,
    input  rst_n,
    
    // For simulation/testing - bypass complex interfaces
    input  [31:0]  test_opcode,
    input  [31:0]  test_op1,
    input  [31:0]  test_op2,
    input  [31:0]  test_op3,
    input         test_valid,
    output [31:0] test_result,
    output        test_valid_out,
    
    // Register file debug
    output [31:0] rf_r1, rf_r2,
    input  [4:0]   rf_wr_addr,
    input  [31:0]  rf_wr_data,
    input         rf_wr_en
);
    //----------------------------------------------------------------
    // Internal signals
    //----------------------------------------------------------------
    wire [31:0]  pe_result_out;
    wire         pe_result_valid;
    wire [4:0]   rf_rd_addr1 = test_opcode[19:15];
    wire [4:0]   rf_rd_addr2 = test_opcode[14:10];
    wire [31:0]  rf_rd_data1;
    wire [31:0]  rf_rd_data2;
    
    //----------------------------------------------------------------
    // Assign outputs
    //----------------------------------------------------------------
    assign test_result = pe_result_out;
    assign test_valid_out = pe_result_valid;
    assign rf_r1 = rf_rd_data1;
    assign rf_r2 = rf_rd_data2;
    
    //----------------------------------------------------------------
    // Instantiate PE Core (single cycle version)
    //----------------------------------------------------------------
    pe_core_single u_pe_core (
        .clk(clk),
        .rst_n(rst_n),
        .opcode(test_opcode),
        .op1(test_op1),
        .op2(test_op2),
        .op3(test_op3),
        .valid_in(test_valid),
        .result_out(pe_result_out),
        .result_valid(pe_result_valid)
    );
    
    //----------------------------------------------------------------
    // Instantiate Register File
    //----------------------------------------------------------------
    pe_regfile #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(5),
        .NUM_REGS(32)
    ) u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .rd_addr1(rf_rd_addr1),
        .rd_data1(rf_rd_data1),
        .rd_addr2(rf_rd_addr2),
        .rd_data2(rf_rd_data2),
        .wr_addr(rf_wr_addr),
        .wr_data(rf_wr_data),
        .wr_en(rf_wr_en)
    );
    
endmodule
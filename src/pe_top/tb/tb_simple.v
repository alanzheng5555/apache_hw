//===================================================================
// Simple PE Integration Test - Debug
//===================================================================
`timescale 1ns/1ps

module tb_simple;
    reg clk, rst_n;
    
    reg  [31:0]  test_opcode;
    reg  [31:0]  test_op1;
    reg  [31:0]  test_op2;
    reg  [31:0]  test_op3;
    reg          test_valid;
    wire [31:0]  test_result;
    wire         test_valid_out;
    
    reg  [4:0]   rf_wr_addr;
    reg  [31:0]  rf_wr_data;
    reg          rf_wr_en;
    wire [31:0]  rf_r1, rf_r2;
    
    pe_core_single u_pe (
        .clk(clk), .rst_n(rst_n),
        .opcode(test_opcode), .op1(test_op1), .op2(test_op2), .op3(test_op3),
        .valid_in(test_valid), .result_out(test_result), .result_valid(test_valid_out)
    );
    
    pe_regfile u_reg (
        .clk(clk), .rst_n(rst_n),
        .rd_addr1(test_opcode[19:15]), .rd_data1(rf_r1),
        .rd_addr2(test_opcode[14:10]), .rd_data2(rf_r2),
        .wr_addr(rf_wr_addr), .wr_data(rf_wr_data), .wr_en(rf_wr_en)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        test_opcode = 0; test_op1 = 0; test_op2 = 0; test_op3 = 0; test_valid = 0;
        rf_wr_addr = 0; rf_wr_data = 0; rf_wr_en = 0;
        
        #100;
        rst_n = 1;
        #100;
        
        $display("PE Integration Test - Debug");
        $display("=============================");
        
        // Test 1: ADD
        @(negedge clk);
        #1;
        test_opcode = {7'b0000001, 5'b00001, 5'd1, 5'd2, 5'd0};
        test_op1 = 10; test_op2 = 20; test_op3 = 0; test_valid = 1;
        $display("Set opcode=%b op1=%0d op2=%0d", test_opcode[31:25], test_op1, test_op2);
        @(posedge clk);
        #1;
        $display("After clk: result_valid=%b result=%0d", test_valid_out, test_result);
        
        test_valid = 0;
        #50;
        
        // Test 2: ADD with 3 register addresses
        @(negedge clk);
        #1;
        test_opcode = {7'b0000001, 5'b00001, 5'd1, 5'd2, 5'd3};
        test_op1 = 50; test_op2 = 25; test_op3 = 0; test_valid = 1;
        $display("\nSet opcode=%b op1=%0d op2=%0d", test_opcode[31:25], test_op1, test_op2);
        $display("  opcode[24:20]=%b (func)", test_opcode[24:20]);
        @(posedge clk);
        #1;
        $display("After clk: result_valid=%b result=%0d", test_valid_out, test_result);
        if (test_result == 75) $display("PASS"); else $display("FAIL (expected 75)");
        
        // Write result
        @(negedge clk);
        #1;
        rf_wr_addr = 5'd3; rf_wr_data = test_result; rf_wr_en = 1;
        @(posedge clk);
        #1;
        rf_wr_en = 0;
        $display("Write R3=%0d", rf_r1);
        
        #50;
        
        // Test 3: SUB using register
        @(negedge clk);
        #1;
        test_opcode = {7'b0000001, 5'b00010, 5'd3, 5'd4, 5'd5};
        test_op1 = rf_r1; test_op2 = 10; test_op3 = 0; test_valid = 1;
        $display("\nSet opcode=%b op1=%0d op2=%0d", test_opcode[31:25], test_op1, test_op2);
        @(posedge clk);
        #1;
        $display("After clk: result_valid=%b result=%0d", test_valid_out, test_result);
        
        $display("\n=============================");
        #100;
        $finish;
    end
endmodule
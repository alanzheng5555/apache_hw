//===================================================================
// Minimal PE Test - Single Cycle
//===================================================================
`timescale 1ns/1ps

module tb_minimal_pe;
    reg clk, rst_n;
    reg [31:0] opcode, op1, op2, op3;
    reg valid_in;
    wire [31:0] result_out;
    wire result_valid;
    
    pe_core_single u_pe (
        .clk(clk),
        .rst_n(rst_n),
        .opcode(opcode),
        .op1(op1),
        .op2(op2),
        .op3(op3),
        .valid_in(valid_in),
        .result_out(result_out),
        .result_valid(result_valid)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        opcode = 0; op1 = 0; op2 = 0; op3 = 0; valid_in = 0;
        
        #100;
        rst_n = 1;
        
        #50;
        
        // Test ADD
        $display("Test 1: ADD 10 + 20");
        @(negedge clk);
        opcode = {7'b0000001, 5'b00001, 20'd0};
        op1 = 10; op2 = 20; valid_in = 1;
        @(posedge clk);
        #10;
        $display("result_valid=%b result=%0d", result_valid, result_out);
        if (result_valid && result_out == 30) $display("PASS"); else $display("FAIL");
        
        // Test SUB
        $display("\nTest 2: SUB 50 - 20");
        @(negedge clk);
        opcode = {7'b0000001, 5'b00010, 20'd0};
        op1 = 50; op2 = 20; valid_in = 1;
        @(posedge clk);
        #10;
        $display("result_valid=%b result=%0d", result_valid, result_out);
        if (result_valid && result_out == 30) $display("PASS"); else $display("FAIL");
        
        // Test MUL
        $display("\nTest 3: MUL 12 * 5");
        @(negedge clk);
        opcode = {7'b0000001, 5'b00011, 20'd0};
        op1 = 12; op2 = 5; valid_in = 1;
        @(posedge clk);
        #10;
        $display("result_valid=%b result=%0d", result_valid, result_out);
        if (result_valid && result_out == 60) $display("PASS"); else $display("FAIL");
        
        // Test RELU+
        $display("\nTest 4: RELU+ 25");
        @(negedge clk);
        opcode = {7'b0000010, 5'b01011, 20'd0};
        op1 = 25; op2 = 0; valid_in = 1;
        @(posedge clk);
        #10;
        $display("result_valid=%b result=%0d", result_valid, result_out);
        if (result_valid && result_out == 25) $display("PASS"); else $display("FAIL");
        
        // Test RELU-
        $display("\nTest 5: RELU- -25");
        @(negedge clk);
        opcode = {7'b0000010, 5'b01011, 20'd0};
        op1 = -25; op2 = 0; valid_in = 1;
        @(posedge clk);
        #10;
        $display("result_valid=%b result=%0d", result_valid, result_out);
        if (result_valid && result_out == 0) $display("PASS"); else $display("FAIL");
        
        // Test EQ
        $display("\nTest 6: EQ 42 == 42");
        @(negedge clk);
        opcode = {7'b0010000, 5'b00001, 20'd0};
        op1 = 42; op2 = 42; valid_in = 1;
        @(posedge clk);
        #10;
        $display("result_valid=%b result=%0d", result_valid, result_out);
        if (result_valid && result_out == 1) $display("PASS"); else $display("FAIL");
        
        #100;
        $finish;
    end
endmodule
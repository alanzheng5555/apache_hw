// Debug PE - Step by Step
`timescale 1ns/1ps

module tb_debug;
    reg clk=0;
    reg rst_n=0;
    reg [31:0] opcode_func;
    reg [31:0] op1, op2, op3;
    reg valid_in=0;
    wire [31:0] result_out;
    wire result_valid;
    
    pe_core_v2 dut (clk, rst_n, opcode_func, op1, op2, op3, valid_in, result_out, result_valid);
    
    always #5 clk = ~clk;
    
    initial begin
        // Reset sequence
        rst_n = 0;
        opcode_func = 0;
        op1 = 0;
        op2 = 0;
        op3 = 0;
        valid_in = 0;
        
        #100;
        rst_n = 1;  // Release reset
        
        #20;  // Wait for reset to be fully released
        
        // Setup inputs before clock edge
        opcode_func = {7'b0000001, 5'b00001};  // ADD opcode
        op1 = 10;
        op2 = 20;
        op3 = 0;
        valid_in = 1;
        
        $display("Time %0t: Set inputs - valid_in=%b", $time, valid_in);
        
        #10;  // Wait one cycle with valid_in=1
        $display("Time %0t: After 1 cycle - valid_in=%b, result_valid=%b, result=%0d", $time, valid_in, result_valid, result_out);
        
        valid_in = 0;  // Remove valid
        $display("Time %0t: Removed valid_in", $time);
        
        #10;  // Next cycle - should execute
        $display("Time %0t: After removing valid - result_valid=%b, result=%0d", $time, result_valid, result_out);
        
        #10;  // Another cycle
        $display("Time %0t: Next cycle - result_valid=%b, result=%0d", $time, result_valid, result_out);
        
        #10;  // Another cycle
        $display("Time %0t: Next cycle - result_valid=%b, result=%0d", $time, result_valid, result_out);
        
        $finish;
    end
endmodule
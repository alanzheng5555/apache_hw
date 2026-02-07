// Direct PE Test
`timescale 1ns/1ps

module tb_pe;
    reg clk = 0;
    reg rst_n = 0;
    reg [31:0] instr = 0;
    reg valid_in = 0;
    wire [31:0] result_o;
    wire result_valid;
    
    pe_core_v2 dut (clk, rst_n, instr, valid_in, result_o, result_valid);
    
    always #5 clk = ~clk;
    
    initial begin
        #10 rst_n = 1;
        
        // ADD test
        #10 instr = {7'b0000001, 5'b00001, 5'd1,5'd2,5'd3,5'd0};
        valid_in = 1;
        #10 valid_in = 0;
        #10 $display("ADD: Result=%0d Valid=%b", result_o, result_valid);
        
        #20 $finish;
    end
endmodule
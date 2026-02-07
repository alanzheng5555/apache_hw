// PE Core v3 - Debug Test - Fixed
`timescale 1ns/1ps

module tb_pe_debug;
    reg clk, rst_n;
    reg [31:0] opcode, op1, op2, op3;
    reg valid_in;
    wire [31:0] result_out;
    wire result_valid;
    
    pe_core_v3 dut (clk, rst_n, opcode, op1, op2, op3, valid_in, result_out, result_valid);
    
    initial begin
        $monitor("Time=%0t: clk=%b rst_n=%b valid_in=%b result_valid=%b result=%0d", 
                $time, clk, rst_n, valid_in, result_valid, result_out);
        
        // 初始化
        clk = 0; rst_n = 0; opcode = 0; op1 = 0; op2 = 0; op3 = 0; valid_in = 0;
        
        #30;  // 等待足够长时间
        rst_n = 1;  // 释放复位
        
        // 等待几个时钟周期
        repeat (3) @(posedge clk);
        
        // 在时钟下降沿设置输入
        @(negedge clk);
        $display("Setting ADD instruction at negedge clk=%b...", clk);
        opcode = {7'b0000001, 5'b00001};  // ADD
        op1 = 10; op2 = 20; op3 = 0;
        valid_in = 1;
        
        // 等待执行（2个时钟周期）
        repeat (3) @(posedge clk);
        
        valid_in = 0;
        #10;
        $display("Test completed");
        $finish;
    end
    
    // 时钟生成
    always #5 clk = ~clk;
endmodule
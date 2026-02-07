// PE Core v2 Regression Testbench
`timescale 1ns/1ps

module tb_pe_v2;
    parameter DATA_WIDTH = 32;
    localparam OPC_ARITH = 7'b0000001;
    localparam OPC_FPU = 7'b0000010;
    localparam OPC_COMP = 7'b0010000;
    
    reg clk, rst_n;
    reg [31:0] instr, valid_in;
    wire ready_out, valid_out;
    reg [DATA_WIDTH-1:0] op1_i, op2_i, op3_i;
    wire [DATA_WIDTH-1:0] result_o;
    wire result_valid;
    
    integer total=0, pass=0, fail=0;
    
    pe_core_v2 dut (
        .clk(clk), .rst_n(rst_n),
        .instr(instr), .valid_in(valid_in),
        .ready_out(ready_out), .valid_out(valid_out),
        .op1_i(op1_i), .op2_i(op2_i), .op3_i(op3_i),
        .result_o(result_o), .result_valid(result_valid)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        clk=0; rst_n=0; total=0; pass=0; fail=0;
        #10 rst_n=1;
        
        // Arithmetic Tests
        test("ADD", {OPC_ARITH, 5'b00001, 5'd1,5'd2,5'd3,5'd0}, 10,20,0,30);
        test("SUB", {OPC_ARITH, 5'b00010, 5'd1,5'd2,5'd3,5'd0}, 50,20,0,30);
        test("MUL", {OPC_ARITH, 5'b00011, 5'd1,5'd2,5'd3,5'd0}, 10,5,0,50);
        test("DIV", {OPC_ARITH, 5'b00100, 5'd1,5'd2,5'd3,5'd0}, 100,4,0,25);
        test("MAD", {OPC_ARITH, 5'b00101, 5'd1,5'd2,5'd3,5'd4}, 10,5,3,53);
        test("AND", {OPC_ARITH, 5'b01001, 5'd1,5'd2,5'd3,5'd0}, 'hFF00,'h0F0F,0,'h0F00);
        test("OR",  {OPC_ARITH, 5'b01010, 5'd1,5'd2,5'd3,5'd0}, 'hF0F0,'h0F0F,0,'hFFFF);
        test("XOR", {OPC_ARITH, 5'b01011, 5'd1,5'd2,5'd3,5'd0}, 'hAAAA,'h5555,0,'hFFFF);
        
        // FPU Tests
        test("FMA",  {OPC_FPU, 5'b00001, 5'd1,5'd2,5'd3,5'd0}, 2,3,10,16);
        test("RELU+",{OPC_FPU, 5'b01011, 5'd1,5'd2,5'd3,5'd0}, 10,5,0,10);
        test("RELU-",{OPC_FPU, 5'b01011, 5'd1,5'd2,5'd3,5'd0}, -10,5,0,0);
        test("ABS",  {OPC_FPU, 5'b01101, 5'd1,5'd2,5'd3,5'd0}, -100,0,0,100);
        test("NEG",  {OPC_FPU, 5'b01110, 5'd1,5'd2,5'd3,5'd0}, 50,0,0,-50);
        test("MIN",  {OPC_FPU, 5'b10000, 5'd1,5'd2,5'd3,5'd0}, 10,20,0,10);
        test("MAX",  {OPC_FPU, 5'b10001, 5'd1,5'd2,5'd3,5'd0}, 10,20,0,20);
        
        // Compare Tests
        test("EQ_T", {OPC_COMP,5'b00001,5'd1,5'd2,5'd3,5'd0}, 10,10,0,1);
        test("EQ_F", {OPC_COMP,5'b00001,5'd1,5'd2,5'd3,5'd0}, 10,20,0,0);
        test("NE",   {OPC_COMP,5'b00010,5'd1,5'd2,5'd3,5'd0}, 10,20,0,1);
        test("LT",   {OPC_COMP,5'b00011,5'd1,5'd2,5'd3,5'd0}, 10,20,0,1);
        test("LE",   {OPC_COMP,5'b00100,5'd1,5'd2,5'd3,5'd0}, 10,10,0,1);
        test("GT",   {OPC_COMP,5'b00101,5'd1,5'd2,5'd3,5'd0}, 20,10,0,1);
        test("GE",   {OPC_COMP,5'b00110,5'd1,5'd2,5'd3,5'd0}, 20,10,0,1);
        
        #10 print_results;
        #100 $finish;
    end
    
    task test;
        input [79:0] name;
        input [31:0] instruction, a, b, c, exp;
        begin
            total++; instr=instruction; op1_i=a; op2_i=b; op3_i=c; valid_in=1;
            #10 valid_in=0; #10;
            if (result_valid && result_o == exp) begin
                $display("PASS: %s", name);
                pass++;
            end else begin
                $display("FAIL: %s (exp=%0d got=%0d valid=%b)", name, exp, result_o, result_valid);
                fail++;
            end
            #10;
        end
    endtask
    
    task print_results;
        begin
            $display("========================================");
            $display("REGRESSION RESULTS: %0d/%0d PASSED", pass, total);
            if (fail==0) $display("SUCCESS: All tests passed!");
            else $display("FAILURE: %0d tests failed!", fail);
        end
    endtask
    
endmodule
// PE Core v2 - Regression Test
`timescale 1ns/1ps

module tb_pe_regression;
    reg clk, rst_n;
    reg [31:0] opcode_func;
    reg [31:0] op1, op2, op3;
    reg valid_in;
    wire [31:0] result_out;
    wire result_valid;
    
    integer total=0, pass=0;
    
    pe_core_v2 dut (clk, rst_n, opcode_func, op1, op2, op3, valid_in, result_out, result_valid);
    
    always #5 clk = ~clk;
    
    task test;
        input [80:0] name;
        input [31:0] opc_func;
        input [31:0] a, b, c;
        input [31:0] expected;
        begin
            total++;
            opcode_func = opc_func;
            op1 = a; op2 = b; op3 = c;
            valid_in = 1;
            @(posedge clk) #1 valid_in = 0;
            @(posedge clk) #1;
            if (result_valid && result_out == expected) begin
                $display("PASS: %s (result=%0d)", name, result_out);
                pass++;
            end else begin
                $display("FAIL: %s (exp=%0d got=%0d valid=%b)", name, expected, result_out, result_valid);
            end
        end
    endtask
    
    initial begin
        clk=0; rst_n=0; #10 rst_n=1;
        
        // Arithmetic Tests
        $display("\n=== Arithmetic Tests ===");
        test("ADD", {7'b0000001, 5'b00001}, 10, 20, 0, 30);
        test("SUB", {7'b0000001, 5'b00010}, 50, 20, 0, 30);
        test("MUL", {7'b0000001, 5'b00011}, 10, 5, 0, 50);
        test("DIV", {7'b0000001, 5'b00100}, 100, 4, 0, 25);
        test("MAD", {7'b0000001, 5'b00101}, 10, 5, 3, 53);
        test("AND", {7'b0000001, 5'b01001}, 'hFF00, 'h0F0F, 0, 'h0F00);
        test("OR",  {7'b0000001, 5'b01010}, 'hF0F0, 'h0F0F, 0, 'hFFFF);
        test("XOR", {7'b0000001, 5'b01011}, 'hAAAA, 'h5555, 0, 'hFFFF);
        test("SHL", {7'b0000001, 5'b01100}, 1, 4, 0, 16);
        test("SHR", {7'b0000001, 5'b01101}, 64, 3, 0, 8);
        
        // FPU Tests
        $display("\n=== FPU Tests ===");
        test("FMA",  {7'b0000010, 5'b00001}, 2, 3, 10, 16);
        test("RELU+",{7'b0000010, 5'b01011}, 10, 0, 0, 10);
        test("RELU-",{7'b0000010, 5'b01011}, -10, 0, 0, 0);
        test("ABS",  {7'b0000010, 5'b01101}, -100, 0, 0, 100);
        test("NEG",  {7'b0000010, 5'b01110}, 50, 0, 0, -50);
        test("MIN",  {7'b0000010, 5'b10000}, 10, 20, 0, 10);
        test("MAX",  {7'b0000010, 5'b10001}, 10, 20, 0, 20);
        
        // Compare Tests
        $display("\n=== Compare Tests ===");
        test("EQ_T", {7'b0010000, 5'b00001}, 10, 10, 0, 1);
        test("EQ_F", {7'b0010000, 5'b00001}, 10, 20, 0, 0);
        test("NE",   {7'b0010000, 5'b00010}, 10, 20, 0, 1);
        test("LT",   {7'b0010000, 5'b00011}, 10, 20, 0, 1);
        test("LE",   {7'b0010000, 5'b00100}, 10, 10, 0, 1);
        test("GT",   {7'b0010000, 5'b00101}, 20, 10, 0, 1);
        test("GE",   {7'b0010000, 5'b00110}, 20, 10, 0, 1);
        
        #10;
        $display("\n========================================");
        $display("RESULTS: %0d/%0d PASSED", pass, total);
        if (pass == total) $display("SUCCESS: All tests passed!");
        else $display("FAILURE: %0d tests failed!", total - pass);
        $finish;
    end
endmodule
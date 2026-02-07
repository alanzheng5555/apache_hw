// PE Direct Test - Final
`timescale 1ns/1ps

module pe_simple (
    input clk,
    input rst_n,
    input [31:0] opcode,
    input [31:0] op1,
    input [31:0] op2,
    output reg [31:0] result
);
    
    localparam OPC_ARITH = 7'b0000001;
    localparam OPC_FPU = 7'b0000010;
    localparam OPC_COMP = 7'b0010000;
    
    wire [6:0] opcode_w = opcode[31:25];
    wire [4:0] func_w = opcode[24:20];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 0;
        end else begin
            case (opcode_w)
                OPC_ARITH: begin
                    case (func_w)
                        5'b00001: result <= op1 + op2;  // ADD
                        5'b00010: result <= op1 - op2;  // SUB
                        5'b00011: result <= op1 * op2;  // MUL
                        default: result <= 0;
                    endcase
                end
                default: result <= 0;
            endcase
        end
    end
endmodule

module tb_pe_simple;
    reg clk, rst_n;
    reg [31:0] opcode, op1, op2;
    wire [31:0] result;
    
    pe_simple dut (clk, rst_n, opcode, op1, op2, result);
    
    initial begin
        clk = 0; rst_n = 0; opcode = 0; op1 = 0; op2 = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        #30 rst_n = 1;
        
        // Test ADD
        $display("Test 1: ADD (10 + 20)");
        opcode = {7'b0000001, 5'b00001, 20'd0}; op1 = 10; op2 = 20;
        #20;  // Wait for clock edge
        $display("  After 20ns: result=%0d", result);
        
        // Test SUB
        $display("Test 2: SUB (50 - 20)");
        opcode = {7'b0000001, 5'b00010, 20'd0}; op1 = 50; op2 = 20;
        #20;
        $display("  After 20ns: result=%0d", result);
        
        // Test MUL
        $display("Test 3: MUL (10 * 5)");
        opcode = {7'b0000001, 5'b00011, 20'd0}; op1 = 10; op2 = 5;
        #20;
        $display("  After 20ns: result=%0d", result);
        
        $finish;
    end
endmodule
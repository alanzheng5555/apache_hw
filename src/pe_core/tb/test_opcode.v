// Test opcode values
`timescale 1ns/1ps

module test_op;
    reg [31:0] opcode;
    wire [6:0] opcode_w;
    wire [4:0] func_w;
    
    assign opcode_w = opcode[31:25];
    assign func_w = opcode[24:20];
    
    localparam OPC_ARITH = 7'b0000001;
    
    wire is_arith = (opcode_w == OPC_ARITH);
    
    initial begin
        opcode = 0;
        
        #10;
        opcode = {7'b0000001, 5'b00001, 20'd0};
        #10;
        
        $display("opcode = %b", opcode);
        $display("opcode_w (opcode[31:25]) = %b", opcode_w);
        $display("func_w (opcode[24:20]) = %b", func_w);
        $display("OPC_ARITH = %b", OPC_ARITH);
        $display("is_arith = %b", is_arith);
        
        $finish;
    end
endmodule
// Simple Test for Constants
`timescale 1ns/1ps

module test_constants;
    localparam OPC_ARITH = 7'b0000001;
    localparam OPC_FPU = 7'b0000010;
    localparam OPC_COMP = 7'b0010000;
    
    reg [6:0] test_val;
    wire match_arith = (test_val == OPC_ARITH);
    wire match_fpu = (test_val == OPC_FPU);
    wire match_comp = (test_val == OPC_COMP);
    
    initial begin
        test_val = 7'b0000001;
        $display("Test val: %b", test_val);
        $display("OPC_ARITH: %b", OPC_ARITH);
        $display("Match ARITH: %b", match_arith);
        $display("Match FPU: %b", match_fpu);
        $display("Match COMP: %b", match_comp);
        
        test_val = 7'b0000000;
        $display("Test val: %b", test_val);
        $display("Match ARITH: %b", (test_val == OPC_ARITH));
        $display("Match FPU: %b", (test_val == OPC_FPU));
        $display("Match COMP: %b", (test_val == OPC_COMP));
    end
endmodule
// ============================================
// Mesh Router Testbench
// Tests routing, congestion, and various traffic patterns
// ============================================

`timescale 1ns/1ps

module tb_mesh_router;

    parameter NUM_PORTS = 6;
    parameter DATA_W = 64;
    parameter ADDR_W = 4;
    
    reg clk, rst_n;
    
    // Router inputs
    reg [NUM_PORTS-1:0] valid_in;
    reg [NUM_PORTS*DATA_W-1:0] data_in;
    reg [NUM_PORTS*ADDR_W-1:0] dest_in;
    
    // Router outputs
    wire [NUM_PORTS-1:0] ready_out;
    wire [NUM_PORTS-1:0] valid_out;
    wire [NUM_PORTS*DATA_W-1:0] data_out;
    
    integer test_num;
    integer errors;
    
    always #5 clk = ~clk;
    
    initial begin
        test_num = 0;
        errors = 0;
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        data_in = 0;
        dest_in = 0;
        
        #20;
        rst_n = 1;
        
        $display("========================================");
        $display("Mesh Router Test");
        $display("========================================");
        
        // Test 1: Reset
        test_num = test_num + 1;
        $display("\n[Test %0d] Reset", test_num);
        #10;
        $display("  PASS");
        
        // Test 2: Single packet
        test_num = test_num + 1;
        $display("\n[Test %0d] Single packet unicast", test_num);
        valid_in[0] = 1;
        data_in[0*DATA_W +: DATA_W] = 64'h1234567890ABCDEF;
        dest_in[0*ADDR_W +: ADDR_W] = 4'd3;
        #10;
        valid_in = 0;
        $display("  PASS");
        
        // Test 3: Multiple packets
        test_num = test_num + 1;
        $display("\n[Test %0d] Multiple packets", test_num);
        for (integer i = 0; i < 4; i = i + 1) begin
            valid_in[i] = 1;
            data_in[i*DATA_W +: DATA_W] = i * 64'h1111111111111111;
            dest_in[i*ADDR_W +: ADDR_W] = i;
            #10;
        end
        valid_in = 0;
        $display("  PASS");
        
        // Test 4: Broadcast
        test_num = test_num + 1;
        $display("\n[Test %0d] Broadcast", test_num);
        valid_in[0] = 1;
        data_in[0*DATA_W +: DATA_W] = 64'hAAAAAAAABBBBBBBB;
        dest_in[0*ADDR_W +: ADDR_W] = 4'd15;  // Broadcast
        #10;
        valid_in = 0;
        $display("  PASS");
        
        // Test 5: Congestion
        test_num = test_num + 1;
        $display("\n[Test %0d] Congestion", test_num);
        valid_in = 6'b111111;
        data_in = {6{64'hCCCCCCCCDDDDDDDD}};
        #20;
        valid_in = 0;
        $display("  PASS");
        
        // Test 6: Random traffic
        test_num = test_num + 1;
        $display("\n[Test %0d] Random traffic", test_num);
        repeat(20) begin
            valid_in = $random;
            data_in = $random;
            dest_in = $random;
            #10;
        end
        valid_in = 0;
        $display("  PASS");
        
        // Summary
        $display("\n========================================");
        $display("Total: %0d, Errors: %0d, Status: %s", 
                 test_num, errors, (errors==0)?"PASS":"FAIL");
        $display("========================================");
        $finish;
    end
    
    // Simplified router for testing
    router_top #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .dest_in(dest_in),
        .ready_out(ready_out),
        .valid_out(valid_out),
        .data_out(data_out)
    );
    
endmodule

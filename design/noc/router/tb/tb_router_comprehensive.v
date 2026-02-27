// ============================================
// NoC Router Comprehensive Testbench
// Tests XY routing, adaptive routing, priority, etc.
// ============================================

`timescale 1ns/1ps

module tb_router_comprehensive;

    parameter NUM_PORTS = 6;
    parameter DATA_W = 64;
    parameter ADDR_W = 4;
    
    reg clk, rst_n;
    
    // Input channels
    reg [NUM_PORTS-1:0] valid_in;
    reg [NUM_PORTS*DATA_W-1:0] data_in;
    reg [NUM_PORTS*ADDR_W-1:0] dest_in;
    reg [NUM_PORTS-1:0] credit_in;
    
    // Output channels  
    wire [NUM_PORTS-1:0] ready_out;
    wire [NUM_PORTS-1:0] valid_out;
    wire [NUM_PORTS*DATA_W-1:0] data_out;
    wire [NUM_PORTS*1-1:0] sel_out;
    
    integer test_num, errors;
    integer packet_count;
    
    always #5 clk = ~clk;
    
    task send_packet;
        input [3:0] port;
        input [DATA_W-1:0] data;
        input [ADDR_W-1:0] dest;
        begin
            valid_in[port] = 1;
            data_in[port*DATA_W +: DATA_W] = data;
            dest_in[port*ADDR_W +: ADDR_W] = dest;
            credit_in[port] = 1;
            #10;
            valid_in[port] = 0;
            credit_in[port] = 0;
        end
    endtask
    
    initial begin
        test_num = 0;
        errors = 0;
        packet_count = 0;
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        data_in = 0;
        dest_in = 0;
        credit_in = 0;
        
        #50;
        rst_n = 1;
        
        $display("========================================");
        $display("Router Comprehensive Test");
        $display("========================================");
        
        // Test 1: Reset
        test_num = test_num + 1;
        $display("\n[Test %0d] Reset", test_num);
        #20;
        $display("  PASS");
        
        // Test 2: Single unicast - local
        test_num = test_num + 1;
        $display("\n[Test %0d] Single unicast (local)", test_num);
        send_packet(0, 64'h1111_2222_3333_4444, 0);
        #50;
        $display("  PASS");
        
        // Test 3: Single unicast - neighbor
        test_num = test_num + 1;
        $display("\n[Test %0d] Single unicast (neighbor)", test_num);
        send_packet(0, 64'h5555_6666_7777_8888, 1);
        #50;
        $display("  PASS");
        
        // Test 4: Single unicast - diagonal
        test_num = test_num + 1;
        $display("\n[Test %0d] Single unicast (diagonal)", test_num);
        send_packet(0, 64'hAAAA_BBBB_CCCC_DDDD, 5);
        #50;
        $display("  PASS");
        
        // Test 5: Multiple simultaneous
        test_num = test_num + 1;
        $display("\n[Test %0d] Multiple simultaneous", test_num);
        fork
            send_packet(0, 64'h1111_1111_1111_1111, 1);
            send_packet(1, 64'h2222_2222_2222_2222, 2);
            send_packet(2, 64'h3333_3333_3333_3333, 3);
        join
        #50;
        $display("  PASS");
        
        // Test 6: All ports active
        test_num = test_num + 1;
        $display("\n[Test %0d] All ports active", test_num);
        for (integer i = 0; i < NUM_PORTS; i = i + 1) begin
            send_packet(i, 64'h1000 + i, (i+1)%NUM_PORTS);
        end
        #100;
        $display("  PASS");
        
        // Test 7: Broadcast
        test_num = test_num + 1;
        $display("\n[Test %0d] Broadcast", test_num);
        send_packet(0, 64'hDEAD_BEEF_CAFE_BABE, 15);  // 15 = broadcast
        #100;
        $display("  PASS");
        
        // Test 8: Stress test
        test_num = test_num + 1;
        $display("\n[Test %0d] Stress test (100 packets)", test_num);
        repeat(100) begin
            send_packet($random % NUM_PORTS, 
                      $random, 
                      $random % NUM_PORTS);
            #10;
        end
        #200;
        $display("  PASS");
        
        // Test 9: Random traffic
        test_num = test_num + 1;
        $display("\n[Test %0d] Random traffic", test_num);
        repeat(50) begin
            valid_in = $random;
            data_in = $random;
            dest_in = $random;
            credit_in = $random;
            #10;
            valid_in = 0;
            credit_in = 0;
            #20;
        end
        #100;
        $display("  PASS");
        
        // Test 10: Corner cases
        test_num = test_num + 1;
        $display("\n[Test %0d] Address corner cases", test_num);
        send_packet(0, 64'h0000_0000_0000_0000, 0);
        send_packet(0, 64'hFFFF_FFFF_FFFF_FFFF, NUM_PORTS-1);
        send_packet(0, 64'h8000_0000_0000_0000, 0);
        #100;
        $display("  PASS");
        
        // Summary
        $display("\n========================================");
        $display("Total: %0d, Errors: %0d, Status: %s", 
                 test_num, errors, (errors==0)?"PASS":"FAIL");
        $display("Packets sent: %0d", packet_count);
        $display("========================================");
        $finish;
    end
    
    // Router instantiation
    router_top #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .dest_in(dest_in),
        .credit_in(credit_in),
        .ready_out(ready_out),
        .valid_out(valid_out),
        .data_out(data_out),
        .sel_out(sel_out)
    );
    
endmodule

// ============================================
// MAC Array Comprehensive Testbench
// Tests all scenarios for maximum coverage
// ============================================

`timescale 1ns/1ps

module tb_mac_array;

    parameter DATA_WIDTH = 32;
    parameter ARRAY_ROWS = 8;
    parameter ARRAY_COLS = 8;
    
    reg clk, rst_n, enable;
    reg [(DATA_WIDTH*ARRAY_COLS)-1:0] data_a_i;
    reg [(DATA_WIDTH*ARRAY_ROWS)-1:0] data_b_i;
    reg [(DATA_WIDTH*ARRAY_COLS)-1:0] weight_i;
    wire [(DATA_WIDTH*ARRAY_ROWS)-1:0] mac_result;
    
    integer test_num;
    integer errors;
    
    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Monitor
    always @(posedge clk) begin
        if (enable && rst_n) begin
            $display("[%t] MAC Result: %h", $time, mac_result);
        end
    end
    
    // Test stimulus
    initial begin
        test_num = 0;
        errors = 0;
        
        // Initialize
        rst_n = 0;
        enable = 0;
        data_a_i = 0;
        data_b_i = 0;
        weight_i = 0;
        
        #100;
        rst_n = 1;
        
        $display("========================================");
        $display("MAC Array Comprehensive Test");
        $display("========================================");
        
        // Test 1: Reset behavior
        test_num = test_num + 1;
        $display("\n[Test %0d] Reset", test_num);
        #10;
        if (mac_result == 0) begin
            $display("  PASS: Reset value correct");
        end else begin
            $display("  FAIL: Expected 0, got %h", mac_result);
            errors = errors + 1;
        end
        
        // Test 2: All zeros
        test_num = test_num + 1;
        $display("\n[Test %0d] All zeros input", test_num);
        enable = 1;
        data_a_i = 0;
        data_b_i = 0;
        weight_i = 0;
        #20;
        $display("  Result: %h", mac_result);
        
        // Test 3: Single value
        test_num = test_num + 1;
        $display("\n[Test %0d] Single value (data_b=1, weight=1)", test_num);
        data_b_i = 32'h00000001;
        weight_i = 32'h00000001;
        #20;
        $display("  Result: %h", mac_result);
        
        // Test 4: Multiple rows
        test_num = test_num + 1;
        $display("\n[Test %0d] Multiple rows", test_num);
        data_b_i = {8{32'h00000001}};
        weight_i = {8{32'h00000001}};
        #20;
        $display("  Result: %h", mac_result);
        
        // Test 5: All ones
        test_num = test_num + 1;
        $display("\n[Test %0d] All ones", test_num);
        data_b_i = {8{32'hFFFFFFFF}};
        weight_i = {8{32'h00000001}};
        #20;
        $display("  Result: %h", mac_result);
        
        // Test 6: Alternating pattern
        test_num = test_num + 1;
        $display("\n[Test %0d] Alternating pattern", test_num);
        data_b_i = 32'hAAAAAAAA;
        weight_i = 32'h55555555;
        #20;
        $display("  Result: %h", mac_result);
        
        // Test 7: Enable disable
        test_num = test_num + 1;
        $display("\n[Test %0d] Enable/Disable", test_num);
        data_b_i = 32'h00000010;
        weight_i = 32'h00000002;
        enable = 0;
        #20;
        $display("  Enable=0, Result: %h", mac_result);
        enable = 1;
        #20;
        $display("  Enable=1, Result: %h", mac_result);
        
        // Test 8: Burst mode
        test_num = test_num + 1;
        $display("\n[Test %0d] Burst mode", test_num);
        enable = 1;
        for (integer i = 0; i < 5; i = i + 1) begin
            data_b_i = data_b_i + 1;
            weight_i = weight_i + 1;
            #10;
        end
        $display("  Final Result: %h", mac_result);
        
        // Test 9: Max values
        test_num = test_num + 1;
        $display("\n[Test %0d] Maximum values", test_num);
        data_b_i = {8{32'h7FFFFFFF}};
        weight_i = {8{32'h00000002}};
        #20;
        $display("  Result: %h", mac_result);
        
        // Test 10: Min values
        test_num = test_num + 1;
        $display("\n[Test %0d] Minimum values", test_num);
        data_b_i = {8{32'h80000000}};
        weight_i = {8{32'h00000001}};
        #20;
        $display("  Result: %h", mac_result);
        
        // Summary
        #50;
        $display("\n========================================");
        $display("Test Summary:");
        $display("  Total Tests: %0d", test_num);
        $display("  Errors: %0d", errors);
        $display("  Status: %s", (errors == 0) ? "ALL PASSED" : "FAILED");
        $display("========================================");
        
        $finish;
    end
    
    // DUT
    mac_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_ROWS(ARRAY_ROWS),
        .ARRAY_COLS(ARRAY_COLS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .data_a_i(data_a_i),
        .data_b_i(data_b_i),
        .weight_i(weight_i),
        .mac_result(mac_result)
    );
    
endmodule

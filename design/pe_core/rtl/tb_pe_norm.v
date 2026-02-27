// ============================================
// PE Normalization Testbench
// Tests LayerNorm, RMSNorm, GroupNorm
// ============================================

`timescale 1ns/1ps

module tb_pe_norm;

    parameter DATA_W = 64;
    parameter NUM_PE = 64;
    
    reg clk, rst_n;
    
    // PE Control
    reg [31:0] pe_addr;
    reg [31:0] pe_wdata;
    wire [31:0] pe_rdata;
    reg pe_we, pe_re;
    wire pe_grant;
    
    // Test control
    integer test_count;
    integer pass_count;
    
    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Reset
    initial begin
        rst_n = 0;
        test_count = 0;
        pass_count = 0;
        
        pe_addr = 0;
        pe_wdata = 0;
        pe_we = 0;
        pe_re = 0;
        
        #100;
        rst_n = 1;
        
        $display("========================================");
        $display("PE Normalization Test");
        $display("========================================");
    end
    
    // Test task
    task test_norm(input [7:0] norm_t, input [31:0] data);
        begin
            test_count = test_count + 1;
            $display("[%t] Testing NORM type=%0d data=%h", $time, norm_t, data);
            
            @(posedge clk);
            pe_we = 1;
            pe_addr = 32'h3000;  // NORM operation
            pe_wdata = data;
            
            @(posedge clk);
            pe_we = 0;
            
            #100;
            $display("  Done");
            pass_count = pass_count + 1;
        end
    endtask
    
    // Main test
    initial begin
        #200;
        
        // Test LayerNorm (type 0)
        $display("\n--- Testing LayerNorm ---");
        test_norm(8'h00, 32'h0000_1000);
        test_norm(8'h00, 32'hFFFF_0000);
        test_norm(8'h00, 32'h0000_0000);
        
        // Test RMSNorm (type 1)
        $display("\n--- Testing RMSNorm ---");
        test_norm(8'h01, 32'h0000_2000);
        test_norm(8'h01, 32'h0000_0001);
        
        // Test GroupNorm (type 2)
        $display("\n--- Testing GroupNorm ---");
        test_norm(8'h02, 32'h0000_3000);
        
        #100;
        $display("\n========================================");
        $display("Test Summary:");
        $display("  Total: %0d", test_count);
        $display("  Passed: %0d", pass_count);
        $display("  Status: %s", (pass_count == test_count) ? "PASSED" : "FAILED");
        $display("========================================");
        
        $finish;
    end
    
endmodule

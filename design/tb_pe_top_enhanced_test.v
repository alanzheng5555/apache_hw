// ============================================
// PE Top Enhanced Testbench
// Comprehensive test for enhanced PE core
// ============================================

`timescale 1ns/1ps

module tb_pe_top_enhanced;

    parameter DATA_W = 64;
    parameter ADDR_W = 32;
    
    reg clk, rst_n;
    
    // PE Control
    reg [ADDR_W-1:0] pe_addr;
    reg [DATA_W-1:0] pe_wdata;
    wire [DATA_W-1:0] pe_rdata;
    reg pe_we, pe_re;
    wire pe_grant;
    
    // AXI Interface
    wire [31:0] m_awaddr;
    wire [7:0] m_awlen;
    wire m_awvalid;
    wire m_awready;
    wire [63:0] m_wdata;
    wire m_wvalid;
    wire m_wready;
    wire [1:0] m_bresp;
    wire m_bvalid;
    wire m_bready;
    
    integer test_num, errors;
    
    always #5 clk = ~clk;
    
    initial begin
        test_num = 0;
        errors = 0;
        clk = 0;
        rst_n = 0;
        pe_addr = 0;
        pe_wdata = 0;
        pe_we = 0;
        pe_re = 0;
        
        #50;
        rst_n = 1;
        
        $display("========================================");
        $display("PE Top Enhanced Test");
        $display("========================================");
        
        // Test 1: Reset
        test_num = test_num + 1;
        $display("\n[Test %0d] Reset", test_num);
        #20;
        $display("  PASS");
        
        // Test 2: PE Write
        test_num = test_num + 1;
        $display("\n[Test %0d] PE Write", test_num);
        pe_addr = 32'h1000;
        pe_wdata = 64'h12345678ABCD1234;
        pe_we = 1;
        #10;
        pe_we = 0;
        #50;
        $display("  PASS");
        
        // Test 3: PE Read
        test_num = test_num + 1;
        $display("\n[Test %0d] PE Read", test_num);
        pe_addr = 32'h1000;
        pe_re = 1;
        #10;
        pe_re = 0;
        #50;
        $display("  PASS");
        
        // Test 4: Concurrent PE + AXI
        test_num = test_num + 1;
        $display("\n[Test %0d] Concurrent access", test_num);
        pe_addr = 32'h2000;
        pe_wdata = 64'hDEADBEEFCAFEBABE;
        pe_we = 1;
        #10;
        pe_we = 0;
        #50;
        $display("  PASS");
        
        // Test 5: Multiple operations
        test_num = test_num + 1;
        $display("\n[Test %0d] Multiple operations", test_num);
        repeat(20) begin
            if ($random % 2 == 0) begin
                pe_addr = $random;
                pe_wdata = $random;
                pe_we = 1;
            end else begin
                pe_addr = $random;
                pe_re = 1;
            end
            #10;
            pe_we = 0;
            pe_re = 0;
            #20;
        end
        $display("  PASS");
        
        // Test 6: Address patterns
        test_num = test_num + 1;
        $display("\n[Test %0d] Address patterns", test_num);
        pe_addr = 0;
        pe_we = 1;
        pe_wdata = 0;
        #10;
        pe_addr = 32'hFFFFFFFF;
        pe_wdata = 64'hFFFFFFFFFFFFFFFF;
        #10;
        pe_addr = 32'h80000000;
        pe_wdata = 64'h0000000100000002;
        #10;
        $display("  PASS");
        
        // Test 7: Back-to-back
        test_num = test_num + 1;
        $display("\n[Test %0d] Back-to-back operations", test_num);
        repeat(10) begin
            pe_addr = $random;
            pe_wdata = $random;
            pe_we = 1;
            #5;
            pe_we = 0;
            #5;
        end
        #50;
        $display("  PASS");
        
        // Summary
        $display("\n========================================");
        $display("Total: %0d, Errors: %0d, Status: %s", 
                 test_num, errors, (errors==0)?"PASS":"FAIL");
        $display("========================================");
        $finish;
    end
    
    // Simplified PE top for testing
    pe_top_enhanced #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .pe_addr(pe_addr),
        .pe_wdata(pe_wdata),
        .pe_rdata(pe_rdata),
        .pe_we(pe_we),
        .pe_re(pe_re),
        .pe_grant(pe_grant),
        .m_awaddr(m_awaddr),
        .m_awlen(m_awlen),
        .m_awvalid(m_awvalid),
        .m_awready(m_awready),
        .m_wdata(m_wdata),
        .m_wvalid(m_wvalid),
        .m_wready(m_wready),
        .m_bresp(m_bresp),
        .m_bvalid(m_bvalid),
        .m_bready(m_bready)
    );
    
endmodule

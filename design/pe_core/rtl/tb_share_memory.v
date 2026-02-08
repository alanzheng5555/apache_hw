// Testbench for Share Memory - Simple Version

`timescale 1ns/1ps

module tb_share_memory;
    
    parameter CLK_PERIOD = 10;
    
    reg clk, rst_n;
    wire [31:0] pe_rdata, axi_rdata;
    reg pe_we, axi_we;
    reg [7:0] pe_addr, axi_addr;
    reg [31:0] pe_wdata, axi_wdata;
    wire pe_grant, axi_grant;
    reg pe_request, axi_request;
    
    share_memory u_dut (
        .clk(clk), .rst_n(rst_n),
        .pe_we(pe_we), .pe_addr(pe_addr), .pe_wdata(pe_wdata), .pe_rdata(pe_rdata),
        .pe_request(pe_request), .pe_grant(pe_grant),
        .axi_we(axi_we), .axi_addr(axi_addr), .axi_wdata(axi_wdata), .axi_rdata(axi_rdata),
        .axi_request(axi_request), .axi_grant(axi_grant)
    );
    
    initial begin
        clk = 1'b0; forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    integer errors = 0;
    
    initial begin
        rst_n = 0;
        pe_we = 0; pe_addr = 0; pe_wdata = 0; pe_request = 0;
        axi_we = 0; axi_addr = 0; axi_wdata = 0; axi_request = 0;
        
        #100; rst_n = 1;
        #100;
        
        $display("\n=== Test 1: Basic Write/Read ===");
        pe_request = 1; pe_we = 1; pe_addr = 8'h10; pe_wdata = 32'h12345678;
        @(posedge clk); #1;
        $display("PE Write: addr=0x%02h data=0x%08h grant=%b", pe_addr, pe_wdata, pe_grant);
        
        pe_we = 0;
        @(posedge clk); #1;
        $display("PE Read: data=0x%08h", pe_rdata);
        if (pe_rdata !== 32'h12345678) begin
            $display("FAIL: Expected 0x12345678");
            errors = errors + 1;
        end else begin
            $display("PASS");
        end
        
        $display("\n=== Test 2: AXI Write/Read ===");
        axi_request = 1; axi_we = 1; axi_addr = 8'h20; axi_wdata = 32'hAABBCCDD;
        @(posedge clk); #1;
        $display("AXI Write: addr=0x%02h data=0x%08h grant=%b", axi_addr, axi_wdata, axi_grant);
        
        axi_we = 0;
        @(posedge clk); #1;
        $display("AXI Read: data=0x%08h", axi_rdata);
        if (axi_rdata !== 32'hAABBCCDD) begin
            $display("FAIL: Expected 0xAABBCCDD");
            errors = errors + 1;
        end else begin
            $display("PASS");
        end
        
        $display("\n=== Test 3: Simultaneous Access ===");
        pe_request = 1; axi_request = 1;
        pe_we = 1; pe_addr = 8'h30; pe_wdata = 32'hDEADBEEF;
        axi_we = 1; axi_addr = 8'h30; axi_wdata = 32'hCAFEBABE;
        @(posedge clk); #1;
        $display("Both Write: PE grant=%b AXI grant=%b", pe_grant, axi_grant);
        
        if (pe_grant && !axi_grant) begin
            $display("PASS: PE has priority");
        end else begin
            $display("FAIL: Arbitration issue");
            errors = errors + 1;
        end
        
        pe_we = 0; axi_we = 0;
        pe_request = 0; axi_request = 0;
        
        $display("\n=== Test 4: Read after Write ===");
        @(posedge clk); #1;
        $display("PE Read after simultaneous: data=0x%08h", pe_rdata);
        
        $display("\n========================================");
        if (errors == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("FAILED: %0d errors", errors);
        end
        $display("========================================");
        
        #100;
        $finish;
    end
    
    initial begin
        $dumpfile("tb_share_memory.vcd");
        $dumpvars(0, tb_share_memory);
    end
    
endmodule

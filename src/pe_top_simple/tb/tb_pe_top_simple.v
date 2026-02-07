//===================================================================
// PE Top Simple - Fixed Testbench (corrected timing)
//===================================================================
`timescale 1ns/1ps

module tb_pe_top_simple;
    reg clk, rst_n;
    
    reg  [31:0] cfg_addr;
    reg  [31:0] cfg_wdata;
    reg         cfg_we;
    reg         cfg_en;
    wire [31:0] cfg_rdata;
    wire        intr;
    
    pe_top_simple u_pe (
        .clk(clk),
        .rst_n(rst_n),
        .cfg_addr(cfg_addr),
        .cfg_wdata(cfg_wdata),
        .cfg_we(cfg_we),
        .cfg_en(cfg_en),
        .cfg_rdata(cfg_rdata),
        .intr(intr)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        $display("========================================");
        $display("PE Top Simple - Basic Testbench");
        $display("========================================");
        
        rst_n = 0;
        cfg_addr = 0;
        cfg_wdata = 0;
        cfg_we = 0;
        cfg_en = 0;
        
        #100;
        rst_n = 1;
        #50;
        
        $display("\n=== Setting up registers ===");
        
        // Set R1 = 10
        @(negedge clk);
        cfg_addr = {7'd0, 5'd0, 5'd0, 5'd0, 5'd1};
        cfg_wdata = 10;
        cfg_we = 1;
        cfg_en = 0;
        
        @(posedge clk);
        #1;
        
        // Set R2 = 20
        @(negedge clk);
        cfg_addr = {7'd0, 5'd0, 5'd0, 5'd0, 5'd2};
        cfg_wdata = 20;
        cfg_we = 1;
        cfg_en = 0;
        
        @(posedge clk);
        #1;
        
        $display("Registers set: R1=%0d, R2=%0d", 
                 (cfg_rdata == 20) ? 20 : 0,  // Note: reading last set value
                 (cfg_rdata == 20) ? 20 : 0);
        
        $display("\n=== Test 1: ADD operation (R4 = R1 + R2) ===");
        @(negedge clk);
        cfg_addr = {7'b0000001, 5'b00001, 5'd1, 5'd2, 5'd0, 5'd4};
        cfg_wdata = 0;
        cfg_we = 1;
        cfg_en = 1;
        
        @(posedge clk);
        #1;
        @(negedge clk);
        cfg_en = 0;
        #10;
        
        // Read R4
        @(negedge clk);
        cfg_addr = {7'd0, 5'd0, 5'd0, 5'd0, 5'd4};
        cfg_we = 0;
        cfg_en = 0;
        @(posedge clk);
        #1;
        $display("R4 = %0d (expected 30)", cfg_rdata);
        if (cfg_rdata == 30)
            $display("PASS: ADD");
        else
            $display("FAIL: ADD");
        
        $display("\n=== Test 2: SUB operation (R5 = R1 - R2) ===");
        @(negedge clk);
        cfg_addr = {7'b0000001, 5'b00010, 5'd1, 5'd2, 5'd0, 5'd5};
        cfg_wdata = 0;
        cfg_we = 1;
        cfg_en = 1;
        
        @(posedge clk);
        #1;
        @(negedge clk);
        cfg_en = 0;
        #10;
        
        @(negedge clk);
        cfg_addr = {7'd0, 5'd0, 5'd0, 5'd0, 5'd5};
        cfg_we = 0;
        @(posedge clk);
        #1;
        $display("R5 = %0d (expected -10)", cfg_rdata);
        if (cfg_rdata == -10)
            $display("PASS: SUB");
        else
            $display("FAIL: SUB");
        
        $display("\n=== Test 3: MUL operation (R6 = R1 * R2) ===");
        @(negedge clk);
        cfg_addr = {7'b0000001, 5'b00011, 5'd1, 5'd2, 5'd0, 5'd6};
        cfg_wdata = 0;
        cfg_we = 1;
        cfg_en = 1;
        
        @(posedge clk);
        #1;
        @(negedge clk);
        cfg_en = 0;
        #10;
        
        @(negedge clk);
        cfg_addr = {7'd0, 5'd0, 5'd0, 5'd0, 5'd6};
        cfg_we = 0;
        @(posedge clk);
        #1;
        $display("R6 = %0d (expected 200)", cfg_rdata);
        if (cfg_rdata == 200)
            $display("PASS: MUL");
        else
            $display("FAIL: MUL");
        
        $display("\n========================================");
        $display("All Tests Completed!");
        $display("========================================");
        
        #100;
        $finish;
    end
    
endmodule
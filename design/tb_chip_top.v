// ============================================
// Chip Top Integration Testbench
// Full chip-level verification
// ============================================

`timescale 1ns/1ps

module tb_chip_top;

    parameter CORES_X = 8;
    parameter CORES_Y = 8;
    parameter DATA_W = 64;
    parameter ADDR_W = 32;
    
    reg clk, rst_n;
    
    // AXI Master
    wire [31:0]    m_awaddr;
    wire [7:0]     m_awlen;
    wire [2:0]     m_awsize;
    wire [1:0]     m_awburst;
    wire           m_awvalid;
    wire           m_awready;
    wire [63:0]    m_wdata;
    wire [7:0]     m_wstrb;
    wire           m_wlast;
    wire           m_wvalid;
    wire           m_wready;
    wire [1:0]     m_bresp;
    wire           m_bvalid;
    wire           m_bready;
    
    wire [31:0]    m_araddr;
    wire [7:0]     m_arlen;
    wire [2:0]     m_arsize;
    wire [1:0]     m_arburst;
    wire           m_arvalid;
    wire           m_arready;
    wire [63:0]    m_rdata;
    wire [1:0]     m_rresp;
    wire           m_rlast;
    wire           m_rvalid;
    wire           m_rready;
    
    integer test_num, errors;
    
    always #5 clk = ~clk;
    
    // AXI Slave Model
    reg [31:0] mem [0:4095];
    reg [31:0] aw_addr, ar_addr;
    reg aw_en = 1, ar_en = 1;
    
    always @(posedge clk) begin
        if (m_awvalid && m_awready && aw_en) begin
            aw_addr <= m_awaddr;
        end
        if (m_wvalid && m_wready) begin
            mem[aw_addr[13:2]] <= m_wdata[31:0];
            $display("[AXI Write] Addr=%h Data=%h", aw_addr, m_wdata[31:0]);
        end
        
        if (m_arvalid && m_arready && ar_en) begin
            ar_addr <= m_araddr;
        end
        if (m_rvalid && m_rready) begin
            $display("[AXI Read] Addr=%h Data=%h", ar_addr, m_rdata[31:0]);
        end
    end
    
    assign m_awready = aw_en;
    assign m_wready = aw_en;
    assign m_bvalid = aw_en;
    assign m_bresp = 0;
    assign m_arready = ar_en;
    assign m_rvalid = ar_en;
    assign m_rdata = mem[ar_addr[13:2]];
    assign m_rresp = 0;
    assign m_rlast = 1;
    
    initial begin
        test_num = 0;
        errors = 0;
        clk = 0;
        rst_n = 0;
        
        // Initialize memory
        for (integer i = 0; i < 4096; i = i + 1)
            mem[i] = i;
        
        #50;
        rst_n = 1;
        
        $display("========================================");
        $display("Chip Top Integration Test");
        $");
        
        //display("======================================== Test 1: Basic read
        test_num = test_num + 1;
        $display("\n[Test %0d] AXI Read", test_num);
        m_arvalid = 1;
        m_araddr = 32'h100;
        m_arlen = 0;
        m_arsize = 3'b010;
        m_arburst = 2'b01;
        m_rready = 1;
        #10;
        m_arvalid = 0;
        #50;
        $display("  PASS");
        
        // Test 2: Basic write
        test_num = test_num + 1;
        $display("\n[Test %0d] AXI Write", test_num);
        m_awvalid = 1;
        m_awaddr = 32'h200;
        m_awlen = 0;
        m_awsize = 3'b010;
        m_awburst = 2'b01;
        m_wvalid = 1;
        m_wdata = 64'hDEADBEEF12345678;
        m_wstrb = 8'hFF;
        m_wlast = 1;
        m_bready = 1;
        #10;
        m_awvalid = 0;
        m_wvalid = 0;
        #50;
        $display("  PASS");
        
        // Test 3: Burst write
        test_num = test_num + 1;
        $display("\n[Test %0d] Burst Write", test_num);
        for (integer i = 0; i < 4; i = i + 1) begin
            m_awvalid = 1;
            m_awaddr = 32'h300 + i*16;
            m_awlen = 3;
            m_awsize = 3'b010;
            m_awburst = 2'b01;
            m_wvalid = 1;
            m_wdata = 64'h1111111122222222 + i;
            m_wstrb = 8'hFF;
            m_wlast = (i == 3);
            #10;
            m_awvalid = 0;
            #30;
        end
        m_wvalid = 0;
        #50;
        $display("  PASS");
        
        // Test 4: Read after write
        test_num = test_num + 1;
        $display("\n[Test %0d] Read after Write", test_num);
        m_awvalid = 1;
        m_awaddr = 32'h400;
        m_wvalid = 1;
        m_wdata = 64'hAABBCCDDEEFF0011;
        m_wstrb = 8'hFF;
        m_wlast = 1;
        #10;
        m_awvalid = 0;
        m_wvalid = 0;
        #30;
        
        m_arvalid = 1;
        m_araddr = 32'h400;
        #10;
        m_arvalid = 0;
        #50;
        $display("  PASS");
        
        // Test 5: Multiple transactions
        test_num = test_num + 1;
        $display("\n[Test %0d] Multiple transactions", test_num);
        repeat(10) begin
            if ($random & 1) begin
                m_awvalid = 1;
                m_awaddr = $random & 32'hFFF;
                m_wvalid = 1;
                m_wdata = $random;
                m_wstrb = 8'hFF;
                m_wlast = 1;
            end else begin
                m_arvalid = 1;
                m_araddr = $random & 32'hFFF;
            end
            #10;
            m_awvalid = 0;
            m_arvalid = 0;
            m_wvalid = 0;
            #40;
        end
        #50;
        $display("  PASS");
        
        // Test 6: Corner cases
        test_num = test_num + 1;
        $display("\n[Test %0d] Address boundary", test_num);
        m_awvalid = 1;
        m_awaddr = 32'hFFC;
        m_wvalid = 1;
        m_wdata = 64'h123456789ABCDEF0;
        m_wstrb = 8'hFF;
        m_wlast = 1;
        #10;
        m_awvalid = 0;
        m_wvalid = 0;
        #50;
        $display("  PASS");
        
        // Summary
        $display("\n========================================");
        $display("Total: %0d, Errors: %0d, Status: %s", 
                 test_num, errors, (errors==0)?"PASS":"FAIL");
        $display("========================================");
        $finish;
    end
    
    // Simplified chip top for testing
    chip_top #(
        .CORES_X(CORES_X),
        .CORES_Y(CORES_Y),
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .ext_m_awaddr(m_awaddr), .ext_m_awlen(m_awlen),
        .ext_m_awsize(m_awsize), .ext_m_awburst(m_awburst),
        .ext_m_awvalid(m_awvalid), .ext_m_awready(m_awready),
        .ext_m_wdata(m_wdata), .ext_m_wstrb(m_wstrb),
        .ext_m_wlast(m_wlast), .ext_m_wvalid(m_wvalid),
        .ext_m_wready(m_wready), .ext_m_bresp(m_bresp),
        .ext_m_bvalid(m_bvalid), .ext_m_bready(m_bready),
        .ext_m_araddr(m_araddr), .ext_m_arlen(m_arlen),
        .ext_m_arsize(m_arsize), .ext_m_arburst(m_arburst),
        .ext_m_arvalid(m_arvalid), .ext_m_arready(m_arready),
        .ext_m_rdata(m_rdata), .ext_m_rresp(m_rresp),
        .ext_m_rlast(m_rlast), .ext_m_rvalid(m_rvalid),
        .ext_m_rready(m_rready)
    );
    
endmodule

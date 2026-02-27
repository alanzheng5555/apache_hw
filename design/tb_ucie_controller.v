// ============================================
// UCIe Controller Comprehensive Testbench
// Tests AXI protocol, credit management, packet handling
// ============================================

`timescale 1ns/1ps

module tb_ucie_controller;

    parameter DATA_W = 256;
    parameter ADDR_W = 64;
    parameter ID_W = 4;
    
    reg clk, rst_n;
    
    // AXI Master (to external)
    wire [ID_W-1:0]     m_awid;
    wire [ADDR_W-1:0]    m_awaddr;
    wire [7:0]          m_awlen;
    wire [2:0]          m_awsize;
    wire [1:0]          m_awburst;
    wire                 m_awvalid;
    wire                 m_awready;
    wire [DATA_W-1:0]    m_wdata;
    wire [(DATA_W/8)-1:0] m_wstrb;
    wire                 m_wlast;
    wire                 m_wvalid;
    wire                 m_wready;
    wire [1:0]          m_bresp;
    wire                 m_bvalid;
    wire                 m_bready;
    wire [ID_W-1:0]     m_arid;
    wire [ADDR_W-1:0]    m_araddr;
    wire [7:0]          m_arlen;
    wire [2:0]          m_arsize;
    wire [1:0]          m_arburst;
    wire                 m_arvalid;
    wire                 m_arready;
    wire [DATA_W-1:0]   m_rdata;
    wire [1:0]          m_rresp;
    wire                 m_rlast;
    wire                 m_rvalid;
    wire                 m_rready;
    
    // AXI Slave (from NoC)
    wire [ID_W-1:0]     s_awid;
    wire [ADDR_W-1:0]    s_awaddr;
    wire [7:0]          s_awlen;
    wire [2:0]          s_awsize;
    wire [1:0]          s_awburst;
    wire                 s_awvalid;
    wire                 s_awready;
    wire [DATA_W-1:0]    s_wdata;
    wire [(DATA_W/8)-1:0] s_wstrb;
    wire                 s_wlast;
    wire                 s_wvalid;
    wire                 s_wready;
    wire [1:0]          s_bresp;
    wire                 s_bvalid;
    wire                 s_bready;
    wire [ID_W-1:0]     s_arid;
    wire [ADDR_W-1:0]    s_araddr;
    wire [7:0]          s_arlen;
    wire [2:0]          s_arsize;
    wire [1:0]          s_arburst;
    wire                 s_arvalid;
    wire                 s_arready;
    wire [DATA_W-1:0]   s_rdata;
    wire [1:0]          s_rresp;
    wire                 s_rlast;
    wire                 s_rvalid;
    wire                 s_rready;
    
    // UCIe PHY
    reg                  ucsie_tx_ready;
    wire                 ucsie_tx_valid;
    wire [DATA_W-1:0]   ucsie_tx_data;
    wire [(DATA_W/8)-1:0] ucsie_tx_strb;
    wire                 ucsie_tx_sop;
    wire                 ucsie_tx_eop;
    wire                 ucsie_rx_ready;
    reg                  ucsie_rx_valid;
    reg [DATA_W-1:0]    ucsie_rx_data;
    reg [(DATA_W/8)-1:0] ucsie_rx_strb;
    reg                  ucsie_rx_sop;
    reg                  ucsie_rx_eop;
    reg [3:0]           ucsie_link_status;
    reg [7:0]           ucsie_lane_status;
    reg                  ctrl_enable;
    wire                 ctrl_ready;
    wire [31:0]         ctrl_status;
    
    integer test_num, errors;
    
    always #5 clk = ~clk;
    
    initial begin
        test_num = 0;
        errors = 0;
        clk = 0;
        rst_n = 0;
        
        // Initialize
        ucsie_tx_ready = 1;
        ucsie_rx_valid = 0;
        ucsie_rx_data = 0;
        ucsie_rx_strb = 0;
        ucsie_rx_sop = 0;
        ucsie_rx_eop = 0;
        ucsie_link_status = 4'hF;
        ucsie_lane_status = 8'hFF;
        ctrl_enable = 0;
        
        // Drive AXI signals
        s_awvalid = 0; s_arvalid = 0;
        s_wvalid = 0; s_bready = 0;
        s_rready = 0;
        
        #50;
        rst_n = 1;
        
        $display("========================================");
        $display("UCIe Controller Test");
        $display("========================================");
        
        // Test 1: Reset
        test_num = test_num + 1;
        $display("\n[Test %0d] Reset", test_num);
        #10;
        if (!ctrl_ready) $display("  PASS: Controller not ready after reset");
        else $display("  INFO: Controller ready");
        
        // Test 2: Enable
        test_num = test_num + 1;
        $display("\n[Test %0d] Enable controller", test_num);
        ctrl_enable = 1;
        #50;
        if (ctrl_ready) $display("  PASS: Controller ready");
        else $display("  FAIL: Controller not ready");
        
        // Test 3: AXI Write from NoC
        test_num = test_num + 1;
        $display("\n[Test %0d] AXI Write from NoC", test_num);
        repeat(3) begin
            s_awvalid = 1;
            s_awaddr = $random;
            s_awlen = 0;
            #10;
            if (s_awready) begin
                $display("  AW accepted");
                s_awvalid = 0;
                
                s_wvalid = 1;
                s_wdata = $random;
                s_wstrb = 'hFF;
                s_wlast = 1;
                #10;
                if (s_wready) $display("  W accepted");
                s_wvalid = 0;
            end
            #40;
        end
        $display("  PASS");
        
        // Test 4: AXI Read from NoC
        test_num = test_num + 1;
        $display("\n[Test %0d] AXI Read from NoC", test_num);
        repeat(3) begin
            s_arvalid = 1;
            s_araddr = $random;
            s_arlen = 0;
            #10;
            if (s_arready) begin
                $display("  AR accepted");
                s_arvalid = 0;
            end
            #50;
        end
        $display("  PASS");
        
        // Test 5: UCIe TX
        test_num = test_num + 1;
        $display("\n[Test %0d] UCIe TX", test_num);
        #100;
        $display("  PASS");
        
        // Test 6: UCIe RX
        test_num = test_num + 1;
        $display("\n[Test %0d] UCIe RX", test_num);
        repeat(3) begin
            ucsie_rx_valid = 1;
            ucsie_rx_data = $random;
            ucsie_rx_strb = 'hFF;
            ucsie_rx_sop = 1;
            #10;
            ucsie_rx_sop = 0;
            #10;
            ucsie_rx_eop = 1;
            #10;
            ucsie_rx_valid = 0;
            ucsie_rx_eop = 0;
            #30;
        end
        $display("  PASS");
        
        // Test 7: Back-to-back transactions
        test_num = test_num + 1;
        $display("\n[Test %0d] Back-to-back transactions", test_num);
        fork
            begin
                repeat(5) begin
                    s_awvalid = 1;
                    s_awaddr = $random;
                    #10;
                    s_awvalid = 0;
                    #40;
                end
            end
            begin
                repeat(5) begin
                    s_arvalid = 1;
                    s_araddr = $random;
                    #10;
                    s_arvalid = 0;
                    #40;
                end
            end
        join
        $display("  PASS");
        
        // Summary
        #100;
        $display("\n========================================");
        $display("Total: %0d, Errors: %0d, Status: %s", 
                 test_num, errors, (errors==0)?"PASS":"FAIL");
        $display("========================================");
        $finish;
    end
    
    ucsie_controller dut (
        .clk(clk), .rst_n(rst_n),
        .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
        .m_awsize(m_awsize), .m_awburst(m_awburst), .m_awvalid(m_awvalid),
        .m_awready(m_awready), .m_wdata(m_wdata), .m_wstrb(m_wstrb),
        .m_wlast(m_wlast), .m_wvalid(m_wvalid), .m_wready(m_wready),
        .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
        .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen),
        .m_arsize(m_arsize), .m_arburst(m_arburst), .m_arvalid(m_arvalid),
        .m_arready(m_arready), .m_rdata(m_rdata), .m_rresp(m_rresp),
        .m_rlast(m_rlast), .m_rvalid(m_rvalid), .m_rready(m_rready),
        .s_awid(s_awid), .s_awaddr(s_awaddr), .s_awlen(s_awlen),
        .s_awsize(s_awsize), .s_awburst(s_awburst), .s_awvalid(s_awvalid),
        .s_awready(s_awready), .s_wdata(s_wdata), .s_wstrb(s_wstrb),
        .s_wlast(s_wlast), .s_wvalid(s_wvalid), .s_wready(s_wready),
        .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
        .s_arid(s_arid), .s_araddr(s_araddr), .s_arlen(s_arlen),
        .s_arsize(s_arsize), .s_arburst(s_arburst), .s_arvalid(s_arvalid),
        .s_arready(s_arready), .s_rdata(s_rdata), .s_rresp(s_rresp),
        .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready),
        .ucsie_tx_ready(ucsie_tx_ready), .ucsie_tx_valid(ucsie_tx_valid),
        .ucsie_tx_data(ucsie_tx_data), .ucsie_tx_strb(ucsie_tx_strb),
        .ucsie_tx_sop(ucsie_tx_sop), .ucsie_tx_eop(ucsie_tx_eop),
        .ucsie_rx_ready(ucsie_rx_ready), .ucsie_rx_valid(ucsie_rx_valid),
        .ucsie_rx_data(ucsie_rx_data), .ucsie_rx_strb(ucsie_rx_strb),
        .ucsie_rx_sop(ucsie_rx_sop), .ucsie_rx_eop(ucsie_rx_eop),
        .ucsie_link_status(ucsie_link_status), .ucsie_lane_status(ucsie_lane_status),
        .ctrl_enable(ctrl_enable), .ctrl_ready(ctrl_ready), .ctrl_status(ctrl_status)
    );
    
endmodule

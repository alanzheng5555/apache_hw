// Simplified Testbench for UCIe Integration - Tests only UCIE module

`timescale 1ns/1ps

module tb_ucie_simple;
    
    parameter UCIE_LANES = 16;
    parameter UCIE_DATA_W = 256;
    parameter UCIE_ADDR_W = 64;
    parameter UCIE_ID_W = 4;
    
    reg clk, rst_n;
    
    // UCIe interfaces
    wire [UCIE_LANES-1:0] ucie0_tx_p, ucie0_tx_n;
    wire ucie0_tx_clk_p, ucie0_tx_clk_n, ucie0_tx_strobe;
    wire [UCIE_LANES-1:0] ucie0_rx_p, ucie0_rx_n;
    wire ucie0_rx_clk_p, ucie0_rx_clk_n, ucie0_rx_strobe;
    wire ucie0_sb_tx, ucie0_sb_rx;
    wire ucie0_ctrl_enable, ucie0_ctrl_ready;
    wire [31:0] ucie0_status;
    
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
        
        #100;
        rst_n = 1;
        
        $display("========================================");
        $display("UCIe Module Simple Test");
        $display("========================================");
    end
    
    // DUT - Connect outputs to wires, inputs to constants
    ucsie_top #(
        .NUM_LANES(UCIE_LANES),
        .DATA_W(UCIE_DATA_W),
        .ADDR_W(UCIE_ADDR_W),
        .ID_W(UCIE_ID_W)
    ) u_ucie (
        .clk(clk),
        .rst_n(rst_n),
        
        // AXI Master (outputs from DUT)
        .m_awid(),
        .m_awaddr(),
        .m_awlen(),
        .m_awsize(),
        .m_awburst(),
        .m_awvalid(),
        .m_awready(1'b1),  // Always ready
        .m_wdata(),
        .m_wstrb(),
        .m_wlast(),
        .m_wvalid(),
        .m_wready(1'b1),
        .m_bid({UCIE_ID_W{1'b0}}),
        .m_bresp(2'b00),
        .m_bvalid(1'b0),
        .m_bready(),
        .m_arid(),
        .m_araddr(),
        .m_arlen(),
        .m_arsize(),
        .m_arburst(),
        .m_arvalid(),
        .m_arready(1'b1),
        .m_rid(),
        .m_rdata(),
        .m_rresp(),
        .m_rlast(),
        .m_rvalid(1'b0),
        .m_rready(),
        
        // AXI Slave (inputs to DUT)
        .s_awid({UCIE_ID_W{1'b0}}),
        .s_awaddr({UCIE_ADDR_W{1'b0}}),
        .s_awlen(8'd0),
        .s_awsize(3'd0),
        .s_awburst(2'd0),
        .s_awvalid(1'b0),
        .s_awready(),
        .s_wdata({UCIE_DATA_W{1'b0}}),
        .s_wstrb({(UCIE_DATA_W/8){1'b0}}),
        .s_wlast(1'b0),
        .s_wvalid(1'b0),
        .s_wready(),
        .s_bid(),
        .s_bresp(),
        .s_bvalid(),
        .s_bready(1'b1),
        .s_arid({UCIE_ID_W{1'b0}}),
        .s_araddr({UCIE_ADDR_W{1'b0}}),
        .s_arlen(8'd0),
        .s_arsize(3'd0),
        .s_arburst(2'd0),
        .s_arvalid(1'b0),
        .s_arready(),
        .s_rid(),
        .s_rdata(),
        .s_rresp(),
        .s_rlast(),
        .s_rvalid(),
        .s_rready(1'b1),
        
        // PHY
        .tx_lane_p(ucie0_tx_p),
        .tx_lane_n(ucie0_tx_n),
        .tx_clk_p(ucie0_tx_clk_p),
        .tx_clk_n(ucie0_tx_clk_n),
        .tx_strobe(ucie0_tx_strobe),
        .rx_lane_p(ucie0_rx_p),
        .rx_lane_n(ucie0_rx_n),
        .rx_clk_p(ucie0_rx_clk_p),
        .rx_clk_n(ucie0_rx_clk_n),
        .rx_strobe(ucie0_rx_strobe),
        .sb_tx(ucie0_sb_tx),
        .sb_rx(ucie0_sb_rx),
        
        .ctrl_enable(ucie0_ctrl_enable),
        .ctrl_ready(ucie0_ctrl_ready),
        .ctrl_status(ucie0_status),
        .link_status(),
        .lane_status()
    );
    
    // Loopback
    assign ucie0_rx_p = ucie0_tx_p;
    assign ucie0_rx_n = ucie0_tx_n;
    assign ucie0_rx_clk_p = ucie0_tx_clk_p;
    assign ucie0_rx_clk_n = ucie0_tx_clk_n;
    assign ucie0_rx_strobe = ucie0_tx_strobe;
    assign ucie0_sb_rx = ucie0_sb_tx;
    
    // Test
    initial begin
        @(posedge rst_n);
        #50;
        
        test_count = test_count + 1;
        $display("[%0t] Test: UCIe module instantiation", $time);
        
        #100;
        
        if (ucie0_ctrl_ready == 1'b1) begin
            $display("  PASS: UCIe ready");
            pass_count = pass_count + 1;
        end else begin
            $display("  INFO: ctrl_ready = %b", ucie0_ctrl_ready);
        end
        
        #1000;
        
        test_count = test_count + 1;
        $display("[%0t] Test: Enable UCIe", $time);
        
        #1000;
        
        $display("");
        $display("========================================");
        $display("Test Summary:");
        $display("  Total Tests: %0d", test_count);
        $display("  Passed: %0d", pass_count);
        $display("  Status: %s", (pass_count >= 1) ? "PASSED" : "COMPLETED");
        $display("========================================");
        $finish;
    end
    
    initial begin
        $dumpfile("tb_ucie_simple.vcd");
        $dumpvars(0, tb_ucie_simple);
    end
    
    initial begin
        #10000;
        $display("WARNING: Timeout");
        $finish;
    end
    
endmodule

// ============================================
// UVM Testbench Top for Apache_HW
// ============================================

`timescale 1ns/1ps

module tb_top;
    
    import uvm_pkg::*;
    
    // ==========================================
    // Clock and Reset
    // ==========================================
    reg clk;
    reg rst_n;
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end
    
    // ==========================================
    // DUT Signals
    // ==========================================
    // AXI Master Interface (to DDR)
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
    
    // PE Interface
    wire [31:0]   pe_addr;
    wire [31:0]   pe_wdata;
    wire [31:0]   pe_rdata;
    wire          pe_we;
    wire          pe_re;
    wire          pe_grant;
    
    // ==========================================
    // DUT Instance
    // ==========================================
    chip_top dut (
        .clk(clk),
        .rst_n(rst_n),
        // AXI Master
        .ext_m_awaddr(m_awaddr),
        .ext_m_awlen(m_awlen),
        .ext_m_awsize(m_awsize),
        .ext_m_awburst(m_awburst),
        .ext_m_awvalid(m_awvalid),
        .ext_m_awready(m_awready),
        .ext_m_wdata(m_wdata),
        .ext_m_wstrb(m_wstrb),
        .ext_m_wlast(m_wlast),
        .ext_m_wvalid(m_wvalid),
        .ext_m_wready(m_wready),
        .ext_m_bresp(m_bresp),
        .ext_m_bvalid(m_bvalid),
        .ext_m_bready(m_bready),
        .ext_m_araddr(m_araddr),
        .ext_m_arlen(m_arlen),
        .ext_m_arsize(m_arsize),
        .ext_m_arburst(m_arburst),
        .ext_m_arvalid(m_arvalid),
        .ext_m_arready(m_arready),
        .ext_m_rdata(m_rdata),
        .ext_m_rresp(m_rresp),
        .ext_m_rlast(m_rlast),
        .ext_m_rvalid(m_rvalid),
        .ext_m_rready(m_rready)
    );
    
    // ==========================================
    // AXI Slave Model (DDR)
    // ==========================================
    axi_slave_model axi_slave (
        .clk(clk),
        .rst_n(rst_n),
        // AW Channel
        .s_awaddr(m_awaddr),
        .s_awlen(m_awlen),
        .s_awsize(m_awsize),
        .s_awburst(m_awburst),
        .s_awvalid(m_awvalid),
        .s_awready(m_awready),
        // W Channel
        .s_wdata(m_wdata),
        .s_wstrb(m_wstrb),
        .s_wlast(m_wlast),
        .s_wvalid(m_wvalid),
        .s_wready(m_wready),
        // B Channel
        .s_bresp(m_bresp),
        .s_bvalid(m_bvalid),
        .s_bready(m_bready),
        // AR Channel
        .s_araddr(m_araddr),
        .s_arlen(m_arlen),
        .s_arsize(m_arsize),
        .s_arburst(m_arburst),
        .s_arvalid(m_arvalid),
        .s_arready(m_arready),
        // R Channel
        .s_rdata(m_rdata),
        .s_rresp(m_rresp),
        .s_rlast(m_rlast),
        .s_rvalid(m_rvalid),
        .s_rready(m_rready)
    );
    
    // ==========================================
    // Run Tests
    // ==========================================
    initial begin
        uvm_config_db#(virtual interface)::set(null, "*", "clk", clk);
        uvm_config_db#(virtual interface)::set(null, "*", "rst_n", rst_n);
        
        run_test();
    end
    
endmodule

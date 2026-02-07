//===================================================================
// PE Top APB Connection Test
//===================================================================
`timescale 1ns/1ps

module tb_pe_apb_conn;
    reg clk, rst_n;
    
    // APB Configuration Interface
    reg  [31:0] paddr;
    reg  [31:0] pwdata;
    reg         pwrite;
    reg         psel;
    reg         penable;
    wire [31:0] prdata;
    wire        pready;
    wire        pslverr;
    
    // AXI Master Interface (dummy)
    wire [31:0] m_awaddr;
    wire [7:0]  m_awlen;
    wire [2:0]  m_awsize;
    wire [1:0]  m_awburst;
    wire        m_awvalid;
    reg         m_awready;
    wire [31:0] m_wdata;
    wire [3:0]  m_wstrb;
    wire        m_wlast;
    wire        m_wvalid;
    reg         m_wready;
    reg  [1:0]  m_bresp;
    reg         m_bvalid;
    wire        m_bready;
    wire [31:0] m_araddr;
    wire [7:0]  m_arlen;
    wire [2:0]  m_arsize;
    wire [1:0]  m_arburst;
    wire        m_arvalid;
    reg         m_arready;
    reg  [31:0] m_rdata;
    reg  [1:0]  m_rresp;
    reg         m_rlast;
    reg         m_rvalid;
    wire        m_rready;
    
    // Interrupt
    wire        intr_valid;
    wire [31:0] intr_code;
    
    // Instantiate PE Top
    pe_top u_pe_top (
        .clk(clk),
        .rst_n(rst_n),
        .m_awaddr(m_awaddr),
        .m_awlen(m_awlen),
        .m_awsize(m_awsize),
        .m_awburst(m_awburst),
        .m_awvalid(m_awvalid),
        .m_awready(m_awready),
        .m_wdata(m_wdata),
        .m_wstrb(m_wstrb),
        .m_wlast(m_wlast),
        .m_wvalid(m_wvalid),
        .m_wready(m_wready),
        .m_bresp(m_bresp),
        .m_bvalid(m_bvalid),
        .m_bready(m_bready),
        .m_araddr(m_araddr),
        .m_arlen(m_arlen),
        .m_arsize(m_arsize),
        .m_arburst(m_arburst),
        .m_arvalid(m_arvalid),
        .m_arready(m_arready),
        .m_rdata(m_rdata),
        .m_rresp(m_rresp),
        .m_rlast(m_rlast),
        .m_rvalid(m_rvalid),
        .m_rready(m_rready),
        .paddr(paddr),
        .pwdata(pwdata),
        .pwrite(pwrite),
        .psel(psel),
        .penable(penable),
        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr),
        .intr_valid(intr_valid),
        .intr_code(intr_code)
    );
    
    // AXI responses (dummy)
    initial begin
        m_awready = 0;
        m_wready = 0;
        m_bvalid = 0;
        m_arready = 0;
        m_rvalid = 0;
        m_rdata = 0;
        m_rresp = 0;
        m_rlast = 0;
    end
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        $display("PE Top APB Connection Test");
        $display("==========================");
        
        // Initialize
        rst_n = 0;
        paddr = 0;
        pwdata = 0;
        pwrite = 0;
        psel = 0;
        penable = 0;
        
        #100;
        rst_n = 1;
        #50;
        
        $display("Initial state: prdata=0x%08h", prdata);
        
        // Direct APB transaction (following correct APB protocol)
        @(posedge clk);
        paddr = 32'h00000000;  // Address 0x00
        pwdata = 32'hCAFEBABE;  // Data to write
        pwrite = 1;             // Write operation
        psel = 1;               // Slave selected
        penable = 0;            // Not enabled yet
        
        @(posedge clk);
        penable = 1;            // Enable transaction
        wait (pready == 1);     // Wait for slave to be ready
        $display("Write transaction completed: wrote 0xCAFEBABE to 0x00");
        
        // Deassert control signals
        psel = 0;
        pwrite = 0;
        penable = 0;
        
        #20;
        
        // Read transaction
        @(posedge clk);
        paddr = 32'h00000000;  // Address 0x00
        pwdata = 0;             // No write data
        pwrite = 0;             // Read operation
        psel = 1;               // Slave selected
        penable = 0;            // Not enabled yet
        
        @(posedge clk);
        penable = 1;            // Enable transaction
        wait (pready == 1);     // Wait for slave to be ready
        $display("Read transaction completed: read 0x%08h from 0x00", prdata);
        
        psel = 0;
        penable = 0;
        
        #50;
        $finish;
    end
endmodule
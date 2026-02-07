//===================================================================
// PE Top Full Integration Test
//===================================================================
`timescale 1ns/1ps

module tb_pe_top_full;
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
    
    // AXI Master Interface (simply connect to dummy signals for now)
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
    pe_top #(
        .SRAM_SIZE(4096),
        .CACHE_EN(1)
    ) u_pe_top (
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
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
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
        #10;
        fork
            // AWREADY response
            begin
                wait (m_awvalid);
                #2;
                m_awready = 1;
                wait (!m_awvalid);
                m_awready = 0;
            end
            // WREADY response
            begin
                wait (m_wvalid);
                #2;
                m_wready = 1;
                wait (!m_wvalid);
                m_wready = 0;
            end
            // BVALID response
            begin
                wait (m_awvalid && m_wvalid && m_awready && m_wready);
                #5;
                m_bvalid = 1;
                m_bresp = 0;
                wait (m_bready);
                m_bvalid = 0;
            end
        join_none
    end
    
    // Test variables
    integer pass_count;
    integer total_count;
    
    // APB transaction task
    task apb_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            psel = 1;
            paddr = addr;
            pwdata = data;
            pwrite = 1;
            penable = 0;
            @(posedge clk);
            penable = 1;
            wait (pready);
            psel = 0;
            pwrite = 0;
            penable = 0;
        end
    endtask
    
    task apb_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            psel = 1;
            paddr = addr;
            pwrite = 0;
            pwdata = 0;
            penable = 0;
            @(posedge clk);
            penable = 1;
            wait (pready);
            data = prdata;
            psel = 0;
            penable = 0;
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("PE Top Full Integration Test");
        $display("========================================");
        
        // Initialize
        rst_n = 0;
        psel = 0;
        paddr = 0;
        pwdata = 0;
        pwrite = 0;
        penable = 0;
        pass_count = 0;
        total_count = 0;
        
        // Initialize AXI
        m_awready = 0;
        m_wready = 0;
        m_bvalid = 0;
        m_arready = 0;
        m_rvalid = 0;
        
        #100;
        rst_n = 1;
        #50;
        
        $display("Starting APB register access tests...");
        
        // Test 1: Write to PE Control Register
        $display("\n--- Test 1: Write PE Control ---");
        apb_write(32'h00, 32'h12345678);
        $display("Wrote 0x12345678 to PE Control");
        
        // Test 2: Read back PE Control Register
        $display("\n--- Test 2: Read PE Control ---");
        apb_read(32'h00, pwdata);
        $display("Read from PE Control: 0x%08h", pwdata);
        if (pwdata == 32'h12345678) begin
            $display("PASS: PE Control register access");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: PE Control register access");
        end
        total_count = total_count + 1;
        
        // Test 3: Write to DMA registers
        $display("\n--- Test 3: Write DMA registers ---");
        apb_write(32'h20, 32'hA0000000);  // DMA SRC
        apb_write(32'h24, 32'hB0000000);  // DMA DST
        apb_write(32'h28, 32'h00001000);  // DMA SIZE (4KB)
        apb_write(32'h30, 32'h00000001);  // DMA START
        
        // Test 4: Read DMA status
        $display("\n--- Test 4: Read DMA status ---");
        apb_read(32'h34, pwdata);  // DMA STATUS
        $display("DMA Status: 0x%08h", pwdata);
        
        // Test 5: Read PE Status
        $display("\n--- Test 5: Read PE Status ---");
        apb_read(32'h04, pwdata);
        $display("PE Status: 0x%08h", pwdata);
        
        // Test 6: Write Cache Control
        $display("\n--- Test 6: Write Cache Control ---");
        apb_write(32'h40, 32'h00000001);  // Enable cache
        apb_read(32'h40, pwdata);
        $display("Cache Control: 0x%08h", pwdata);
        if (pwdata == 32'h00000001) begin
            $display("PASS: Cache control register access");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Cache control register access");
        end
        total_count = total_count + 1;
        
        #100;
        
        $display("\n========================================");
        $display("FINAL TEST RESULTS");
        $display("========================================");
        $display("Total:  %0d tests", total_count);
        $display("Passed: %0d tests", pass_count);
        $display("Failed: %0d tests", total_count - pass_count);
        $display("Pass Rate: %0d%%", (total_count > 0) ? (pass_count * 100 / total_count) : 0);
        $display("========================================");
        
        if (pass_count == total_count) begin
            $display("SUCCESS: All tests passed!");
        end else begin
            $display("PARTIAL SUCCESS: Some tests passed");
        end
        
        #100;
        $finish;
    end
    
endmodule
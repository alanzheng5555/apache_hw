//===================================================================
// Simple APB Slave Test - Corrected Timing
//===================================================================
`timescale 1ns/1ps

module tb_apb_slave;
    reg clk, rst_n;
    reg [7:0] paddr;
    reg [31:0] pwdata;
    reg pwrite, psel, penable;
    wire [31:0] prdata;
    wire pready, pslverr;
    
    // Dummy signals for APB slave
    wire [31:0] pe_status = 0;
    wire [31:0] intr_raw = 0;
    wire [31:0] intr_code = 0;
    wire dma_done = 0;
    wire dma_error = 0;
    wire dma_busy = 0;
    wire [31:0] cache_status = 0;
    
    // Outputs
    wire [31:0] pe_ctrl;
    wire [31:0] dma_src_addr, dma_dst_addr, dma_size, dma_stride;
    wire [2:0] dma_mode;
    wire dma_start;
    wire [31:0] cache_ctrl;
    wire [31:0] intr_enable, intr_clear;
    
    pe_apb_slave u_apb (
        .clk(clk),
        .rst_n(rst_n),
        .paddr(paddr),
        .pwdata(pwdata),
        .pwrite(pwrite),
        .psel(psel),
        .penable(penable),
        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr),
        .pe_ctrl(pe_ctrl),
        .pe_status(pe_status),
        .dma_src_addr(dma_src_addr),
        .dma_dst_addr(dma_dst_addr),
        .dma_size(dma_size),
        .dma_stride(dma_stride),
        .dma_mode(dma_mode),
        .dma_start(dma_start),
        .dma_done(dma_done),
        .dma_error(dma_error),
        .dma_busy(dma_busy),
        .cache_ctrl(cache_ctrl),
        .cache_status(cache_status),
        .intr_enable(intr_enable),
        .intr_raw(intr_raw),
        .intr_clear(intr_clear),
        .intr_code(intr_code)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        paddr = 0; pwdata = 0; pwrite = 0; psel = 0; penable = 0;
        
        #100;
        rst_n = 1;
        #50;
        
        $display("APB Slave Test");
        $display("==============");
        
        // Write to register 0x00
        @(posedge clk);
        paddr = 8'h00;
        pwdata = 32'hDEADBEEF;
        pwrite = 1;
        psel = 1;
        penable = 0;  // Not enabled yet
        
        @(posedge clk);
        penable = 1;  // Enable transaction
        wait (pready);  // Wait for ready
        $display("Wrote 0xDEADBEEF to 0x00");
        
        // Hold for one cycle after transaction completes
        psel = 0;
        pwrite = 0;
        penable = 0;
        #20;
        
        // Read from register 0x00
        @(posedge clk);
        paddr = 8'h00;
        pwrite = 0;
        pwdata = 0;
        psel = 1;
        penable = 0;
        
        @(posedge clk);
        penable = 1;  // Enable transaction
        wait (pready);  // Wait for ready
        $display("Read from 0x00: 0x%08h", prdata);
        
        psel = 0;
        penable = 0;
        
        #50;
        $finish;
    end
endmodule
//===================================================================
// APB Slave Internal Register Test
//===================================================================
`timescale 1ns/1ps

module tb_apb_internal;
    reg clk, rst_n;
    reg [7:0] paddr;
    reg [31:0] pwdata;
    reg pwrite, psel, penable;
    
    // Direct access to internal register for debugging
    wire [31:0] reg_pe_ctrl_out;
    
    // APB signals
    wire [31:0] prdata;
    wire pready, pslverr;
    
    // Dummy signals
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
    
    // Instantiate APB slave
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
    
    // Monitor internal register
    assign reg_pe_ctrl_out = u_apb.reg_pe_ctrl;
    
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
        
        $display("APB Internal Register Test");
        $display("==========================");
        
        $display("Initial reg_pe_ctrl: 0x%08h", reg_pe_ctrl_out);
        $display("Initial prdata (read from 0x00): 0x%08h", prdata);
        
        // Write to register 0x00
        @(posedge clk);
        paddr = 8'h00;
        pwdata = 32'hDEADBEEF;
        pwrite = 1;
        psel = 1;
        penable = 1;
        
        @(posedge clk);
        #5;  // Wait a bit after clock
        
        $display("After write attempt - reg_pe_ctrl: 0x%08h", reg_pe_ctrl_out);
        $display("After write attempt - prdata: 0x%08h", prdata);
        
        // Check if the condition was met
        $display("psel: %b, penable: %b, pwrite: %b", psel, penable, pwrite);
        $display("pready: %b", pready);
        
        #20;
        $finish;
    end
endmodule
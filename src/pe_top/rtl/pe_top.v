//===================================================================
// PE Top - Complete Processing Element Top-Level Module
//===================================================================
`timescale 1ns/1ps

module pe_top #(
    parameter SRAM_SIZE = 4096,
    parameter CACHE_EN  = 1
) (
    input  clk,
    input  rst_n,
    
    //----------------------------------------------------------------
    // AXI4 Master Interface (to external memory) - Simplified
    //----------------------------------------------------------------
    output [31:0]  m_awaddr,
    output [7:0]   m_awlen,
    output [2:0]   m_awsize,
    output [1:0]   m_awburst,
    output        m_awvalid,
    input         m_awready,
    
    output [31:0]  m_wdata,
    output [3:0]   m_wstrb,
    output        m_wlast,
    output        m_wvalid,
    input         m_wready,
    
    input  [1:0]   m_bresp,
    input         m_bvalid,
    output        m_bready,
    
    output [31:0]  m_araddr,
    output [7:0]   m_arlen,
    output [2:0]   m_arsize,
    output [1:0]   m_arburst,
    output        m_arvalid,
    input         m_arready,
    
    input  [31:0]  m_rdata,
    input  [1:0]   m_rresp,
    input         m_rlast,
    input         m_rvalid,
    output        m_rready,
    
    //----------------------------------------------------------------
    // APB Configuration Interface
    //----------------------------------------------------------------
    input  [31:0]  paddr,
    input  [31:0]  pwdata,
    input         pwrite,
    input         psel,
    input         penable,
    output [31:0] prdata,
    output        pready,
    output        pslverr,
    
    //----------------------------------------------------------------
    // Interrupt Output
    //----------------------------------------------------------------
    output        intr_valid,
    output [31:0] intr_code
);
    //----------------------------------------------------------------
    // Parameters
    //----------------------------------------------------------------
    localparam ADR_W = 32;
    
    //----------------------------------------------------------------
    // PE Core Signals
    //----------------------------------------------------------------
    wire [31:0]  pe_opcode;
    wire [31:0]  pe_op1;
    wire [31:0]  pe_op2;
    wire [31:0]  pe_op3;
    wire         pe_valid_in;
    wire [31:0]  pe_result_out;
    wire         pe_result_valid;
    
    //----------------------------------------------------------------
    // Register File Signals
    //----------------------------------------------------------------
    wire [4:0]   rf_rd_addr1 = pe_opcode[19:15];
    wire [4:0]   rf_rd_addr2 = pe_opcode[14:10];
    wire [31:0]  rf_rd_data1;
    wire [31:0]  rf_rd_data2;
    wire [31:0]  rf_wr_data;
    wire [4:0]   rf_wr_addr;
    wire         rf_wr_en;
    
    //----------------------------------------------------------------
    // Cache/SRAM Signals
    //----------------------------------------------------------------
    wire [31:0]  cache_addr;
    wire [31:0]  cache_wdata;
    wire [3:0]   cache_wstrb;
    wire         cache_wr_en;
    wire         cache_rd_en;
    wire [31:0]  cache_rdata;
    wire         cache_ready;
    wire         cache_hit;
    
    //----------------------------------------------------------------
    // DMA Signals
    //----------------------------------------------------------------
    wire [31:0]  dma_src_addr;
    wire [31:0]  dma_dst_addr;
    wire [31:0]  dma_size;
    wire [31:0]  dma_stride;
    wire [2:0]   dma_mode;
    wire         dma_start;
    wire         dma_done;
    wire         dma_error;
    wire         dma_busy;
    
    //----------------------------------------------------------------
    // APB Signals
    //----------------------------------------------------------------
    wire [31:0]  apb_pe_ctrl;
    wire [31:0]  apb_pe_status;
    wire [31:0]  apb_intr_enable;
    wire [31:0]  apb_intr_clear;
    wire [31:0]  apb_cache_ctrl;
    wire [31:0]  cache_status;
    wire [31:0]  intr_raw;
    wire [31:0]  intr_code_reg;
    
    //----------------------------------------------------------------
    // Control Logic
    //----------------------------------------------------------------
    reg [31:0] operand1, operand2, operand3;
    reg [31:0] result_reg;
    reg [4:0]  dest_reg;
    reg        result_valid_reg;
    reg        pe_busy;
    
    //----------------------------------------------------------------
    // PE Status
    //----------------------------------------------------------------
    assign apb_pe_status = {30'd0, result_valid_reg, pe_busy};
    
    //----------------------------------------------------------------
    // Interrupt
    //----------------------------------------------------------------
    assign intr_raw = {31'd0, dma_done};
    assign intr_valid = |(intr_raw & apb_intr_enable);
    assign intr_code = intr_code_reg;
    
    //----------------------------------------------------------------
    // Main PE Control Logic
    //----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 0;
            dest_reg <= 0;
            result_valid_reg <= 0;
            pe_busy <= 0;
        end else begin
            if (pe_result_valid) begin
                result_reg <= pe_result_out;
                result_valid_reg <= 1;
                dest_reg <= pe_opcode[4:0];
                pe_busy <= 0;
            end else if (apb_pe_ctrl[0] && !pe_busy) begin
                // Start new operation
                operand1 <= rf_rd_data1;
                operand2 <= rf_rd_data2;
                operand3 <= 0;  // Use register 0 for third operand
                pe_busy <= 1;
            end else if (result_valid_reg) begin
                // Clear result valid after one cycle
                result_valid_reg <= 0;
            end
        end
    end
    
    //----------------------------------------------------------------
    // Connect PE Core
    //----------------------------------------------------------------
    assign pe_opcode = apb_pe_ctrl[31:0];  // For demo, opcode from ctrl reg
    assign pe_op1    = operand1;
    assign pe_op2    = operand2;
    assign pe_op3    = operand3;
    assign pe_valid_in = apb_pe_ctrl[0] && !pe_busy;
    
    assign rf_wr_data = result_reg;
    assign rf_wr_addr = dest_reg;
    assign rf_wr_en   = result_valid_reg && (dest_reg != 0);
    
    //----------------------------------------------------------------
    // Instantiate PE Core
    //----------------------------------------------------------------
    pe_core_v3 u_pe_core (
        .clk(clk),
        .rst_n(rst_n),
        .opcode(pe_opcode),
        .op1(pe_op1),
        .op2(pe_op2),
        .op3(pe_op3),
        .valid_in(pe_valid_in),
        .result_out(pe_result_out),
        .result_valid(pe_result_valid)
    );
    
    //----------------------------------------------------------------
    // Instantiate Register File
    //----------------------------------------------------------------
    pe_regfile #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(5),
        .NUM_REGS(32)
    ) u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .rd_addr1(rf_rd_addr1),
        .rd_data1(rf_rd_data1),
        .rd_addr2(rf_rd_addr2),
        .rd_data2(rf_rd_data2),
        .wr_addr(rf_wr_addr),
        .wr_data(rf_wr_data),
        .wr_en(rf_wr_en)
    );
    
    //----------------------------------------------------------------
    // Instantiate SRAM
    //----------------------------------------------------------------
    pe_sram #(
        .SIZE(SRAM_SIZE),
        .DATA_W(32),
        .ADR_W($clog2(SRAM_SIZE/4))
    ) u_sram (
        .clk(clk),
        .rst_n(rst_n),
        .addr(cache_addr[$clog2(SRAM_SIZE/4)-1:0]),
        .wdata(cache_wdata),
        .wstrb(cache_wstrb),
        .we(cache_wr_en),
        .en(cache_rd_en || cache_wr_en),
        .rdata(cache_rdata)
    );
    
    //----------------------------------------------------------------
    // Instantiate DMA
    //----------------------------------------------------------------
    pe_dma u_dma (
        .clk(clk),
        .rst_n(rst_n),
        .src_addr(dma_src_addr),
        .dst_addr(dma_dst_addr),
        .size(dma_size),
        .src_stride(dma_stride),
        .dst_stride(dma_stride),
        .mode(dma_mode),
        .start(dma_start),
        .done(dma_done),
        .error(dma_error),
        .busy(dma_busy),
        .cache_addr(cache_addr),
        .cache_wdata(cache_wdata),
        .cache_wstrb(cache_wstrb),
        .cache_wr_en(cache_wr_en),
        .cache_rdata(cache_rdata),
        .cache_rd_en(cache_rd_en),
        .cache_rvalid(1'b1),  // SRAM always ready
        .cache_wready(1'b1)   // SRAM always ready
    );
    
    //----------------------------------------------------------------
    // Instantiate APB Slave
    //----------------------------------------------------------------
    pe_apb_slave #(
        .ADDR_W(8)
    ) u_apb (
        .clk(clk),
        .rst_n(rst_n),
        .paddr(paddr[7:0]),
        .pwdata(pwdata),
        .pwrite(pwrite),
        .psel(psel),
        .penable(penable),
        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr),
        .pe_ctrl(apb_pe_ctrl),
        .pe_status(apb_pe_status),
        .intr_enable(apb_intr_enable),
        .intr_raw(intr_raw),
        .intr_clear(apb_intr_clear),
        .intr_code(intr_code_reg),
        .dma_src_addr(dma_src_addr),
        .dma_dst_addr(dma_dst_addr),
        .dma_size(dma_size),
        .dma_stride(dma_stride),
        .dma_mode(dma_mode),
        .dma_start(dma_start),
        .dma_done(dma_done),
        .dma_error(dma_error),
        .dma_busy(dma_busy),
        .cache_ctrl(apb_cache_ctrl),
        .cache_status(cache_status)
    );
    
    //----------------------------------------------------------------
    // Cache signals (simple SRAM connection)
    //----------------------------------------------------------------
    assign cache_ready = 1;
    assign cache_hit = 1;
    assign cache_status = 0;
    
    //----------------------------------------------------------------
    // AXI connections (connect to cache/SRAM)
    //----------------------------------------------------------------
    assign m_awaddr = cache_addr;
    assign m_awlen = 0;
    assign m_awsize = 0;
    assign m_awburst = 0;
    assign m_awvalid = cache_wr_en;
    assign m_wdata = cache_wdata;
    assign m_wstrb = cache_wstrb;
    assign m_wlast = 1;
    assign m_wvalid = cache_wr_en;
    assign m_araddr = cache_addr;
    assign m_arlen = 0;
    assign m_arsize = 0;
    assign m_arburst = 0;
    assign m_arvalid = cache_rd_en;
    assign m_bready = 1;
    assign m_rready = 1;
    
    // Connect AXI response signals to inputs (these are driven by external master)
    assign cache_rd_en = m_arvalid && m_arready;
    assign cache_wr_en = m_awvalid && m_awready && m_wvalid && m_wready;
    assign cache_wdata = m_wdata;
    assign cache_addr = m_araddr;
    
endmodule
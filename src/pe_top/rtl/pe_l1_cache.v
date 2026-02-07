//===================================================================
// PE L1 Cache - Direct-mapped write-back cache
//===================================================================
`timescale 1ns/1ps

module pe_l1_cache #(
    parameter SIZE        = 4096,      // Cache size in bytes
    parameter LINE_SIZE   = 64,         // Cache line size
    parameter ADR_W       = 32,         // Address width
    parameter VALID_W     = 1,
    parameter TAG_W       = ADR_W - $clog2(SIZE) - $clog2(LINE_SIZE),
    parameter INDEX_W     = $clog2(SIZE / LINE_SIZE),
    parameter OFFSET_W    = $clog2(LINE_SIZE)
) (
    input  clk,
    input  rst_n,
    
    // Cache Interface
    input  [ADR_W-1:0]  cpu_addr,
    input               cpu_read,
    input               cpu_write,
    input  [31:0]       cpu_wdata,
    input  [3:0]        cpu_wstrb,
    output [31:0]       cpu_rdata,
    output              cpu_ready,
    output              cpu_hit,
    
    // AXI Interface (for cache miss handling)
    output [ADR_W-1:0]  axi_awaddr,
    output [7:0]        axi_awlen,
    output              axi_awvalid,
    input               axi_awready,
    
    output [ADR_W-1:0]  axi_araddr,
    output [7:0]        axi_arlen,
    output              axi_arvalid,
    input               axi_arready,
    
    input  [31:0]       axi_rdata,
    input               axi_rvalid,
    input               axi_rlast,
    input               axi_rresp,
    output              axi_rready,
    
    output [31:0]       axi_wdata,
    output [3:0]        axi_wstrb,
    output              axi_wlast,
    output              axi_wvalid,
    input               axi_wready,
    
    input  [1:0]        axi_bresp,
    input               axi_bvalid,
    output              axi_bready
);
    //----------------------------------------------------------------
    // Parameters
    //----------------------------------------------------------------
    localparam BYTES_PER_LINE = LINE_SIZE;
    localparam WORDS_PER_LINE = LINE_SIZE / 4;
    
    //----------------------------------------------------------------
    // Cache tag array
    //----------------------------------------------------------------
    reg [TAG_W-1:0]   tag_ram [0:(1<<INDEX_W)-1];
    reg               valid_ram [0:(1<<INDEX_W)-1];
    reg               dirty_ram [0:(1<<INDEX_W)-1];
    
    //----------------------------------------------------------------
    // Data array
    //----------------------------------------------------------------
    reg [31:0] data_ram [0:(1<<INDEX_W)*WORDS_PER_LINE-1];
    
    //----------------------------------------------------------------
    // Address decomposition
    //----------------------------------------------------------------
    wire [TAG_W-1:0]    addr_tag   = cpu_addr[ADR_W-1:ADR_W-TAG_W];
    wire [INDEX_W-1:0]  addr_index = cpu_addr[INDEX_W+OFFSET_W-1:OFFSET_W];
    wire [OFFSET_W-1:0] addr_offset = cpu_addr[OFFSET_W-1:2];
    
    //----------------------------------------------------------------
    // Tag comparison
    //----------------------------------------------------------------
    wire tag_match = valid_ram[addr_index] && 
                     (tag_ram[addr_index] == addr_tag);
    
    wire cache_hit_reg = tag_match;
    assign cpu_hit = cache_hit_reg;
    
    //----------------------------------------------------------------
    // State machine
    //----------------------------------------------------------------
    typedef enum {
        IDLE,
        READ_MISS,
        READ_LINE,
        WRITE_MISS,
        WRITE_ALLOCATE,
        WRITE_LINE,
        WRITE_BACK
    } state_t;
    
    state_t state, next_state;
    reg [INDEX_W-1:0] miss_index;
    reg [TAG_W-1:0]   miss_tag;
    reg [7:0]         word_counter;
    reg               busy;
    
    //----------------------------------------------------------------
    // Output signals
    //----------------------------------------------------------------
    assign cpu_ready = (state == IDLE) && busy;
    assign cpu_rdata = data_ram[addr_index * WORDS_PER_LINE + addr_offset];
    
    //----------------------------------------------------------------
    // AXI read signals
    //----------------------------------------------------------------
    assign axi_araddr  = {miss_tag, addr_index, {OFFSET_W{1'b0}}};
    assign axi_arlen   = WORDS_PER_LINE - 1;
    assign axi_arsize = 3'b010;  // 4 bytes
    assign axi_arburst = 2'b01;  // INCR
    assign axi_arvalid = (state == READ_MISS);
    assign axi_rready  = (state == READ_LINE);
    
    //----------------------------------------------------------------
    // AXI write signals
    //----------------------------------------------------------------
    assign axi_awaddr  = {miss_tag, miss_index, {OFFSET_W{1'b0}}};
    assign axi_awlen   = WORDS_PER_LINE - 1;
    assign axi_awsize = 3'b010;
    assign axi_awburst = 2'b01;
    assign axi_awvalid = (state == WRITE_BACK);
    assign axi_wlast   = (word_counter == WORDS_PER_LINE - 1);
    assign axi_wvalid  = (state == WRITE_LINE);
    assign axi_bready  = (state == WRITE_BACK) && axi_bvalid;
    
    //----------------------------------------------------------------
    // State machine - current state
    //----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            word_counter <= 0;
            miss_index <= 0;
            miss_tag <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                READ_MISS: begin
                    if (axi_arready) begin
                        next_state <= READ_LINE;
                        word_counter <= 0;
                    end
                end
                
                READ_LINE: begin
                    if (axi_rvalid && axi_rlast) begin
                        next_state <= IDLE;
                        busy <= 0;
                    end
                    if (axi_rvalid) begin
                        data_ram[addr_index * WORDS_PER_LINE + word_counter] <= axi_rdata;
                        word_counter <= word_counter + 1;
                    end
                end
                
                WRITE_BACK: begin
                    if (axi_awready) begin
                        word_counter <= 0;
                        next_state <= WRITE_LINE;
                    end
                end
                
                WRITE_LINE: begin
                    if (axi_wvalid && axi_wready) begin
                        if (word_counter == WORDS_PER_LINE - 1)
                            next_state <= WRITE_BACK;
                        else
                            word_counter <= word_counter + 1;
                    end
                end
            endcase
        end
    end
    
    //----------------------------------------------------------------
    // Tag RAM write
    //----------------------------------------------------------------
    always @(posedge clk) begin
        if (tag_match && cpu_write && state == IDLE) begin
            dirty_ram[addr_index] <= 1'b1;
            data_ram[addr_index * WORDS_PER_LINE + addr_offset] <= cpu_wdata;
        end
    end
    
    //----------------------------------------------------------------
    // Initialization
    //----------------------------------------------------------------
    integer i;
    initial begin
        for (i = 0; i < (1<<INDEX_W); i = i + 1) begin
            tag_ram[i] = 0;
            valid_ram[i] = 0;
            dirty_ram[i] = 0;
        end
    end
    
endmodule
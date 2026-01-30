// Local Cache Module for PE Core
// Implements L1 cache as specified in the architecture

`timescale 1ns/1ps

module local_cache #(
    parameter CACHE_SIZE = 32768, // 32KB
    parameter LINE_SIZE = 64,     // 64 bytes per line
    parameter ASSOCIATIVITY = 4,  // 4-way set associative
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 256    // 256-bit wide for vector access
)(
    input  wire                    clk,
    input  wire                    rst_n,
    
    // CPU-side interface
    input  wire                    req_valid,
    input  wire                    req_write,
    input  wire [ADDR_WIDTH-1:0]  req_addr,
    input  wire [DATA_WIDTH-1:0]  req_wdata,
    output wire [DATA_WIDTH-1:0]  resp_rdata,
    output wire                    resp_valid,
    
    // Memory-side interface
    output wire                    mem_req,
    output wire                   mem_write,
    output wire [ADDR_WIDTH-1:0] mem_addr,
    output wire [DATA_WIDTH-1:0] mem_wdata,
    input  wire [DATA_WIDTH-1:0] mem_rdata,
    input  wire                   mem_resp_valid
);

    // Cache parameters
    localparam OFFSET_BITS = $clog2(LINE_SIZE >> ($clog2(DATA_WIDTH/8)));
    localparam INDEX_BITS = $clog2(CACHE_SIZE / (LINE_SIZE * ASSOCIATIVITY));
    localparam TAG_BITS = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;
    
    // Address fields
    wire [TAG_BITS-1:0]    req_tag;
    wire [INDEX_BITS-1:0]  req_index;
    wire [OFFSET_BITS-1:0] req_offset;
    
    assign req_tag = req_addr[ADDR_WIDTH-1:ADDR_WIDTH-TAG_BITS];
    assign req_index = req_addr[ADDR_WIDTH-TAG_BITS-1:OFFSET_BITS];
    assign req_offset = req_addr[OFFSET_BITS-1:0];
    
    // Cache data and tags
    reg [DATA_WIDTH-1:0] cache_data [0:ASSOCIATIVITY-1] [0:(CACHE_SIZE/LINE_SIZE)-1];
    reg [TAG_BITS-1:0]   cache_tags [0:ASSOCIATIVITY-1] [0:(CACHE_SIZE/LINE_SIZE)-1];
    reg                  cache_valid [0:ASSOCIATIVITY-1] [0:(CACHE_SIZE/LINE_SIZE)-1];
    reg [ASSOCIATIVITY-1:0] lru_bits [0:(CACHE_SIZE/LINE_SIZE)-1]; // LRU replacement
    
    // Internal signals
    reg [ASSOCIATIVITY-1:0] hit_way;
    reg cache_hit;
    reg [$clog2(ASSOCIATIVITY)-1:0] victim_way;
    
    // Hit detection
    integer i;
    always @(*) begin
        hit_way = 0;
        cache_hit = 0;
        victim_way = 0;
        
        for (i = 0; i < ASSOCIATIVITY; i = i + 1) begin
            if (cache_valid[i][req_index] && (cache_tags[i][req_index] == req_tag)) begin
                hit_way[i] = 1;
                cache_hit = 1;
            end
        end
        
        // Find LRU way for replacement
        victim_way = 0;
        if (lru_bits[req_index][0]) victim_way = 0;
        else if (lru_bits[req_index][1]) victim_way = 1;
        else if (lru_bits[req_index][2]) victim_way = 2;
        else victim_way = 3;
    end
    
    // Response logic
    reg [DATA_WIDTH-1:0] cache_rdata;
    reg cache_resp_valid;
    
    always @(*) begin
        if (cache_hit) begin
            for (i = 0; i < ASSOCIATIVITY; i = i + 1) begin
                if (hit_way[i])
                    cache_rdata = cache_data[i][req_index];
            end
        end else begin
            cache_rdata = mem_rdata;
        end
    end
    
    assign resp_rdata = cache_rdata;
    assign resp_valid = cache_resp_valid;
    
    // Memory request logic
    reg pending_miss;
    reg [ADDR_WIDTH-1:0] miss_addr;
    
    assign mem_req = pending_miss && !mem_resp_valid;
    assign mem_write = 1'b0; // Simplified, only read for this example
    wire [ADDR_WIDTH-1:0] mem_addr_internal;
    reg [ADDR_WIDTH-1:0] temp_addr1, temp_addr2;
    always @(*) begin
        temp_addr1 = {cache_tags[victim_way][miss_addr[ADDR_WIDTH-TAG_BITS-1:OFFSET_BITS]], 
                      miss_addr[ADDR_WIDTH-TAG_BITS-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
        temp_addr2 = {req_tag, req_index, {OFFSET_BITS{1'b0}}};
        mem_addr_internal = pending_miss ? temp_addr1 : temp_addr2;
    end
    assign mem_addr = mem_addr_internal;
    assign mem_wdata = req_wdata;
    
    // Cache controller
    reg [2:0] current_state, next_state;
    
    // State definitions
    localparam STATE_IDLE = 3'd0;
    localparam STATE_CHECK_HIT = 3'd1;
    localparam STATE_MISS_PENDING = 3'd2;
    localparam STATE_WRITE_BACK = 3'd3;
    localparam STATE_FILL_CACHE = 3'd4;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
            pending_miss <= 1'b0;
            cache_resp_valid <= 1'b0;
            // Initialize cache
            for (integer j = 0; j < ASSOCIATIVITY; j = j + 1) begin
                for (integer k = 0; k < (CACHE_SIZE/LINE_SIZE); k = k + 1) begin
                    cache_valid[j][k] <= 1'b0;
                end
            end
        end else begin
            current_state <= next_state;
            
            case (current_state)
                STATE_IDLE: begin
                    if (req_valid) begin
                        next_state <= STATE_CHECK_HIT;
                    end
                end
                
                STATE_CHECK_HIT: begin
                    if (cache_hit) begin
                        cache_resp_valid <= 1'b1;
                        // Update LRU
                        lru_bits[req_index][victim_way] <= ~lru_bits[req_index][victim_way];
                    end else begin
                        pending_miss <= 1'b1;
                        miss_addr <= req_addr;
                        next_state <= STATE_MISS_PENDING;
                    end
                end
                
                STATE_MISS_PENDING: begin
                    if (mem_resp_valid) begin
                        // Fill cache line
                        cache_data[victim_way][req_index] <= mem_rdata;
                        cache_tags[victim_way][req_index] <= req_tag;
                        cache_valid[victim_way][req_index] <= 1'b1;
                        cache_resp_valid <= 1'b1;
                        pending_miss <= 1'b0;
                        next_state <= STATE_IDLE;
                    end
                end
            endcase
            
            // Clear response valid after one cycle
            if (cache_resp_valid)
                cache_resp_valid <= 1'b0;
        end
    end

endmodule
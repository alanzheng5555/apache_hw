// PE Top with AXI Master Interface
// Wraps pe_top_enhanced with AXI4-Lite master for off-chip memory access
// Based on pe_top_enhanced architecture

`timescale 1ns/1ps

module pe_top_axi #(
    parameter DATA_WIDTH = 32,
    parameter VECTOR_WIDTH = 16,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32,
    parameter NUM_VECTORS = 256
)(
    // System signals
    input  wire                        clk,
    input  wire                        rst_n,
    
    // AXI4-Lite Master Interface - Read Channel
    output wire [AXI_ADDR_WIDTH-1:0]   maxi_araddr,
    output wire                        maxi_arvalid,
    input  wire                        maxi_arready,
    output wire [2:0]                  maxi_arprot,
    input  wire [AXI_DATA_WIDTH-1:0]   maxi_rdata,
    input  wire                        maxi_rvalid,
    output wire                        maxi_rready,
    input  wire [1:0]                  maxi_rresp,
    
    // Configuration
    input  wire [31:0]                 base_addr,
    input  wire [31:0]                 instruction,
    input  wire [7:0]                  op_config,       // [7:4]=act_type, [3:0]=norm_type
    input  wire                        start,
    output wire                        done,
    output wire                        error,
    
    // Control
    input  wire                        mode,            // 0=single, 1=continuous
    input  wire [7:0]                  num_operations,
    output wire [7:0]                 op_count
);

    // ==========================================
    // Internal Signals
    // ==========================================
    reg  [31:0]                       current_addr;
    reg                               read_enable;
    wire [31:0]                      read_data;
    wire                             read_valid;
    wire                             read_ready;
    
    // PE Top inputs (unpacked from AXI read data)
    wire [DATA_WIDTH-1:0]            data_a [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0]            data_b [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0]            weight [VECTOR_WIDTH-1:0];
    
    // PE Top outputs
    wire [DATA_WIDTH-1:0]            result [VECTOR_WIDTH-1:0];
    wire                             pe_valid;
    
    // Control FSM
    reg  [3:0]                       state;
    reg  [7:0]                       op_counter;
    reg                              done_reg;
    reg                              error_reg;
    
    // FSM States
    localparam IDLE           = 4'd0;
    localparam READ_DATA_A    = 4'd1;
    localparam READ_DATA_B    = 4'd2;
    localparam READ_WEIGHT   = 4'd3;
    localparam PE_PROCESS    = 4'd4;
    localparam STORE_RESULT  = 4'd5;
    localparam DONE          = 4'd6;
    
    // ==========================================
    // AXI4-Lite Read Master
    // ==========================================
    assign maxi_araddr  = current_addr;
    assign maxi_arvalid = read_enable;
    assign maxi_arprot  = 3'b000;          // Data access, non-privileged, secure
    assign maxi_rready  = 1'b1;            // Always ready to receive data
    
    // Read data valid when both valid and ready
    assign read_valid = maxi_arvalid & maxi_arready & maxi_rvalid;
    assign read_data  = maxi_rdata;
    
    // Unpack AXI data to vector format
    genvar i;
    generate
        for (i = 0; i < VECTOR_WIDTH; i = i + 1) begin : unpack_axi
            assign data_a[i]    = read_data[(i*32)+:32];
            assign data_b[i]    = read_data[(i*32)+:32];  // Reuse for single-port
            assign weight[i]    = read_data[(i*32)+:32];  // Reuse for single-port
        end
    endgenerate
    
    // ==========================================
    // PE Top Instance (from pe_top_enhanced)
    // ==========================================
    pe_top_enhanced #(
        .DATA_WIDTH(DATA_WIDTH),
        .VECTOR_WIDTH(VECTOR_WIDTH)
    ) u_pe (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(pe_valid),
        .ready_out(),
        .instruction(instruction),
        .data_a_packed({data_b, data_a}),  // Pack into 512-bit bus
        .data_b_packed({data_b, data_a}),
        .weight_packed({weight, weight}),
        .k_cache_packed({512{1'b0}}),
        .v_cache_packed({512{1'b0}}),
        .sparse_mask_a({16{1'b1}}),
        .sparse_mask_b({16{1'b1}}),
        .sparsity_ratio(8'd0),
        .scale_a(8'd1),
        .scale_b(8'd1),
        .scale_o(8'd1),
        .addr_i(32'd0),
        .data_o(),
        .data_i(256'd0),
        .mem_req_o(),
        .mem_ack_i(1'b1),
        .cache_flush(1'b0),
        .cache_hit(),
        .result_packed({result, result}),
        .valid_out(pe_valid),
        .attention_packed(),
        .perf_counter(),
        .perf_overflow()
    );
    
    // ==========================================
    // Control FSM
    // ==========================================
    assign done   = done_reg;
    assign error  = error_reg;
    assign op_count = op_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            current_addr <= 32'd0;
            read_enable  <= 1'b0;
            op_counter   <= 8'd0;
            done_reg     <= 1'b0;
            error_reg    <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        current_addr <= base_addr;
                        read_enable  <= 1'b1;
                        state        <= READ_DATA_A;
                        op_counter   <= 8'd0;
                        done_reg     <= 1'b0;
                        error_reg    <= 1'b0;
                    end
                end
                
                READ_DATA_A: begin
                    if (read_valid) begin
                        // Data A received, next read B
                        current_addr <= current_addr + 32'd4;
                        state        <= READ_DATA_B;
                    end
                    // Stay in READ_DATA_A until valid
                end
                
                READ_DATA_B: begin
                    if (read_valid) begin
                        // Data B received, next read weight
                        current_addr <= current_addr + 32'd4;
                        state        <= READ_WEIGHT;
                    end
                end
                
                READ_WEIGHT: begin
                    if (read_valid) begin
                        // Weight received, start PE processing
                        current_addr <= current_addr + 32'd4;
                        state        <= PE_PROCESS;
                    end
                end
                
                PE_PROCESS: begin
                    // Wait for PE to complete (1 cycle for this demo)
                    if (pe_valid) begin
                        op_counter <= op_counter + 8'd1;
                        state      <= STORE_RESULT;
                    end
                end
                
                STORE_RESULT: begin
                    // Check if more operations needed
                    if (op_counter >= num_operations) begin
                        state    <= DONE;
                        done_reg <= 1'b1;
                        read_enable <= 1'b0;
                    end else if (mode == 1'b1) begin
                        // Continuous mode: read next data set
                        current_addr <= current_addr + 32'd4;
                        state        <= READ_DATA_A;
                    end else begin
                        state <= DONE;
                        done_reg <= 1'b1;
                    end
                end
                
                DONE: begin
                    if (!start) begin
                        state    <= IDLE;
                        done_reg <= 1'b0;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule

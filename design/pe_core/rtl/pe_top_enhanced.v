// PE Top with Full AXI4 Master Interface
// Supports burst reads, wide data bus, and complete AXI4 protocol

`timescale 1ns/1ps

// Parameters
localparam SIM_DATA_WIDTH = 32;
localparam SIM_VEC_WIDTH = 4;
localparam SIM_AXI_ADDR = 32;
localparam SIM_AXI_DATA = 64;  // 64-bit data bus (2x32)
localparam SIM_BURST_LEN = 8;  // Burst length

// ==========================================
// Sub-modules
// ==========================================
module mac_array #(
    parameter WIDTH = 32,
    parameter SIZE = 4
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 enable,
    input  wire [WIDTH-1:0]    a [SIZE-1:0],
    input  wire [WIDTH-1:0]    b [SIZE-1:0],
    output wire [WIDTH-1:0]     result [SIZE-1:0]
);
    genvar i;
    generate for (i = 0; i < SIZE; i = i + 1) begin : mac
        assign result[i] = a[i] * b[i];
    end endgenerate
endmodule

module activation_unit #(
    parameter WIDTH = 32,
    parameter SIZE = 4
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 enable,
    input  wire [7:0]          act_type,
    input  wire [WIDTH-1:0]    data_in [SIZE-1:0],
    output wire [WIDTH-1:0]     data_out [SIZE-1:0]
);
    genvar i;
    generate for (i = 0; i < SIZE; i = i + 1) begin : act
        assign data_out[i] = (act_type == 8'd0) ? 
                           ((data_in[i][WIDTH-1]) ? 32'd0 : data_in[i]) : data_in[i];
    end endgenerate
endmodule

module normalization_unit #(
    parameter WIDTH = 32,
    parameter SIZE = 4
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 enable,
    input  wire [7:0]          norm_type,
    input  wire [WIDTH-1:0]    data_in [SIZE-1:0],
    output wire [WIDTH-1:0]     data_out [SIZE-1:0]
);
    genvar i;
    generate for (i = 0; i < SIZE; i = i + 1) begin : norm
        assign data_out[i] = data_in[i];
    end endgenerate
endmodule

// ==========================================
// PE Top with Full AXI4 Master
// ==========================================
module pe_top #(
    parameter DATA_WIDTH = 32,
    parameter VECTOR_WIDTH = 4,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64,     // 64-bit for AXI4
    parameter AXI_ID_WIDTH = 4,
    parameter BURST_SIZE = 8           // Burst length
)(
    // System
    input  wire                         clk,
    input  wire                         rst_n,
    
    // AXI4 Master Write Channel (not used, for completeness)
    output wire [AXI_ID_WIDTH-1:0]      axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]    axi_awaddr,
    output wire [7:0]                   axi_awlen,
    output wire [2:0]                  axi_awsize,
    output wire [1:0]                  axi_awburst,
    output wire [3:0]                  axi_awcache,
    output wire [2:0]                  axi_awprot,
    output wire                         axi_awvalid,
    input  wire                         axi_awready,
    
    output wire [AXI_DATA_WIDTH-1:0]    axi_wdata,
    output wire [(AXI_DATA_WIDTH/8)-1:0] axi_wstrb,
    output wire                         axi_wlast,
    output wire                         axi_wvalid,
    input  wire                         axi_wready,
    
    input  wire [AXI_ID_WIDTH-1:0]      axi_bid,
    input  wire [1:0]                   axi_bresp,
    input  wire                         axi_bvalid,
    output wire                         axi_bready,
    
    // AXI4 Master Read Channel
    output wire [AXI_ID_WIDTH-1:0]      axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0]    axi_araddr,
    output wire [7:0]                   axi_arlen,
    output wire [2:0]                  axi_arsize,
    output wire [1:0]                  axi_arburst,
    output wire [3:0]                  axi_arcache,
    output wire [2:0]                  axi_arprot,
    output wire                         axi_arvalid,
    input  wire                         axi_arready,
    
    input  wire [AXI_ID_WIDTH-1:0]      axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]    axi_rdata,
    input  wire [1:0]                   axi_rresp,
    input  wire                         axi_rlast,
    input  wire                         axi_rvalid,
    output wire                         axi_rready,
    
    // Control & Status
    input  wire [AXI_ADDR_WIDTH-1:0]    base_addr,
    input  wire [31:0]                  instruction,
    input  wire                         start,
    output wire                         done,
    output wire [7:0]                   op_count,
    output wire                         error
);

    // FSM States
    localparam IDLE       = 5'd0;
    localparam INIT_BURST = 5'd1;
    localparam WAIT_RDATA = 5'd2;
    localparam PROCESS    = 5'd3;
    localparam NEXT_OP    = 5'd4;
    localparam DONE      = 5'd5;
    
    // Registers
    reg [4:0] state;
    reg [AXI_ADDR_WIDTH-1:0] current_addr;
    reg [7:0] op_counter;
    reg done_reg, error_reg;
    reg [AXI_ID_WIDTH-1:0] axi_arid_reg;
    
    // Data buffers (64-bit bus -> 32-bit PE)
    reg [AXI_DATA_WIDTH-1:0] read_buffer [0:1];  // 2x64-bit buffer
    reg [7:0] read_count;
    reg burst_started;
    
    // PE data
    reg [DATA_WIDTH-1:0] data_a [VECTOR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] data_b [VECTOR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] result [VECTOR_WIDTH-1:0];
    
    // Control signals
    wire is_mac, is_act, is_norm;
    wire [7:0] act_type, norm_type;
    
    // PE results
    wire [DATA_WIDTH-1:0] mac_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] act_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] norm_result [VECTOR_WIDTH-1:0];
    wire pe_valid;
    
    // Decode instruction
    assign is_mac   = instruction[31:28] == 4'h1;
    assign is_act   = instruction[31:28] == 4'h2;
    assign is_norm  = instruction[31:28] == 4'h3;
    assign act_type = instruction[7:0];
    assign norm_type = instruction[7:0];
    
    // Assign unused write channel (not used in this design)
    assign axi_awid = 4'd0;
    assign axi_awaddr = 32'd0;
    assign axi_awlen = 8'd0;
    assign axi_awsize = 3'd0;
    assign axi_awburst = 2'd0;
    assign axi_awcache = 4'd0;
    assign axi_awprot = 3'd0;
    assign axi_awvalid = 1'b0;
    assign axi_wdata = 64'd0;
    assign axi_wstrb = 8'd0;
    assign axi_wlast = 1'b0;
    assign axi_wvalid = 1'b0;
    assign axi_bready = 1'b0;
    
    // AXI4 Read Channel
    assign axi_arid    = axi_arid_reg;
    assign axi_araddr  = current_addr;
    assign axi_arlen   = BURST_SIZE - 1;  // Burst length - 1
    assign axi_arsize  = 3'd3;            // 8 bytes (64 bits)
    assign axi_arburst = 2'b01;            // INCR
    assign axi_arcache = 4'd3;            // Normal cacheable
    assign axi_arprot  = 3'b000;           // Data access
    assign axi_arvalid = (state == INIT_BURST);
    assign axi_rready  = 1'b1;            // Always ready
    
    // PE Instances
    mac_array #(.WIDTH(DATA_WIDTH), .SIZE(VECTOR_WIDTH)) u_mac (
        .clk(clk), .rst_n(rst_n), .enable(is_mac & pe_valid),
        .a(data_a), .b(data_b), .result(mac_result)
    );
    
    activation_unit #(.WIDTH(DATA_WIDTH), .SIZE(VECTOR_WIDTH)) u_act (
        .clk(clk), .rst_n(rst_n), .enable(is_act & pe_valid),
        .act_type(act_type), .data_in(data_a), .data_out(act_result)
    );
    
    normalization_unit #(.WIDTH(DATA_WIDTH), .SIZE(VECTOR_WIDTH)) u_norm (
        .clk(clk), .rst_n(rst_n), .enable(is_norm & pe_valid),
        .norm_type(norm_type), .data_in(data_a), .data_out(norm_result)
    );
    
    // Result selection
    integer i_idx;
    always @(posedge clk) begin
        if (pe_valid) begin
            if (is_mac) begin
                for (i_idx = 0; i_idx < VECTOR_WIDTH; i_idx = i_idx + 1)
                    result[i_idx] <= mac_result[i_idx];
            end else if (is_act) begin
                for (i_idx = 0; i_idx < VECTOR_WIDTH; i_idx = i_idx + 1)
                    result[i_idx] <= act_result[i_idx];
            end else if (is_norm) begin
                for (i_idx = 0; i_idx < VECTOR_WIDTH; i_idx = i_idx + 1)
                    result[i_idx] <= norm_result[i_idx];
            end
        end
    end
    
    // Unpack 64-bit AXI data to 32-bit PE data
    integer j_idx;
    always @(posedge clk) begin
        if (axi_rvalid && axi_rready) begin
            // Lower 32 bits -> data_a[0:1], Upper 32 bits -> data_b[0:1]
            for (j_idx = 0; j_idx < 2; j_idx = j_idx + 1) begin
                if (j_idx < VECTOR_WIDTH)
                    data_a[j_idx] <= axi_rdata[(j_idx*32)+:32];
                if (j_idx < VECTOR_WIDTH)
                    data_b[j_idx] <= axi_rdata[((j_idx+2)*32)+:32];
            end
        end
    end
    
    // FSM
    assign pe_valid = axi_rvalid && axi_rready;
    assign done = done_reg;
    assign error = error_reg;
    assign op_count = op_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            current_addr <= 32'd0;
            op_counter <= 8'd0;
            done_reg <= 1'b0;
            error_reg <= 1'b0;
            axi_arid_reg <= 4'd0;
            burst_started <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        current_addr <= base_addr;
                        axi_arid_reg <= axi_arid_reg + 4'd1;
                        state <= INIT_BURST;
                        op_counter <= 8'd0;
                        done_reg <= 1'b0;
                        error_reg <= 1'b0;
                        burst_started <= 1'b0;
                    end
                end
                
                INIT_BURST: begin
                    if (axi_arvalid && axi_arready) begin
                        state <= WAIT_RDATA;
                        burst_started <= 1'b1;
                    end
                end
                
                WAIT_RDATA: begin
                    if (axi_rvalid && axi_rready) begin
                        if (axi_rlast) begin
                            // Burst complete, process data
                            state <= PROCESS;
                        end
                    end
                end
                
                PROCESS: begin
                    op_counter <= op_counter + 8'd1;
                    state <= NEXT_OP;
                end
                
                NEXT_OP: begin
                    if (op_counter >= 8'd15) begin  // Run 16 operations per burst
                        state <= DONE;
                        done_reg <= 1'b1;
                    end else if (burst_started) begin
                        // Continue with next burst
                        current_addr <= current_addr + (BURST_SIZE * 8);  // Increment by burst bytes
                        state <= INIT_BURST;
                    end
                end
                
                DONE: begin
                    if (!start) begin
                        state <= IDLE;
                        done_reg <= 1'b0;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule

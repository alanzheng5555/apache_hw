// PE Top with AXI Master Interface - Simplified
// Wraps basic PE operations with AXI4-Lite read interface

`timescale 1ns/1ps

// Simplify VECTOR_WIDTH for simulation
localparam SIM_DATA_WIDTH = 32;
localparam SIM_VECTOR_WIDTH = 4;
localparam SIM_ADDR_WIDTH = 32;
localparam SIM_AXI_WIDTH = 32;

// ==========================================
// MAC Array Module
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
    generate
        for (i = 0; i < SIZE; i = i + 1) begin : mac_gen
            assign result[i] = a[i] * b[i];
        end
    endgenerate
endmodule

// ==========================================
// Activation Unit
// ==========================================
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
    generate
        for (i = 0; i < SIZE; i = i + 1) begin : act_gen
            assign data_out[i] = (act_type == 8'd0) ? 
                                 ((data_in[i][WIDTH-1]) ? 32'd0 : data_in[i]) :  // ReLU
                                 data_in[i];
        end
    endgenerate
endmodule

// ==========================================
// Normalization Unit
// ==========================================
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
    generate
        for (i = 0; i < SIZE; i = i + 1) begin : norm_gen
            assign data_out[i] = data_in[i];
        end
    endgenerate
endmodule

// ==========================================
// PE Top with AXI Master
// ==========================================
module pe_top #(
    parameter DATA_WIDTH = 32,
    parameter VECTOR_WIDTH = 4,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32
)(
    // System
    input  wire                     clk,
    input  wire                     rst_n,
    
    // AXI4-Lite Master (Read)
    output wire [AXI_ADDR_WIDTH-1:0]   axi_araddr,
    output wire                        axi_arvalid,
    input  wire                        axi_arready,
    output wire [2:0]                  axi_arprot,
    input  wire [AXI_DATA_WIDTH-1:0]   axi_rdata,
    input  wire                        axi_rvalid,
    output wire                        axi_rready,
    input  wire [1:0]                  axi_rresp,
    
    // Control
    input  wire [31:0]                base_addr,
    input  wire [31:0]                instruction,
    input  wire                        start,
    output wire                        done,
    output wire [7:0]                 op_count,
    output wire                        error
);

    // FSM States
    localparam IDLE        = 4'd0;
    localparam READ_A      = 4'd1;
    localparam READ_B      = 4'd2;
    localparam PROCESS     = 4'd3;
    localparam NEXT        = 4'd4;
    localparam DONE        = 4'd5;
    
    // Registers
    reg [3:0] state;
    reg [31:0] current_addr;
    reg [31:0] data_a [VECTOR_WIDTH-1:0];
    reg [31:0] data_b [VECTOR_WIDTH-1:0];
    reg [31:0] result [VECTOR_WIDTH-1:0];
    reg [7:0] count;
    reg done_reg;
    reg error_reg;
    
    // Control signals
    wire is_mac, is_act, is_norm;
    wire [7:0] act_type, norm_type;
    
    // PE results
    wire [DATA_WIDTH-1:0] mac_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] act_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] norm_result [VECTOR_WIDTH-1:0];
    
    // Decode instruction
    assign is_mac   = instruction[31:28] == 4'h1;
    assign is_act   = instruction[31:28] == 4'h2;
    assign is_norm  = instruction[31:28] == 4'h3;
    assign act_type = instruction[7:0];
    assign norm_type = instruction[7:0];
    
    // AXI signals
    assign axi_araddr = current_addr;
    assign axi_arvalid = (state == READ_A || state == READ_B);
    assign axi_arprot = 3'b000;
    assign axi_rready = 1'b1;
    
    // Unpack AXI data (simplified - 32-bit at a time)
    genvar i;
    generate
        for (i = 0; i < VECTOR_WIDTH; i = i + 1) begin : unpack
            always @(posedge clk) begin
                if (state == READ_A && axi_rvalid) begin
                    data_a[i] <= axi_rdata;
                end
                if (state == READ_B && axi_rvalid) begin
                    data_b[i] <= axi_rdata;
                end
            end
        end
    endgenerate
    
    // MAC Array
    mac_array #(.WIDTH(DATA_WIDTH), .SIZE(VECTOR_WIDTH)) u_mac (
        .clk(clk),
        .rst_n(rst_n),
        .enable(is_mac & (state == PROCESS)),
        .a(data_a),
        .b(data_b),
        .result(mac_result)
    );
    
    // Activation Unit
    activation_unit #(.WIDTH(DATA_WIDTH), .SIZE(VECTOR_WIDTH)) u_act (
        .clk(clk),
        .rst_n(rst_n),
        .enable(is_act & (state == PROCESS)),
        .act_type(act_type),
        .data_in(data_a),
        .data_out(act_result)
    );
    
    // Normalization Unit
    normalization_unit #(.WIDTH(DATA_WIDTH), .SIZE(VECTOR_WIDTH)) u_norm (
        .clk(clk),
        .rst_n(rst_n),
        .enable(is_norm & (state == PROCESS)),
        .norm_type(norm_type),
        .data_in(data_a),
        .data_out(norm_result)
    );
    
    // Result selection
    integer idx;
    always @(posedge clk) begin
        if (state == PROCESS) begin
            if (is_mac) begin
                for (idx = 0; idx < VECTOR_WIDTH; idx = idx + 1) begin
                    result[idx] <= mac_result[idx];
                end
            end else if (is_act) begin
                for (idx = 0; idx < VECTOR_WIDTH; idx = idx + 1) begin
                    result[idx] <= act_result[idx];
                end
            end else if (is_norm) begin
                for (idx = 0; idx < VECTOR_WIDTH; idx = idx + 1) begin
                    result[idx] <= norm_result[idx];
                end
            end
        end
    end
    
    // FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            current_addr <= 32'd0;
            count       <= 8'd0;
            done_reg    <= 1'b0;
            error_reg   <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        current_addr <= base_addr;
                        count        <= 8'd0;
                        state        <= READ_A;
                        done_reg     <= 1'b0;
                    end
                end
                
                READ_A: begin
                    if (axi_arvalid && axi_arready) begin
                        #1 current_addr <= current_addr + 32'd4;
                        #1 state <= READ_B;
                    end
                end
                
                READ_B: begin
                    if (axi_arvalid && axi_arready) begin
                        #1 current_addr <= current_addr + 32'd4;
                        #1 state <= PROCESS;
                    end
                end
                
                PROCESS: begin
                    count <= count + 8'd1;
                    state <= NEXT;
                end
                
                NEXT: begin
                    if (count >= 8'd10) begin  // Run 10 operations
                        state    <= DONE;
                        done_reg <= 1'b1;
                    end else begin
                        state <= READ_A;  // Continue reading
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
    
    assign done    = done_reg;
    assign error   = error_reg;
    assign op_count = count;
    
endmodule

// Simplified PE Top Module - Processing Element for AI Inference
// Implements the PE core specifications with simplified components for verification

`timescale 1ns/1ps

module pe_top #(
    parameter DATA_WIDTH = 16,  // FP16/BF16 width
    parameter VECTOR_WIDTH = 16, // Reduced for simplification
    parameter MAC_ARRAY_ROWS = 8,
    parameter MAC_ARRAY_COLS = 8
)(
    // Clock and Reset
    input  wire                       clk,
    input  wire                       rst_n,
    
    // Control Interface
    input  wire                       valid_in,
    output wire                       ready_out,
    input  wire [31:0]               instruction,
    
    // Data Inputs
    input  wire [DATA_WIDTH-1:0]     data_a_i [VECTOR_WIDTH-1:0],
    input  wire [DATA_WIDTH-1:0]     data_b_i [VECTOR_WIDTH-1:0],
    input  wire [DATA_WIDTH-1:0]     weight_i [VECTOR_WIDTH-1:0],
    
    // Data Outputs
    output reg [DATA_WIDTH-1:0]      result_o [VECTOR_WIDTH-1:0],
    output wire                       valid_out,
    
    // Memory Interface (simplified)
    input  wire [31:0]               addr_i,
    output wire [255:0]              data_o,
    input  wire [255:0]              data_i,
    output wire                       mem_req_o,
    input  wire                       mem_ack_i
);

    // Internal signals
    wire [DATA_WIDTH-1:0] mac_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] activation_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] norm_result [VECTOR_WIDTH-1:0];
    
    // Instruction decode
    wire is_mac_op, is_activation_op, is_norm_op, is_mem_op;
    assign is_mac_op = instruction[31:28] == 4'h1;
    assign is_activation_op = instruction[31:28] == 4'h2;
    assign is_norm_op = instruction[31:28] == 4'h3;
    assign is_mem_op = instruction[31:28] == 4'h4;
    
    // Internal operation selection
    reg [1:0] operation_mode; // 00=mac, 01=activation, 10=norm, 11=input_passthrough
    always @(*) begin
        if (is_mac_op) operation_mode = 2'b00;
        else if (is_activation_op) operation_mode = 2'b01;
        else if (is_norm_op) operation_mode = 2'b10;
        else operation_mode = 2'b11; // passthrough
    end
    
    // MAC Array
    mac_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_ROWS(MAC_ARRAY_ROWS),
        .ARRAY_COLS(MAC_ARRAY_COLS)
    ) u_mac_array (
        .clk(clk),
        .rst_n(rst_n),
        .enable(is_mac_op & valid_in),
        .data_a_i(data_a_i),
        .data_b_i(data_b_i),
        .weight_i(weight_i),
        .mac_result(mac_result)
    );
    
    // Activation Unit
    activation_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .VECTOR_WIDTH(VECTOR_WIDTH)
    ) u_activation (
        .clk(clk),
        .rst_n(rst_n),
        .enable(is_activation_op & valid_in),
        .activation_type(instruction[7:0]),
        .data_i(data_a_i),
        .data_o(activation_result)
    );
    
    // Normalization Unit
    normalization_unit_simple #(
        .DATA_WIDTH(DATA_WIDTH),
        .VECTOR_WIDTH(VECTOR_WIDTH)
    ) u_normalization (
        .clk(clk),
        .rst_n(rst_n),
        .enable(is_norm_op & valid_in),
        .norm_type(instruction[7:0]),
        .data_i(data_a_i),
        .data_o(norm_result)
    );
    
    // Output selection based on operation type
    integer i;
    always @(*) begin
        for (i = 0; i < VECTOR_WIDTH; i = i + 1) begin
            case (operation_mode)
                2'b00: result_o[i] = mac_result[i];           // MAC result
                2'b01: result_o[i] = activation_result[i];     // Activation result
                2'b10: result_o[i] = norm_result[i];           // Normalization result
                2'b11: result_o[i] = data_a_i[i];              // Passthrough
            endcase
        end
    end
    
    assign valid_out = valid_in;
    assign ready_out = 1'b1; // Always ready for simplicity
    
    // Memory interface logic (simplified)
    assign mem_req_o = is_mem_op & valid_in;
    assign data_o = {256{1'b0}};

endmodule
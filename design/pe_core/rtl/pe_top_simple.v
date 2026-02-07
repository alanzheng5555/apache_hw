// Simplified PE Top Module - Processing Element for AI Inference
// Implements the PE core specifications with simplified components for verification

`timescale 1ns/1ps

module pe_top_simple #(
    parameter DATA_WIDTH = 32,  // FP32 width
    parameter VECTOR_WIDTH = 16,
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
    
    // Data Inputs (packed for compatibility)
    input  wire [(DATA_WIDTH*VECTOR_WIDTH)-1:0] data_a_packed,
    input  wire [(DATA_WIDTH*VECTOR_WIDTH)-1:0] data_b_packed,
    input  wire [(DATA_WIDTH*VECTOR_WIDTH)-1:0] weight_packed,
    
    // Data Outputs (packed)
    output wire [(DATA_WIDTH*VECTOR_WIDTH)-1:0] result_packed,
    output wire                       valid_out,
    
    // Memory Interface (simplified)
    input  wire [31:0]               addr_i,
    output wire [255:0]              data_o,
    input  wire [255:0]              data_i,
    output wire                       mem_req_o,
    input  wire                       mem_ack_i
);

    // Internal signals
    wire [(DATA_WIDTH*MAC_ARRAY_ROWS)-1:0] mac_result_packed;
    
    // Instruction decode
    wire is_mac_op, is_activation_op, is_norm_op;
    assign is_mac_op = instruction[31:28] == 4'h1;
    assign is_activation_op = instruction[31:28] == 4'h2;
    assign is_norm_op = instruction[31:28] == 4'h3;
    
    // MAC Array
    mac_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_ROWS(MAC_ARRAY_ROWS),
        .ARRAY_COLS(MAC_ARRAY_COLS)
    ) u_mac_array (
        .clk(clk),
        .rst_n(rst_n),
        .enable(is_mac_op & valid_in),
        .data_a_i(data_a_packed[DATA_WIDTH*MAC_ARRAY_COLS-1:0]),
        .data_b_i(data_b_packed[DATA_WIDTH*MAC_ARRAY_ROWS-1:0]),
        .weight_i(weight_packed[DATA_WIDTH*MAC_ARRAY_COLS-1:0]),
        .mac_result(mac_result_packed)
    );
    
    // Output selection (passthrough for simplicity)
    assign result_packed = is_mac_op ? { {(VECTOR_WIDTH-MAC_ARRAY_ROWS){32'd0}}, mac_result_packed } : 
                          is_activation_op ? data_a_packed :
                          is_norm_op ? data_a_packed : data_a_packed;
    
    // Valid output
    assign valid_out = valid_in;
    assign ready_out = 1'b1;
    assign mem_req_o = 1'b0;
    assign data_o = 256'd0;

endmodule

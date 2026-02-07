// MAC Array Module - Matrix Multiply Accumulate Array for PE Core
// Simplified version with packed arrays for compatibility

`timescale 1ns/1ps

module mac_array #(
    parameter DATA_WIDTH = 32,
    parameter ARRAY_ROWS = 8,
    parameter ARRAY_COLS = 8
)(
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire                           enable,
    input  wire [(DATA_WIDTH*ARRAY_COLS)-1:0] data_a_i,
    input  wire [(DATA_WIDTH*ARRAY_ROWS)-1:0] data_b_i,
    input  wire [(DATA_WIDTH*ARRAY_COLS)-1:0] weight_i,
    output wire [(DATA_WIDTH*ARRAY_ROWS)-1:0] mac_result
);

    // Unpack data for processing
    wire [DATA_WIDTH-1:0] a_vec [ARRAY_COLS-1:0];
    wire [DATA_WIDTH-1:0] b_vec [ARRAY_ROWS-1:0];
    wire [DATA_WIDTH-1:0] w_vec [ARRAY_COLS-1:0];
    reg  [DATA_WIDTH-1:0] result_vec [ARRAY_ROWS-1:0];
    
    genvar row, col;
    integer j;
    
    // Unpack input arrays
    generate
        for (col = 0; col < ARRAY_COLS; col = col + 1) begin : unpack_a
            assign a_vec[col] = data_a_i[col*DATA_WIDTH +: DATA_WIDTH];
            assign w_vec[col] = weight_i[col*DATA_WIDTH +: DATA_WIDTH];
        end
        for (row = 0; row < ARRAY_ROWS; row = row + 1) begin : unpack_b
            assign b_vec[row] = data_b_i[row*DATA_WIDTH +: DATA_WIDTH];
        end
    endgenerate
    
    // MAC operation
    generate
        for (row = 0; row < ARRAY_ROWS; row = row + 1) begin : mac_rows
            reg [DATA_WIDTH*2+8-1:0] acc;
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    acc <= 0;
                end else if (enable) begin
                    acc = 0;
                    for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                        acc = acc + b_vec[row] * w_vec[j];
                    end
                end
            end
            always @* begin
                result_vec[row] = acc[DATA_WIDTH-1:0];
            end
        end
    endgenerate
    
    // Pack output
    generate
        for (row = 0; row < ARRAY_ROWS; row = row + 1) begin : pack_result
            assign mac_result[row*DATA_WIDTH +: DATA_WIDTH] = result_vec[row];
        end
    endgenerate

endmodule

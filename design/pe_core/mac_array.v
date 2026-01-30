// MAC Array Module - Matrix Multiply Accumulate Array for PE Core
// Implements the MAC array as specified in the PE core specification

`timescale 1ns/1ps

module mac_array #(
    parameter DATA_WIDTH = 16,
    parameter ARRAY_ROWS = 16,
    parameter ARRAY_COLS = 16
)(
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire                           enable,
    input  wire [DATA_WIDTH-1:0]         data_a_i [ARRAY_COLS-1:0],
    input  wire [DATA_WIDTH-1:0]         data_b_i [ARRAY_ROWS-1:0],
    input  wire [DATA_WIDTH-1:0]         weight_i [ARRAY_COLS-1:0],
    output wire [DATA_WIDTH-1:0]         mac_result [ARRAY_ROWS-1:0]
);

    // Internal signals for partial products and accumulators
    wire [DATA_WIDTH*2-1:0] partial_products [ARRAY_ROWS-1:0][ARRAY_COLS-1:0];
    reg  [DATA_WIDTH*2+8-1:0] accumulators [ARRAY_ROWS-1:0]; // Extra bits for accumulation
    
    genvar i, j;
    
    // Generate MAC units
    generate
        for (i = 0; i < ARRAY_ROWS; i = i + 1) begin : gen_rows
            for (j = 0; j < ARRAY_COLS; j = j + 1) begin : gen_cols
                // Partial product calculation
                assign partial_products[i][j] = $signed(data_b_i[i]) * $signed(weight_i[j]);
            end
            
            // Accumulation logic
            reg [$bits(partial_products)+$clog2(ARRAY_COLS)-1:0] temp_sum;
            integer k;
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    accumulators[i] <= 0;
                end
                else if (enable) begin
                    // Accumulate all partial products for this row
                    temp_sum = 0;
                    
                    for (k = 0; k < ARRAY_COLS; k = k + 1) begin
                        temp_sum = temp_sum + partial_products[i][k];
                    end
                    
                    // Add input data_a contribution
                    temp_sum = temp_sum + (data_a_i[i] << 1); // Shift for scaling if needed
                    
                    accumulators[i] <= temp_sum;
                end
            end
            
            // Final result assignment with proper width conversion
            assign mac_result[i] = accumulators[i][DATA_WIDTH-1:0];
        end
    endgenerate

endmodule
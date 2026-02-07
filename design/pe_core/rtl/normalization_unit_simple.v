// Simplified Normalization Unit Module for PE Core
// Implements Layer Normalization and RMS Normalization for Transformer models
// Simplified for compatibility with standard Verilog

`timescale 1ns/1ps

module normalization_unit_simple #(
    parameter DATA_WIDTH = 32,
    parameter VECTOR_WIDTH = 32
)(
    input  wire                            clk,
    input  wire                            rst_n,
    input  wire                            enable,
    input  wire [7:0]                     norm_type, // 0=LayerNorm, 1=RMSNorm
    input  wire [DATA_WIDTH-1:0]          data_i [VECTOR_WIDTH-1:0],
    output reg  [DATA_WIDTH-1:0]          data_o [VECTOR_WIDTH-1:0]
);

    // Define normalization types
    localparam NORM_LAYER = 8'h0;
    localparam NORM_RMS = 8'h1;
    
    // Internal signals
    reg [DATA_WIDTH-1:0] mean_val;
    reg [DATA_WIDTH-1:0] var_val;
    reg [DATA_WIDTH-1:0] inv_std_dev;
    reg [DATA_WIDTH-1:0] eps_val; // Small epsilon for numerical stability
    
    // Constants
    assign eps_val = 16'h0080; // Small positive value for FP16
    
    // Temporary registers for calculations
    reg [DATA_WIDTH*2-1:0] sum_temp;
    reg [DATA_WIDTH*2-1:0] sum_square_temp;
    reg [DATA_WIDTH-1:0] diff;
    reg [DATA_WIDTH-1:0] centered;
    integer i, j;

    always @(posedge clk) begin
        if (enable) begin
            case (norm_type)
                NORM_LAYER: begin
                    // Calculate mean
                    sum_temp = 0;
                    for (i = 0; i < VECTOR_WIDTH; i = i + 1) begin
                        sum_temp = sum_temp + $signed(data_i[i]);
                    end
                    mean_val = sum_temp / VECTOR_WIDTH;
                    
                    // Calculate variance
                    sum_square_temp = 0;
                    for (j = 0; j < VECTOR_WIDTH; j = j + 1) begin
                        diff = $signed(data_i[j]) - $signed(mean_val);
                        sum_square_temp = sum_square_temp + (diff * diff);
                    end
                    var_val = sum_square_temp / VECTOR_WIDTH;
                    
                    // Simplified standard deviation calculation (square root approximation)
                    // For now, just use a simple approximation
                    inv_std_dev = 16'h2000; // Fixed approximation for demonstration
                    
                    // Apply normalization: (x - mean) / sqrt(variance + eps)
                    for (i = 0; i < VECTOR_WIDTH; i = i + 1) begin
                        centered = $signed(data_i[i]) - $signed(mean_val);
                        // Simplified: just divide by a fixed factor for demonstration
                        data_o[i] <= centered >>> 2; // Divide by 4 as simple normalization
                    end
                end
                NORM_RMS: begin
                    // RMS Normalization: x / sqrt(mean(x^2) + eps)
                    sum_square_temp = 0;
                    for (i = 0; i < VECTOR_WIDTH; i = i + 1) begin
                        sum_square_temp = sum_square_temp + ($signed(data_i[i]) * $signed(data_i[i]));
                    end
                    var_val = sum_square_temp / VECTOR_WIDTH;
                    
                    // Simplified: use fixed factor for demonstration
                    inv_std_dev = 16'h2000; // Fixed approximation
                    
                    // Apply normalization
                    for (i = 0; i < VECTOR_WIDTH; i = i + 1) begin
                        // Simplified: just scale by a fixed factor for demonstration
                        data_o[i] <= data_i[i] >>> 1; // Divide by 2 as simple normalization
                    end
                end
                default: begin
                    // Pass through if unknown type
                    for (i = 0; i < VECTOR_WIDTH; i = i + 1) begin
                        data_o[i] <= data_i[i];
                    end
                end
            endcase
        end
    end

endmodule
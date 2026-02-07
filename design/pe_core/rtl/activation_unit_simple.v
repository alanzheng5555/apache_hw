// Simplified Activation Unit Module for PE Core
// Implements various activation functions optimized for Transformer models
// Simplified for compatibility with standard Verilog

`timescale 1ns/1ps

module activation_unit #(
    parameter DATA_WIDTH = 32,
    parameter VECTOR_WIDTH = 32
)(
    input  wire                            clk,
    input  wire                            rst_n,
    input  wire                            enable,
    input  wire [7:0]                     activation_type, // 0=GELU, 1=ReLU, 2=Swish, 3=Sigmoid, 4=Tanh
    input  wire [DATA_WIDTH-1:0]          data_i [VECTOR_WIDTH-1:0],
    output reg  [DATA_WIDTH-1:0]          data_o [VECTOR_WIDTH-1:0]
);

    // Define activation types
    localparam ACT_GELU = 8'h0;
    localparam ACT_RELU = 8'h1;
    localparam ACT_SWISH = 8'h2;
    localparam ACT_SIGMOID = 8'h3;
    localparam ACT_TANH = 8'h4;
    
    // Internal signals
    integer i;
    
    // Activation computation
    always @(posedge clk) begin
        if (enable) begin
            for (i = 0; i < VECTOR_WIDTH; i = i + 1) begin
                case (activation_type)
                    ACT_RELU: begin
                        // ReLU: max(0, x)
                        if ($signed(data_i[i]) > 0)
                            data_o[i] <= data_i[i];
                        else
                            data_o[i] <= {DATA_WIDTH{1'b0}}; // Zero
                    end
                    ACT_GELU: begin
                        // Simplified GELU: roughly x/2 for values near zero
                        if ($signed(data_i[i]) > 16'h4000) // Large positive
                            data_o[i] <= data_i[i];
                        else if ($signed(data_i[i]) < -16'h4000) // Large negative
                            data_o[i] <= {DATA_WIDTH{1'b0}}; // Zero
                        else
                            data_o[i] <= data_i[i] >>> 1; // Divide by 2 as approximation
                    end
                    ACT_SWISH: begin
                        // Simplified Swish: x sigmoid(x), approximated
                        if ($signed(data_i[i]) > 16'h2000) // Positive
                            data_o[i] <= data_i[i];
                        else if ($signed(data_i[i]) < -16'h2000) // Negative
                            data_o[i] <= {DATA_WIDTH{1'b0}}; // Zero
                        else
                            data_o[i] <= data_i[i] >>> 1; // Approximation
                    end
                    ACT_SIGMOID: begin
                        // Sigmoid approximation
                        if ($signed(data_i[i]) > 16'h4000) // Large positive
                            data_o[i] <= {1'b0, {(DATA_WIDTH-1){1'b1}}}; // Approaching 1
                        else if ($signed(data_i[i]) < -16'h4000) // Large negative
                            data_o[i] <= {DATA_WIDTH{1'b0}}; // Approaching 0
                        else
                            data_o[i] <= {{(DATA_WIDTH-7){1'b0}}, 7'b1000000}; // Midpoint
                    end
                    ACT_TANH: begin
                        // Tanh approximation
                        if ($signed(data_i[i]) > 16'h4000) // Large positive
                            data_o[i] <= {1'b0, {(DATA_WIDTH-1){1'b1}}}; // Approaching 1
                        else if ($signed(data_i[i]) < -16'h4000) // Large negative
                            data_o[i] <= {1'b1, {(DATA_WIDTH-1){1'b0}}}; // Approaching -1
                        else
                            data_o[i] <= data_i[i]; // Linear in center
                    end
                    default: begin
                        data_o[i] <= data_i[i]; // Pass-through
                    end
                endcase
            end
        end
    end

endmodule
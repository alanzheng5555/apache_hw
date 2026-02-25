// MAC Array Module - Simplified for Icarus Verilog (Standard Verilog)

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
    output reg  [(DATA_WIDTH*ARRAY_ROWS)-1:0] mac_result
);

    integer k;
    
    // Accumulator registers
    reg [DATA_WIDTH*2+8-1:0] acc0, acc1, acc2, acc3, acc4, acc5, acc6, acc7;
    reg [DATA_WIDTH*2+8-1:0] temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7;
    
    // Row 0
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc0 <= 0;
            temp0 <= 0;
        end else if (enable) begin
            temp0 <= data_b_i[0*DATA_WIDTH +: DATA_WIDTH] * weight_i[0*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[0*DATA_WIDTH +: DATA_WIDTH] * weight_i[1*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[0*DATA_WIDTH +: DATA_WIDTH] * weight_i[2*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[0*DATA_WIDTH +: DATA_WIDTH] * weight_i[3*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[0*DATA_WIDTH +: DATA_WIDTH] * weight_i[4*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[0*DATA_WIDTH +: DATA_WIDTH] * weight_i[5*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[0*DATA_WIDTH +: DATA_WIDTH] * weight_i[6*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[0*DATA_WIDTH +: DATA_WIDTH] * weight_i[7*DATA_WIDTH +: DATA_WIDTH];
            acc0 <= temp0;
        end
    end
    
    // Row 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc1 <= 0;
            temp1 <= 0;
        end else if (enable) begin
            temp1 <= data_b_i[1*DATA_WIDTH +: DATA_WIDTH] * weight_i[0*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[1*DATA_WIDTH +: DATA_WIDTH] * weight_i[1*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[1*DATA_WIDTH +: DATA_WIDTH] * weight_i[2*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[1*DATA_WIDTH +: DATA_WIDTH] * weight_i[3*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[1*DATA_WIDTH +: DATA_WIDTH] * weight_i[4*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[1*DATA_WIDTH +: DATA_WIDTH] * weight_i[5*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[1*DATA_WIDTH +: DATA_WIDTH] * weight_i[6*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[1*DATA_WIDTH +: DATA_WIDTH] * weight_i[7*DATA_WIDTH +: DATA_WIDTH];
            acc1 <= temp1;
        end
    end
    
    // Row 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc2 <= 0;
            temp2 <= 0;
        end else if (enable) begin
            temp2 <= data_b_i[2*DATA_WIDTH +: DATA_WIDTH] * weight_i[0*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[2*DATA_WIDTH +: DATA_WIDTH] * weight_i[1*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[2*DATA_WIDTH +: DATA_WIDTH] * weight_i[2*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[2*DATA_WIDTH +: DATA_WIDTH] * weight_i[3*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[2*DATA_WIDTH +: DATA_WIDTH] * weight_i[4*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[2*DATA_WIDTH +: DATA_WIDTH] * weight_i[5*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[2*DATA_WIDTH +: DATA_WIDTH] * weight_i[6*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[2*DATA_WIDTH +: DATA_WIDTH] * weight_i[7*DATA_WIDTH +: DATA_WIDTH];
            acc2 <= temp2;
        end
    end
    
    // Row 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc3 <= 0;
            temp3 <= 0;
        end else if (enable) begin
            temp3 <= data_b_i[3*DATA_WIDTH +: DATA_WIDTH] * weight_i[0*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[3*DATA_WIDTH +: DATA_WIDTH] * weight_i[1*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[3*DATA_WIDTH +: DATA_WIDTH] * weight_i[2*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[3*DATA_WIDTH +: DATA_WIDTH] * weight_i[3*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[3*DATA_WIDTH +: DATA_WIDTH] * weight_i[4*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[3*DATA_WIDTH +: DATA_WIDTH] * weight_i[5*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[3*DATA_WIDTH +: DATA_WIDTH] * weight_i[6*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[3*DATA_WIDTH +: DATA_WIDTH] * weight_i[7*DATA_WIDTH +: DATA_WIDTH];
            acc3 <= temp3;
        end
    end
    
    // Row 4
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc4 <= 0;
            temp4 <= 0;
        end else if (enable) begin
            temp4 <= data_b_i[4*DATA_WIDTH +: DATA_WIDTH] * weight_i[0*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[4*DATA_WIDTH +: DATA_WIDTH] * weight_i[1*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[4*DATA_WIDTH +: DATA_WIDTH] * weight_i[2*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[4*DATA_WIDTH +: DATA_WIDTH] * weight_i[3*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[4*DATA_WIDTH +: DATA_WIDTH] * weight_i[4*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[4*DATA_WIDTH +: DATA_WIDTH] * weight_i[5*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[4*DATA_WIDTH +: DATA_WIDTH] * weight_i[6*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[4*DATA_WIDTH +: DATA_WIDTH] * weight_i[7*DATA_WIDTH +: DATA_WIDTH];
            acc4 <= temp4;
        end
    end
    
    // Row 5
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc5 <= 0;
            temp5 <= 0;
        end else if (enable) begin
            temp5 <= data_b_i[5*DATA_WIDTH +: DATA_WIDTH] * weight_i[0*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[5*DATA_WIDTH +: DATA_WIDTH] * weight_i[1*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[5*DATA_WIDTH +: DATA_WIDTH] * weight_i[2*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[5*DATA_WIDTH +: DATA_WIDTH] * weight_i[3*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[5*DATA_WIDTH +: DATA_WIDTH] * weight_i[4*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[5*DATA_WIDTH +: DATA_WIDTH] * weight_i[5*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[5*DATA_WIDTH +: DATA_WIDTH] * weight_i[6*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[5*DATA_WIDTH +: DATA_WIDTH] * weight_i[7*DATA_WIDTH +: DATA_WIDTH];
            acc5 <= temp5;
        end
    end
    
    // Row 6
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc6 <= 0;
            temp6 <= 0;
        end else if (enable) begin
            temp6 <= data_b_i[6*DATA_WIDTH +: DATA_WIDTH] * weight_i[0*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[6*DATA_WIDTH +: DATA_WIDTH] * weight_i[1*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[6*DATA_WIDTH +: DATA_WIDTH] * weight_i[2*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[6*DATA_WIDTH +: DATA_WIDTH] * weight_i[3*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[6*DATA_WIDTH +: DATA_WIDTH] * weight_i[4*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[6*DATA_WIDTH +: DATA_WIDTH] * weight_i[5*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[6*DATA_WIDTH +: DATA_WIDTH] * weight_i[6*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[6*DATA_WIDTH +: DATA_WIDTH] * weight_i[7*DATA_WIDTH +: DATA_WIDTH];
            acc6 <= temp6;
        end
    end
    
    // Row 7
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc7 <= 0;
            temp7 <= 0;
        end else if (enable) begin
            temp7 <= data_b_i[7*DATA_WIDTH +: DATA_WIDTH] * weight_i[0*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[7*DATA_WIDTH +: DATA_WIDTH] * weight_i[1*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[7*DATA_WIDTH +: DATA_WIDTH] * weight_i[2*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[7*DATA_WIDTH +: DATA_WIDTH] * weight_i[3*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[7*DATA_WIDTH +: DATA_WIDTH] * weight_i[4*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[7*DATA_WIDTH +: DATA_WIDTH] * weight_i[5*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[7*DATA_WIDTH +: DATA_WIDTH] * weight_i[6*DATA_WIDTH +: DATA_WIDTH] +
                     data_b_i[7*DATA_WIDTH +: DATA_WIDTH] * weight_i[7*DATA_WIDTH +: DATA_WIDTH];
            acc7 <= temp7;
        end
    end
    
    // Output result
    always @(*) begin
        mac_result[0*DATA_WIDTH +: DATA_WIDTH] = acc0[DATA_WIDTH-1:0];
        mac_result[1*DATA_WIDTH +: DATA_WIDTH] = acc1[DATA_WIDTH-1:0];
        mac_result[2*DATA_WIDTH +: DATA_WIDTH] = acc2[DATA_WIDTH-1:0];
        mac_result[3*DATA_WIDTH +: DATA_WIDTH] = acc3[DATA_WIDTH-1:0];
        mac_result[4*DATA_WIDTH +: DATA_WIDTH] = acc4[DATA_WIDTH-1:0];
        mac_result[5*DATA_WIDTH +: DATA_WIDTH] = acc5[DATA_WIDTH-1:0];
        mac_result[6*DATA_WIDTH +: DATA_WIDTH] = acc6[DATA_WIDTH-1:0];
        mac_result[7*DATA_WIDTH +: DATA_WIDTH] = acc7[DATA_WIDTH-1:0];
    end

endmodule

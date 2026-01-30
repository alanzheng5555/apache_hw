// Register File Module for PE Core
// Implements scalar and vector register files as specified in architecture

`timescale 1ns/1ps

module register_file #(
    parameter SCALAR_REGS = 32,
    parameter VECTOR_REGS = 32,
    parameter VEC_WIDTH = 512, // Vector register width in bits
    parameter DATA_WIDTH = 16
)(
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Scalar register ports
    input  wire                      s_write_enable,
    input  wire [$clog2(SCALAR_REGS)-1:0] s_write_reg_addr,
    input  wire [DATA_WIDTH-1:0]    s_write_data,
    input  wire [$clog2(SCALAR_REGS)-1:0] s_read_reg_addr1,
    input  wire [$clog2(SCALAR_REGS)-1:0] s_read_reg_addr2,
    output wire [DATA_WIDTH-1:0]    s_read_data1,
    output wire [DATA_WIDTH-1:0]    s_read_data2,
    
    // Vector register ports
    input  wire                      v_write_enable,
    input  wire [$clog2(VECTOR_REGS)-1:0] v_write_reg_addr,
    input  wire [VEC_WIDTH-1:0]     v_write_data,
    input  wire [$clog2(VECTOR_REGS)-1:0] v_read_reg_addr,
    output wire [VEC_WIDTH-1:0]     v_read_data
);

    // Scalar register array
    reg [DATA_WIDTH-1:0] scalar_regs [SCALAR_REGS-1:0];
    
    // Vector register array
    reg [VEC_WIDTH-1:0] vector_regs [VECTOR_REGS-1:0];
    
    // Scalar register write
    always @(posedge clk) begin
        if (s_write_enable) begin
            scalar_regs[s_write_reg_addr] <= s_write_data;
        end
    end
    
    // Vector register write
    always @(posedge clk) begin
        if (v_write_enable) begin
            vector_regs[v_write_reg_addr] <= v_write_data;
        end
    end
    
    // Scalar register read
    assign s_read_data1 = scalar_regs[s_read_reg_addr1];
    assign s_read_data2 = scalar_regs[s_read_reg_addr2];
    
    // Vector register read
    assign v_read_data = vector_regs[v_read_reg_addr];

endmodule
// Complete PE Core Module
// Integrates all PE core components into a unified module

`timescale 1ns/1ps

module pe_core_complete #(
    parameter DATA_WIDTH = 32,
    parameter VECTOR_WIDTH = 16,
    parameter MAC_ARRAY_ROWS = 16,
    parameter MAC_ARRAY_COLS = 16,
    parameter SCALAR_REGS = 32,
    parameter VECTOR_REGS = 32,
    parameter VEC_REG_WIDTH = 512,
    parameter L1_CACHE_SIZE = 32768,
    parameter L1_LINE_SIZE = 64,
    parameter L1_ASSOC = 4
)(
    // Global signals
    input  wire                        clk,
    input  wire                        rst_n,
    
    // Control interface
    input  wire                        start,
    input  wire [31:0]                instruction,
    output reg                         done,
    
    // Data interfaces
    input  wire [DATA_WIDTH-1:0]      data_in [VECTOR_WIDTH-1:0],
    output wire [DATA_WIDTH-1:0]      data_out [VECTOR_WIDTH-1:0],
    
    // Memory interface
    input  wire [31:0]                mem_addr,
    input  wire                        mem_req,
    output wire [255:0]               mem_data_out,
    input  wire [255:0]               mem_data_in,
    output wire                        mem_ack
);

    // Internal control signals
    wire mac_enable, activation_enable, norm_enable;
    
    // Internal data paths
    wire [DATA_WIDTH-1:0] mac_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] activation_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] norm_result [VECTOR_WIDTH-1:0];
    
    // Decode instruction
    assign mac_enable = instruction[31:28] == 4'h1;
    assign activation_enable = instruction[31:28] == 4'h2;
    assign norm_enable = instruction[31:28] == 4'h3;
    
    // MAC Array
    mac_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_ROWS(MAC_ARRAY_ROWS),
        .ARRAY_COLS(MAC_ARRAY_COLS)
    ) u_mac_array (
        .clk(clk),
        .rst_n(rst_n),
        .enable(mac_enable),
        .data_a_i(data_in),
        .data_b_i(data_in),
        .weight_i(data_in),
        .mac_result(mac_result)
    );
    
    // Activation Unit
    activation_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .VECTOR_WIDTH(VECTOR_WIDTH)
    ) u_activation (
        .clk(clk),
        .rst_n(rst_n),
        .enable(activation_enable),
        .activation_type(instruction[7:0]),
        .data_i(data_in),
        .data_o(activation_result)
    );
    
    // Normalization Unit
    normalization_unit_simple #(
        .DATA_WIDTH(DATA_WIDTH),
        .VECTOR_WIDTH(VECTOR_WIDTH)
    ) u_normalization (
        .clk(clk),
        .rst_n(rst_n),
        .enable(norm_enable),
        .norm_type(instruction[7:0]),
        .data_i(data_in),
        .data_o(norm_result)
    );
    
    // Output selection and control logic
    reg [2:0] operation_state;
    localparam IDLE = 3'd0, PROCESSING = 3'd1, COMPLETE = 3'd2;
    reg [7:0] cycle_count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operation_state <= IDLE;
            done <= 1'b0;
            cycle_count <= 8'd0;
        end else begin
            case (operation_state)
                IDLE: begin
                    if (start) begin
                        operation_state <= PROCESSING;
                        done <= 1'b0;
                        cycle_count <= 8'd0;
                    end
                end
                PROCESSING: begin
                    cycle_count <= cycle_count + 1;
                    // Simplified: complete after 10 cycles
                    if (cycle_count >= 8'd10) begin
                        operation_state <= COMPLETE;
                    end
                end
                COMPLETE: begin
                    done <= 1'b1;
                    operation_state <= IDLE;
                end
            endcase
        end
    end
    
    // Output data selection
    assign data_out = norm_enable ? norm_result :
                     activation_enable ? activation_result :
                     mac_enable ? mac_result : data_in;
                     
    // Memory interface (simplified passthrough)
    assign mem_data_out = mem_data_in;
    assign mem_ack = mem_req;

endmodule

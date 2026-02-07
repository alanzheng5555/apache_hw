// PE Core v2 - Direct extraction
`timescale 1ns/1ps

module pe_core_v2 (
    input clk,
    input rst_n,
    input [31:0] opcode_func,
    input [31:0] op1, op2, op3,
    input valid_in,
    output reg [31:0] result_out,
    output reg result_valid
);
    
    localparam OPC_ARITH = 7'b0000001;
    localparam OPC_FPU = 7'b0000010;
    localparam OPC_COMP = 7'b0010000;
    
    // Pipeline registers
    reg pipeline_valid;
    reg [6:0] pipeline_opcode;
    reg [4:0] pipeline_func;
    reg [31:0] pipeline_op1, pipeline_op2, pipeline_op3;
    
    // Stage 1: Capture input
    always @(posedge clk) begin
        if (!rst_n) begin
            pipeline_valid <= 1'b0;
            pipeline_opcode <= 7'd0;
            pipeline_func <= 5'd0;
            pipeline_op1 <= 32'd0;
            pipeline_op2 <= 32'd0;
            pipeline_op3 <= 32'd0;
        end else begin
            if (valid_in) begin
                pipeline_valid <= 1'b1;
                pipeline_opcode <= opcode_func[31:25];  // Direct extraction
                pipeline_func <= opcode_func[24:20];    // Direct extraction
                pipeline_op1 <= op1;
                pipeline_op2 <= op2;
                pipeline_op3 <= op3;
            end else begin
                pipeline_valid <= 1'b0;
            end
        end
    end
    
    // Stage 2: Execute operation
    always @(posedge clk) begin
        if (!rst_n) begin
            result_valid <= 1'b0;
            result_out <= 32'd0;
        end else begin
            if (pipeline_valid) begin
                result_valid <= 1'b1;
                
                case (pipeline_opcode)
                    OPC_ARITH: begin
                        case (pipeline_func)
                            5'b00001: result_out <= pipeline_op1 + pipeline_op2;  // ADD
                            5'b00010: result_out <= pipeline_op1 - pipeline_op2;  // SUB
                            5'b00011: result_out <= pipeline_op1 * pipeline_op2;  // MUL
                            5'b00100: result_out <= pipeline_op1 / pipeline_op2;  // DIV
                            5'b00101: result_out <= pipeline_op1 * pipeline_op2 + pipeline_op3;  // MAD
                            5'b00110: result_out <= pipeline_op1 * pipeline_op2 + pipeline_op3;  // MAC
                            5'b01001: result_out <= pipeline_op1 & pipeline_op2;   // AND
                            5'b01010: result_out <= pipeline_op1 | pipeline_op2;   // OR
                            5'b01011: result_out <= pipeline_op1 ^ pipeline_op2;   // XOR
                            5'b01100: result_out <= pipeline_op1 << pipeline_op2[4:0]; // SHL
                            5'b01101: result_out <= pipeline_op1 >> pipeline_op2[4:0]; // SHR
                            default: result_out <= 32'd999999;  // ARITH default
                        endcase
                    end
                    OPC_FPU: begin
                        case (pipeline_func)
                            5'b00001: result_out <= pipeline_op1 * pipeline_op2 + pipeline_op3;  // FMA
                            5'b01011: result_out <= (pipeline_op1[31]) ? 32'd0 : pipeline_op1;  // RELU
                            5'b01101: result_out <= (pipeline_op1[31]) ? -pipeline_op1 : pipeline_op1;  // ABS
                            5'b01110: result_out <= -pipeline_op1;  // NEG
                            5'b10000: result_out <= (pipeline_op1 < pipeline_op2) ? pipeline_op1 : pipeline_op2;  // MIN
                            5'b10001: result_out <= (pipeline_op1 > pipeline_op2) ? pipeline_op1 : pipeline_op2;  // MAX
                            default: result_out <= 32'd888888;  // FPU default
                        endcase
                    end
                    OPC_COMP: begin
                        case (pipeline_func)
                            5'b00001: result_out <= (pipeline_op1 == pipeline_op2) ? 32'd1 : 32'd0;  // EQ
                            5'b00010: result_out <= (pipeline_op1 != pipeline_op2) ? 32'd1 : 32'd0;  // NE
                            5'b00011: result_out <= (pipeline_op1 < pipeline_op2) ? 32'd1 : 32'd0;  // LT
                            5'b00100: result_out <= (pipeline_op1 <= pipeline_op2) ? 32'd1 : 32'd0;  // LE
                            5'b00101: result_out <= (pipeline_op1 > pipeline_op2) ? 32'd1 : 32'd0;  // GT
                            5'b00110: result_out <= (pipeline_op1 >= pipeline_op2) ? 32'd1 : 32'd0;  // GE
                            default: result_out <= 32'd777777;  // COMP default
                        endcase
                    end
                    default: result_out <= 32'd666666;  // Unknown opcode
                endcase
            end else begin
                result_valid <= 1'b0;
                result_out <= 32'd0;
            end
        end
    end
    
endmodule
//===================================================================
// PE Core - Single Cycle Version for Testing
//===================================================================
`timescale 1ns/1ps

module pe_core_single (
    input clk,
    input rst_n,
    input [31:0] opcode,
    input [31:0] op1,
    input [31:0] op2,
    input [31:0] op3,
    input valid_in,
    output reg [31:0] result_out,
    output reg result_valid
);
    
    // 操作码定义
    localparam OPC_ARITH = 7'b0000001;
    localparam OPC_FPU   = 7'b0000010;
    localparam OPC_COMP  = 7'b0010000;
    
    // Single cycle execution
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_valid <= 0;
            result_out <= 0;
        end else if (valid_in) begin
            result_valid <= 1;
            
            case (opcode[31:25])
                OPC_ARITH: begin
                    case (opcode[24:20])
                        5'b00001: result_out <= op1 + op2;           // ADD
                        5'b00010: result_out <= op1 - op2;           // SUB
                        5'b00011: result_out <= op1 * op2;           // MUL
                        5'b00100: result_out <= op1 / op2;           // DIV
                        5'b00101: result_out <= op1 * op2 + op3;    // MAD
                        5'b01001: result_out <= op1 & op2;           // AND
                        5'b01010: result_out <= op1 | op2;           // OR
                        5'b01011: result_out <= op1 ^ op2;           // XOR
                        5'b01100: result_out <= op1 << op2[4:0];    // SHL
                        5'b01101: result_out <= op1 >> op2[4:0];    // SHR
                        default:  result_out <= 0;
                    endcase
                end
                
                OPC_FPU: begin
                    case (opcode[24:20])
                        5'b00001: result_out <= op1 * op2 + op3;    // FMA
                        5'b01011: result_out <= (op1[31]) ? 32'd0 : op1;  // RELU
                        5'b01101: result_out <= (op1[31]) ? -op1 : op1;  // ABS
                        5'b01110: result_out <= -op1;               // NEG
                        5'b10000: result_out <= (op1 < op2) ? op1 : op2;  // MIN
                        5'b10001: result_out <= (op1 > op2) ? op1 : op2;  // MAX
                        default:  result_out <= 0;
                    endcase
                end
                
                OPC_COMP: begin
                    case (opcode[24:20])
                        5'b00001: result_out <= (op1 == op2) ? 32'd1 : 32'd0;  // EQ
                        5'b00010: result_out <= (op1 != op2) ? 32'd1 : 32'd0;  // NE
                        5'b00011: result_out <= (op1 < op2) ? 32'd1 : 32'd0;  // LT
                        5'b00100: result_out <= (op1 <= op2) ? 32'd1 : 32'd0;  // LE
                        5'b00101: result_out <= (op1 > op2) ? 32'd1 : 32'd0;  // GT
                        5'b00110: result_out <= (op1 >= op2) ? 32'd1 : 32'd0;  // GE
                        default:  result_out <= 0;
                    endcase
                end
                
                default: begin
                    result_valid <= 0;
                    result_out <= 0;
                end
            endcase
        end else begin
            result_valid <= 0;
            result_out <= 0;
        end
    end
    
endmodule
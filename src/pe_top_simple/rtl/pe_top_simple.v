//===================================================================
// PE Top Simple - Pure Sequential Version
//===================================================================
`timescale 1ns/1ps

module pe_top_simple (
    input  clk,
    input  rst_n,
    
    input  [31:0]  cfg_addr,
    input  [31:0]  cfg_wdata,
    input          cfg_we,
    input          cfg_en,
    output [31:0]  cfg_rdata,
    output         intr
);
    localparam OPC_ARITH = 7'b0000001;
    localparam OPC_FPU   = 7'b0000010;
    localparam OPC_COMP  = 7'b0010000;
    
    reg [31:0] rf [0:31];
    
    wire [4:0] rs1 = cfg_addr[19:15];
    wire [4:0] rs2 = cfg_addr[14:10];
    wire [4:0] rs3 = cfg_addr[9:5];
    wire [4:0] rd  = cfg_addr[4:0];
    wire [6:0] opcode = cfg_addr[31:25];
    wire [4:0] func   = cfg_addr[24:20];
    
    // Latch values at clock edge
    reg [4:0] rs1_reg, rs2_reg, rs3_reg, rd_reg;
    reg [6:0] opcode_reg;
    reg [4:0] func_reg;
    reg cfg_en_reg, cfg_we_reg;
    
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                rf[i] <= 0;
        end else begin
            // Latch inputs at clock edge
            rs1_reg <= rs1;
            rs2_reg <= rs2;
            rs3_reg <= rs3;
            rd_reg <= rd;
            opcode_reg <= opcode;
            func_reg <= func;
            cfg_en_reg <= cfg_en;
            cfg_we_reg <= cfg_we;
            
            // Register write logic
            if (cfg_we_reg && rd_reg != 0) begin
                if (cfg_en_reg) begin
                    // PE operation
                    $display("DEBUG: PE op - opcode=%b, func=%b, rs1=%d, rs2=%d", opcode_reg, func_reg, rf[rs1_reg], rf[rs2_reg]);
                    case (opcode_reg)
                        OPC_ARITH: begin
                            case (func_reg)
                                5'b00001: begin $display("DEBUG: ADD"); rf[rd_reg] <= rf[rs1_reg] + rf[rs2_reg]; end
                                5'b00010: begin $display("DEBUG: SUB"); rf[rd_reg] <= rf[rs1_reg] - rf[rs2_reg]; end
                                5'b00011: begin $display("DEBUG: MUL"); rf[rd_reg] <= rf[rs1_reg] * rf[rs2_reg]; end
                                default: rf[rd_reg] <= 0;
                            endcase
                        end
                        default: rf[rd_reg] <= 0;
                    endcase
                end else begin
                    $display("DEBUG: Direct write - rf[%d] <= %d", rd_reg, cfg_wdata);
                    rf[rd_reg] <= cfg_wdata;
                end
            end
        end
    end
    
    assign cfg_rdata = rf[cfg_addr[4:0]];
    assign intr = 1'b0;
    
endmodule
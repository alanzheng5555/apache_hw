// Complete PE Core Module
// Integrates all PE core components into a unified module

`timescale 1ns/1ps

module pe_core_complete #(
    parameter DATA_WIDTH = 16,
    parameter VECTOR_WIDTH = 32,
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
    output wire                        done,
    
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
    wire [31:0] current_instruction;
    
    // Internal data paths
    wire [DATA_WIDTH-1:0] mac_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] activation_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] norm_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] reg_read_data [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] cache_read_data [VECTOR_WIDTH-1:0];
    
    // Decode instruction
    assign mac_enable = instruction[31:28] == 4'h1;
    assign activation_enable = instruction[31:28] == 4'h2;
    assign norm_enable = instruction[31:28] == 4'h3;
    assign current_instruction = instruction;
    
    // Register file
    wire [DATA_WIDTH-1:0] rf_read_data1, rf_read_data2;
    wire [DATA_WIDTH-1:0] rf_write_data;
    wire rf_write_enable;
    wire [$clog2(SCALAR_REGS)-1:0] rf_write_addr;
    wire [$clog2(SCALAR_REGS)-1:0] rf_read_addr1, rf_read_addr2;
    
    register_file #(
        .SCALAR_REGS(SCALAR_REGS),
        .VECTOR_REGS(VECTOR_REGS),
        .VEC_WIDTH(VEC_REG_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_register_file (
        .clk(clk),
        .rst_n(rst_n),
        .s_write_enable(rf_write_enable),
        .s_write_reg_addr(rf_write_addr),
        .s_write_data(rf_write_data),
        .s_read_reg_addr1(rf_read_addr1),
        .s_read_reg_addr2(rf_read_addr2),
        .s_read_data1(rf_read_data1),
        .s_read_data2(rf_read_data2),
        .v_write_enable(1'b0), // Simplified for this example
        .v_write_reg_addr(0),
        .v_write_data(0),
        .v_read_reg_addr(0),
        .v_read_data() // Unused in this simplified version
    );
    
    // Local cache
    wire cache_resp_valid;
    wire [255:0] cache_resp_data;
    
    local_cache #(
        .CACHE_SIZE(L1_CACHE_SIZE),
        .LINE_SIZE(L1_LINE_SIZE),
        .ASSOCIATIVITY(L1_ASSOC),
        .ADDR_WIDTH(32),
        .DATA_WIDTH(256)
    ) u_local_cache (
        .clk(clk),
        .rst_n(rst_n),
        .req_valid(mem_req),
        .req_write(1'b0), // Read-only in this example
        .req_addr(mem_addr),
        .req_wdata(256'h0), // Write data not used in this example
        .resp_rdata(cache_resp_data),
        .resp_valid(cache_resp_valid),
        .mem_req(mem_ack),
        .mem_write(1'b0),
        .mem_addr(mem_addr),
        .mem_wdata(256'h0),
        .mem_rdata(mem_data_in),
        .mem_resp_valid(1'b1) // Simplified
    );
    
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
        .data_b_i(mac_enable ? data_in : '0), // Simplified data routing
        .weight_i(mac_enable ? data_in : '0), // Simplified data routing
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
        .data_i(activation_enable ? data_in : 
                mac_enable ? mac_result : 
                data_in), // Data routing based on operation
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
        .data_i(norm_enable ? data_in : 
                activation_enable ? activation_result : 
                mac_enable ? mac_result : 
                data_in), // Data routing based on operation
        .data_o(norm_result)
    );
    
    // Output selection and control logic
    reg [2:0] operation_state;
    localparam IDLE = 3'd0, PROCESSING = 3'd1, COMPLETE = 3'd2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operation_state <= IDLE;
            done <= 1'b0;
        end else begin
            case (operation_state)
                IDLE: begin
                    if (start) begin
                        operation_state <= PROCESSING;
                        done <= 1'b0;
                    end
                end
                PROCESSING: begin
                    // For simplicity, assume operation completes in 10 cycles
                    if ($time > 100) begin  // Simplified completion condition
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
                     
    // Memory interface
    assign mem_data_out = cache_resp_data;

endmodule
// PE Top with Full AXI4 Master and AXI4 Slave Interface
// Master: Reads from external memory
// Slave:  Allows external bus to access internal SRAM

`timescale 1ns/1ps

// Parameters
localparam DATA_W = 32;
localparam VEC_W = 4;
localparam AXI_ADDR_W = 32;
localparam AXI_DATA_W = 64;
localparam AXI_ID_W = 4;
localparam BURST_SZ = 8;
localparam SRAM_DEPTH = 256;
localparam SRAM_ADDR_W = 8;

// ==========================================
// Sub-modules
// ==========================================
module mac_array #(
    parameter WIDTH = 32,
    parameter SIZE = 4
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 enable,
    input  wire [WIDTH-1:0]    a [SIZE-1:0],
    input  wire [WIDTH-1:0]    b [SIZE-1:0],
    output wire [WIDTH-1:0]     result [SIZE-1:0]
);
    genvar i;
    generate for (i = 0; i < SIZE; i = i + 1) begin : mac
        assign result[i] = a[i] * b[i];
    end endgenerate
endmodule

module activation_unit #(
    parameter WIDTH = 32,
    parameter SIZE = 4
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 enable,
    input  wire [7:0]          act_type,
    input  wire [WIDTH-1:0]    data_in [SIZE-1:0],
    output wire [WIDTH-1:0]     data_out [SIZE-1:0]
);
    genvar i;
    generate for (i = 0; i < SIZE; i = i + 1) begin : act
        assign data_out[i] = (act_type == 8'd0) ? 
                           ((data_in[i][WIDTH-1]) ? 32'd0 : data_in[i]) : data_in[i];
    end endgenerate
endmodule

module normalization_unit #(
    parameter WIDTH = 32,
    parameter SIZE = 4
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 enable,
    input  wire [7:0]          norm_type,
    input  wire [WIDTH-1:0]    data_in [SIZE-1:0],
    output wire [WIDTH-1:0]     data_out [SIZE-1:0]
);
    genvar i;
    generate for (i = 0; i < SIZE; i = i + 1) begin : norm
        assign data_out[i] = data_in[i];
    end endgenerate
endmodule

// ==========================================
// SRAM Module (Dual-port, 32-bit wide)
// ==========================================
module sram #(
    parameter DEPTH = 256,
    parameter WIDTH = 32,
    parameter ADDR_W = 8
)(
    // Port A: PE Write / AXI Read
    input  wire                 clk_a,
    input  wire                 we_a,
    input  wire [ADDR_W-1:0]    addr_a,
    input  wire [WIDTH-1:0]    wdata_a,
    output wire [WIDTH-1:0]    rdata_a,
    
    // Port B: AXI Write
    input  wire                 clk_b,
    input  wire                 we_b,
    input  wire [ADDR_W-1:0]    addr_b,
    input  wire [WIDTH-1:0]    wdata_b
);
    
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    
    // Port A
    assign rdata_a = mem[addr_a];
    always @(posedge clk_a) begin
        if (we_a) mem[addr_a] <= wdata_a;
    end
    
    // Port B
    always @(posedge clk_b) begin
        if (we_b) mem[addr_b] <= wdata_b;
    end
    
endmodule

// ==========================================
// PE Top with AXI Master + AXI Slave
// ==========================================
module pe_top #(
    parameter DATA_WIDTH = 32,
    parameter VECTOR_WIDTH = 4,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64,
    parameter AXI_ID_WIDTH = 4,
    parameter BURST_SIZE = 8
)(
    // System
    input  wire                         clk,
    input  wire                         rst_n,
    
    // ==========================================
    // AXI4 Master Interface (to external memory)
    // ==========================================
    // Write Channel (unused)
    output wire [AXI_ID_WIDTH-1:0]      m_awid,
    output wire [AXI_ADDR_WIDTH-1:0]    m_awaddr,
    output wire [7:0]                   m_awlen,
    output wire [2:0]                  m_awsize,
    output wire [1:0]                  m_awburst,
    output wire [3:0]                  m_awcache,
    output wire [2:0]                  m_awprot,
    output wire                         m_awvalid,
    input  wire                         m_awready,
    output wire [AXI_DATA_WIDTH-1:0]    m_wdata,
    output wire [(AXI_DATA_WIDTH/8)-1:0] m_wstrb,
    output wire                         m_wlast,
    output wire                         m_wvalid,
    input  wire                         m_wready,
    input  wire [AXI_ID_WIDTH-1:0]      m_bid,
    input  wire [1:0]                   m_bresp,
    input  wire                         m_bvalid,
    output wire                         m_bready,
    
    // Read Channel
    output wire [AXI_ID_WIDTH-1:0]      m_arid,
    output wire [AXI_ADDR_WIDTH-1:0]    m_araddr,
    output wire [7:0]                   m_arlen,
    output wire [2:0]                  m_arsize,
    output wire [1:0]                  m_arburst,
    output wire [3:0]                  m_arcache,
    output wire [2:0]                  m_arprot,
    output wire                         m_arvalid,
    input  wire                         m_arready,
    input  wire [AXI_ID_WIDTH-1:0]      m_rid,
    input  wire [AXI_DATA_WIDTH-1:0]    m_rdata,
    input  wire [1:0]                   m_rresp,
    input  wire                         m_rlast,
    input  wire                         m_rvalid,
    output wire                         m_rready,
    
    // ==========================================
    // AXI4 Slave Interface (for external bus to access SRAM)
    // ==========================================
    // Write Channel
    input  wire [AXI_ID_WIDTH-1:0]      s_awid,
    input  wire [AXI_ADDR_WIDTH-1:0]    s_awaddr,
    input  wire [7:0]                   s_awlen,
    input  wire [2:0]                  s_awsize,
    input  wire [1:0]                  s_awburst,
    input  wire [3:0]                  s_awcache,
    input  wire [2:0]                  s_awprot,
    input  wire                         s_awvalid,
    output wire                         s_awready,
    input  wire [AXI_DATA_WIDTH-1:0]    s_wdata,
    input  wire [(AXI_DATA_WIDTH/8)-1:0] s_wstrb,
    input  wire                         s_wlast,
    input  wire                         s_wvalid,
    output wire                         s_wready,
    output wire [AXI_ID_WIDTH-1:0]      s_bid,
    output wire [1:0]                   s_bresp,
    output wire                         s_bvalid,
    input  wire                         s_bready,
    
    // Read Channel
    input  wire [AXI_ID_WIDTH-1:0]      s_arid,
    input  wire [AXI_ADDR_WIDTH-1:0]    s_araddr,
    input  wire [7:0]                   s_arlen,
    input  wire [2:0]                  s_arsize,
    input  wire [1:0]                  s_arburst,
    input  wire [3:0]                  s_arcache,
    input  wire [2:0]                  s_arprot,
    input  wire                         s_arvalid,
    output wire                         s_arready,
    output wire [AXI_ID_WIDTH-1:0]      s_rid,
    output wire [AXI_DATA_WIDTH-1:0]    s_rdata,
    output wire [1:0]                   s_rresp,
    output wire                         s_rlast,
    output wire                         s_rvalid,
    input  wire                         s_rready,
    
    // Control & Status
    input  wire [AXI_ADDR_WIDTH-1:0]    base_addr,
    input  wire [31:0]                  instruction,
    input  wire                         start,
    output wire                         done,
    output wire [7:0]                   op_count,
    output wire                         error
);

    // ==========================================
    // FSM States
    // ==========================================
    localparam IDLE       = 5'd0;
    localparam INIT_BURST = 5'd1;
    localparam WAIT_RDATA = 5'd2;
    localparam PROCESS    = 5'd3;
    localparam NEXT_OP    = 5'd4;
    localparam DONE       = 5'd5;
    
    // Registers
    reg [4:0] state;
    reg [AXI_ADDR_WIDTH-1:0] cur_addr;
    reg [7:0] op_counter;
    reg done_r, error_r;
    reg [AXI_ID_WIDTH-1:0] m_arid_r;
    
    // SRAM signals
    wire sram_we_a;
    wire [7:0] sram_addr_a;
    wire [31:0] sram_wdata_a;
    reg sram_we_b, sram_we_b_reg;
    reg [7:0] sram_addr_b, sram_addr_b_reg;
    reg [31:0] sram_wdata_b, sram_wdata_b_reg;
    wire [31:0] sram_rdata_a;
    
    // PE data
    reg [DATA_WIDTH-1:0] data_a [VECTOR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] data_b [VECTOR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] result [VECTOR_WIDTH-1:0];
    
    // Control
    wire is_mac, is_act, is_norm;
    wire [7:0] act_type, norm_type;
    
    // PE results
    wire [DATA_WIDTH-1:0] mac_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] act_result [VECTOR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] norm_result [VECTOR_WIDTH-1:0];
    wire pe_valid;
    
    // ==========================================
    // AXI Slave Write Channel FSM
    // ==========================================
    reg [4:0] s_state;
    reg [7:0] s_wcount;
    reg [31:0] s_waddr_reg;
    
    localparam S_IDLE    = 3'd0;
    localparam S_WWAIT   = 3'd1;
    localparam S_WDATA   = 3'd2;
    localparam S_WRESP   = 3'd3;
    localparam S_RWAIT   = 3'd4;
    localparam S_RDATA   = 3'd5;
    
    reg [4:0] s_rstate;
    reg [7:0] s_rcount;
    reg [31:0] s_raddr_reg;
    reg [63:0] s_rdata_reg;
    
    // Decode
    assign is_mac   = instruction[31:28] == 4'h1;
    assign is_act   = instruction[31:28] == 4'h2;
    assign is_norm  = instruction[31:28] == 4'h3;
    assign act_type = instruction[7:0];
    assign norm_type = instruction[7:0];
    
    // ==========================================
    // AXI Master Assigns (Write unused)
    // ==========================================
    assign m_awid = 4'd0;
    assign m_awaddr = 32'd0;
    assign m_awlen = 8'd0;
    assign m_awsize = 3'd0;
    assign m_awburst = 2'd0;
    assign m_awcache = 4'd0;
    assign m_awprot = 3'd0;
    assign m_awvalid = 1'b0;
    assign m_wdata = 64'd0;
    assign m_wstrb = 8'd0;
    assign m_wlast = 1'b0;
    assign m_wvalid = 1'b0;
    assign m_bready = 1'b0;
    
    // AXI Master Read
    assign m_arid    = m_arid_r;
    assign m_araddr  = cur_addr;
    assign m_arlen   = BURST_SIZE - 1;
    assign m_arsize  = 3'd3;  // 8 bytes
    assign m_arburst = 2'b01;  // INCR
    assign m_arcache = 4'd3;
    assign m_arprot  = 3'd000;
    assign m_arvalid = (state == INIT_BURST);
    assign m_rready  = 1'b1;
    
    // ==========================================
    // AXI Slave Write Channel
    // ==========================================
    assign s_awready = (s_state == S_WWAIT);
    assign s_wready   = (s_state == S_WDATA);
    assign s_bid      = s_awid;
    assign s_bresp    = 2'b00;  // OKAY
    assign s_bvalid   = (s_state == S_WRESP);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_state <= S_IDLE;
            s_waddr_reg <= 32'd0;
            s_wcount <= 8'd0;
            sram_we_b_reg <= 1'b0;
            sram_wdata_b_reg <= 32'd0;
            sram_addr_b_reg <= 8'd0;
        end else begin
            case (s_state)
                S_IDLE: begin
                    if (s_awvalid && s_awready) begin
                        s_waddr_reg <= s_awaddr[9:2];  // Word address
                        s_wcount <= s_awlen;
                        s_state <= S_WWAIT;
                    end
                end
                S_WWAIT: begin
                    if (s_wvalid && s_wready) begin
                        sram_we_b_reg <= 1'b1;
                        sram_addr_b_reg <= s_waddr_reg;
                        sram_wdata_b_reg <= s_wdata[31:0];
                        s_waddr_reg <= s_waddr_reg + 1;
                        if (s_wcount == 8'd0) begin
                            s_state <= S_WRESP;
                        end else begin
                            s_wcount <= s_wcount - 1;
                        end
                    end else begin
                        sram_we_b_reg <= 1'b0;
                    end
                end
                S_WRESP: begin
                    sram_we_b_reg <= 1'b0;
                    if (s_bready && s_bvalid) begin
                        s_state <= S_IDLE;
                    end
                end
                default: s_state <= S_IDLE;
            endcase
        end
    end
    
    // ==========================================
    // AXI Slave Read Channel
    // ==========================================
    assign s_arready = (s_rstate == S_RWAIT);
    assign s_rid     = s_arid;
    assign s_rresp   = 2'b00;
    assign s_rlast   = (s_rcount == 8'd0);
    assign s_rvalid  = (s_rstate == S_RDATA);
    assign s_rdata   = s_rdata_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_rstate <= S_IDLE;
            s_raddr_reg <= 32'd0;
            s_rcount <= 8'd0;
            s_rdata_reg <= 64'd0;
        end else begin
            case (s_rstate)
                S_IDLE: begin
                    if (s_arvalid && s_arready) begin
                        s_raddr_reg <= s_araddr[9:2];
                        s_rcount <= s_arlen;
                        s_rstate <= S_RWAIT;
                    end
                end
                S_RWAIT: begin
                    if (s_rready && s_rvalid) begin
                        s_rdata_reg <= {32'd0, sram_rdata_a};
                        if (s_rcount == 8'd0) begin
                            s_rstate <= S_IDLE;
                        end else begin
                            s_raddr_reg <= s_raddr_reg + 1;
                            s_rcount <= s_rcount - 1;
                        end
                    end
                end
                default: s_rstate <= S_IDLE;
            endcase
        end
    end
    
    // ==========================================
    // SRAM Instance
    // ==========================================
    sram #(.DEPTH(SRAM_DEPTH), .WIDTH(32), .ADDR_W(8)) u_sram (
        .clk_a(clk),
        .we_a(sram_we_a),
        .addr_a(sram_addr_a),
        .wdata_a(sram_wdata_a),
        .rdata_a(sram_rdata_a),
        .clk_b(clk),
        .we_b(sram_we_b),
        .addr_b(sram_addr_b),
        .wdata_b(sram_wdata_b)
    );
    
    // PE writes results to SRAM
    assign sram_we_a = pe_valid;
    assign sram_addr_a = cur_addr[9:2];  // Simplified address
    assign sram_wdata_a = result[0];
    
    // ==========================================
    // PE Instances
    // ==========================================
    mac_array #(.WIDTH(DATA_WIDTH), .SIZE(VECTOR_WIDTH)) u_mac (
        .clk(clk), .rst_n(rst_n), .enable(is_mac & pe_valid),
        .a(data_a), .b(data_b), .result(mac_result)
    );
    
    activation_unit #(.WIDTH(DATA_WIDTH), .SIZE(VECTOR_WIDTH)) u_act (
        .clk(clk), .rst_n(rst_n), .enable(is_act & pe_valid),
        .act_type(act_type), .data_in(data_a), .data_out(act_result)
    );
    
    normalization_unit #(.WIDTH(DATA_WIDTH), .SIZE(VECTOR_WIDTH)) u_norm (
        .clk(clk), .rst_n(rst_n), .enable(is_norm & pe_valid),
        .norm_type(norm_type), .data_in(data_a), .data_out(norm_result)
    );
    
    // Result selection
    integer i_idx;
    always @(posedge clk) begin
        if (pe_valid) begin
            if (is_mac) begin
                for (i_idx = 0; i_idx < VECTOR_WIDTH; i_idx = i_idx + 1)
                    result[i_idx] <= mac_result[i_idx];
            end else if (is_act) begin
                for (i_idx = 0; i_idx < VECTOR_WIDTH; i_idx = i_idx + 1)
                    result[i_idx] <= act_result[i_idx];
            end else if (is_norm) begin
                for (i_idx = 0; i_idx < VECTOR_WIDTH; i_idx = i_idx + 1)
                    result[i_idx] <= norm_result[i_idx];
            end
        end
    end
    
    // Unpack AXI data
    integer j_idx;
    always @(posedge clk) begin
        if (m_rvalid && m_rready) begin
            for (j_idx = 0; j_idx < 2; j_idx = j_idx + 1) begin
                if (j_idx < VECTOR_WIDTH)
                    data_a[j_idx] <= m_rdata[(j_idx*32)+:32];
                if (j_idx < VECTOR_WIDTH)
                    data_b[j_idx] <= m_rdata[((j_idx+2)*32)+:32];
            end
        end
    end
    
    // ==========================================
    // Master FSM
    // ==========================================
    assign pe_valid = m_rvalid && m_rready;
    assign done = done_r;
    assign error = error_r;
    assign op_count = op_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cur_addr <= 32'd0;
            op_counter <= 8'd0;
            done_r <= 1'b0;
            error_r <= 1'b0;
            m_arid_r <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        cur_addr <= base_addr;
                        m_arid_r <= m_arid_r + 4'd1;
                        state <= INIT_BURST;
                        op_counter <= 8'd0;
                        done_r <= 1'b0;
                        error_r <= 1'b0;
                    end
                end
                INIT_BURST: begin
                    if (m_arvalid && m_arready) begin
                        state <= WAIT_RDATA;
                    end
                end
                WAIT_RDATA: begin
                    if (m_rvalid && m_rready) begin
                        if (m_rlast) begin
                            state <= PROCESS;
                        end
                    end
                end
                PROCESS: begin
                    op_counter <= op_counter + 8'd1;
                    state <= NEXT_OP;
                end
                NEXT_OP: begin
                    if (op_counter >= 8'd15) begin
                        state <= DONE;
                        done_r <= 1'b1;
                    end else begin
                        cur_addr <= cur_addr + (BURST_SIZE * 8);
                        state <= INIT_BURST;
                    end
                end
                DONE: begin
                    if (!start) begin
                        state <= IDLE;
                        done_r <= 1'b0;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule

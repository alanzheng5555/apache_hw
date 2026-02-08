// NoC Router Module - Traffic Monitor
// Counts packets, bytes, and measures latency

`timescale 1ns/1ps

module traffic_monitor #(
    parameter PORTS = 3,
    parameter CNT_W = 64  // 64-bit counters
)(
    // System
    input  wire                 clk,
    input  wire                 rst_n,
    
    // APB Interface
    input  wire [11:0]          paddr,
    input  wire [31:0]         pwdata,
    input  wire                 pwrite,
    input  wire                 psel,
    input  wire                 penable,
    output wire                 pready,
    output wire [31:0]         prdata,
    
    // Port Statistics (Input)
    input  wire [PORTS-1:0]     in_pkt_valid,
    input  wire [PORTS-1:0]     in_pkt_last,
    input  wire [63:0]         in_byte_cnt [PORTS-1:0],
    input  wire [31:0]         in_latency [PORTS-1:0],
    
    // Port Statistics (Output)
    input  wire [PORTS-1:0]     out_pkt_valid,
    input  wire [PORTS-1:0]     out_pkt_last,
    input  wire [63:0]         out_byte_cnt [PORTS-1:0],
    input  wire [31:0]         out_latency [PORTS-1:0]
);
    
    // Counters
    reg [CNT_W-1:0] pkt_cnt_in [0:PORTS-1];
    reg [CNT_W-1:0] byte_cnt_in [0:PORTS-1];
    reg [CNT_W-1:0] lat_min_in [0:PORTS-1];
    reg [CNT_W-1:0] lat_max_in [0:PORTS-1];
    reg [CNT_W-1:0] pkt_cnt_out [0:PORTS-1];
    reg [CNT_W-1:0] byte_cnt_out [0:PORTS-1];
    reg [CNT_W-1:0] lat_min_out [0:PORTS-1];
    reg [CNT_W-1:0] lat_max_out [0:PORTS-1];
    
    // Control
    reg clear_counters;
    
    // APB FSM
    reg [1:0] apb_state;
    localparam APB_IDLE = 2'd0;
    localparam APB_ACCESS = 2'd1;
    
    assign pready = (apb_state == APB_ACCESS);
    
    // Read data mux
    reg [31:0] prdata_reg;
    assign prdata = prdata_reg;
    
    always @(*) begin
        prdata_reg = 32'd0;
        if (psel && !pwrite) begin
            case (paddr[11:2])
                // Input port 0
                10'd0: prdata_reg = pkt_cnt_in[0][31:0];
                10'd1: prdata_reg = byte_cnt_in[0][31:0];
                10'd2: prdata_reg = lat_min_in[0][31:0];
                10'd3: prdata_reg = lat_max_in[0][31:0];
                // Input port 1
                10'd4: prdata_reg = pkt_cnt_in[1][31:0];
                10'd5: prdata_reg = byte_cnt_in[1][31:0];
                10'd6: prdata_reg = lat_min_in[1][31:0];
                10'd7: prdata_reg = lat_max_in[1][31:0];
                // Input port 2
                10'd8: prdata_reg = pkt_cnt_in[2][31:0];
                10'd9: prdata_reg = byte_cnt_in[2][31:0];
                10'd10: prdata_reg = lat_min_in[2][31:0];
                10'd11: prdata_reg = lat_max_in[2][31:0];
                // Output port 0
                10'd16: prdata_reg = pkt_cnt_out[0][31:0];
                10'd17: prdata_reg = byte_cnt_out[0][31:0];
                10'd18: prdata_reg = lat_min_out[0][31:0];
                10'd19: prdata_reg = lat_max_out[0][31:0];
                // Output port 1
                10'd20: prdata_reg = pkt_cnt_out[1][31:0];
                10'd21: prdata_reg = byte_cnt_out[1][31:0];
                10'd22: prdata_reg = lat_min_out[1][31:0];
                10'd23: prdata_reg = lat_max_out[1][31:0];
                // Output port 2
                10'd24: prdata_reg = pkt_cnt_out[2][31:0];
                10'd25: prdata_reg = byte_cnt_out[2][31:0];
                10'd26: prdata_reg = lat_min_out[2][31:0];
                10'd27: prdata_reg = lat_max_out[2][31:0];
            endcase
        end
    end
    
    // Counter update
    integer port_idx;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear_counters) begin
            for (port_idx = 0; port_idx < PORTS; port_idx = port_idx + 1) begin
                pkt_cnt_in[port_idx] <= 64'd0;
                byte_cnt_in[port_idx] <= 64'd0;
                lat_min_in[port_idx] <= {CNT_W{1'b1}};
                lat_max_in[port_idx] <= 64'd0;
                pkt_cnt_out[port_idx] <= 64'd0;
                byte_cnt_out[port_idx] <= 64'd0;
                lat_min_out[port_idx] <= {CNT_W{1'b1}};
                lat_max_out[port_idx] <= 64'd0;
            end
        end else begin
            // Input counters
            for (port_idx = 0; port_idx < PORTS; port_idx = port_idx + 1) begin
                if (in_pkt_valid[port_idx]) begin
                    pkt_cnt_in[port_idx] <= pkt_cnt_in[port_idx] + 64'd1;
                    byte_cnt_in[port_idx] <= byte_cnt_in[port_idx] + in_byte_cnt[port_idx];
                    
                    if (in_latency[port_idx] < lat_min_in[port_idx])
                        lat_min_in[port_idx] <= in_latency[port_idx];
                    if (in_latency[port_idx] > lat_max_in[port_idx])
                        lat_max_in[port_idx] <= in_latency[port_idx];
                end
                
                if (out_pkt_valid[port_idx]) begin
                    pkt_cnt_out[port_idx] <= pkt_cnt_out[port_idx] + 64'd1;
                    byte_cnt_out[port_idx] <= byte_cnt_out[port_idx] + out_byte_cnt[port_idx];
                    
                    if (out_latency[port_idx] < lat_min_out[port_idx])
                        lat_min_out[port_idx] <= out_latency[port_idx];
                    if (out_latency[port_idx] > lat_max_out[port_idx])
                        lat_max_out[port_idx] <= out_latency[port_idx];
                end
            end
        end
    end
    
    // APB Write FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            apb_state <= APB_IDLE;
            clear_counters <= 1'b0;
        end else begin
            case (apb_state)
                APB_IDLE: begin
                    if (psel && penable) begin
                        apb_state <= APB_ACCESS;
                        if (pwrite && paddr[11:2] == 10'd255) begin
                            clear_counters <= pwdata[0];
                        end
                    end
                end
                APB_ACCESS: begin
                    apb_state <= APB_IDLE;
                    clear_counters <= 1'b0;
                end
                default: apb_state <= APB_IDLE;
            endcase
        end
    end
    
endmodule

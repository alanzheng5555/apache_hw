// UCIe Top-Level Module
// Universal Chiplet Interconnect Express
// Based on UCIe 1.0 Specification

`timescale 1ns/1ps

module ucsie_top #(
    parameter NUM_LANES = 16,           // 1-16 lanes
    parameter DATA_W = 256,             // 256-bit data path
    parameter ADDR_W = 64,              // 64-bit address
    parameter IDE_ENABLE = 1,           // Integrity & Data Encryption
    parameter RETIMER_ENABLE = 0,        // Retimer support
    parameter MAX_PACKET_SIZE = 4096    // Max protocol packet size
)(
    // ==========================================
    // System Interface
    // ==========================================
    input  wire                 clk,
    input  wire                 rst_n,
    
    // ==========================================
    // Protocol Layer Interface (PCIe/CXL)
    // ==========================================
    // Transmit (TX)
    input  wire                 tx_valid,
    output wire                 tx_ready,
    input  wire [DATA_W-1:0]    tx_data,
    input  wire [(DATA_W/8)-1:0] tx_strb,
    input  wire                 tx_sop,      // Start of packet
    input  wire                 tx_eop,      // End of packet
    
    // Receive (RX)
    output wire                 rx_valid,
    input  wire                 rx_ready,
    output wire [DATA_W-1:0]    rx_data,
    output wire [(DATA_W/8)-1:0] rx_strb,
    output wire                 rx_sop,
    output wire                 rx_eop,
    
    // ==========================================
    // Physical Layer Interface (Analog)
    // ==========================================
    // TX (to remote chiplet)
    output wire [NUM_LANES-1:0]  tx_lane_p,
    output wire [NUM_LANES-1:0]  tx_lane_n,
    output wire                 tx_clk_p,
    output wire                 tx_clk_n,
    output wire                 tx_strobe,
    
    // RX (from remote chiplet)
    input  wire [NUM_LANES-1:0]  rx_lane_p,
    input  wire [NUM_LANES-1:0]  rx_lane_n,
    input  wire                 rx_clk_p,
    input  wire                 rx_clk_n,
    input  wire                 rx_strobe,
    
    // ==========================================
    // Sideband Interface (Management)
    // ==========================================
    output wire                 sb_tx,
    input  wire                 sb_rx,
    
    // ==========================================
    // Link Status & Control
    // ==========================================
    output wire [3:0]          link_status,  // {init_done, train_done, lane_up, phy_up}
    output wire [7:0]          lane_status,  // Per-lane status
    input  wire [15:0]          credit_init,
    output wire [15:0]          credit_return
);

    // ==========================================
    // Local Parameters
    // ==========================================
    localparam ST_WIDTH = NUM_LANES == 16 ? 4 :
                         NUM_LANES == 8  ? 3 :
                         NUM_LANES == 4  ? 2 :
                         NUM_LANES == 2  ? 1 : 0;
    
    // ==========================================
    // Internal Signals
    // ==========================================
    
    // Adapter <-> PHY signals
    wire [DATA_W-1:0]   phy_tx_data;
    wire [(DATA_W/8)-1:0] phy_tx_strb;
    wire [ST_WIDTH:0]   phy_tx_header;
    wire                 phy_tx_valid;
    wire                 phy_tx_ready;
    wire                 phy_tx_sop;
    wire                 phy_tx_eop;
    
    wire [DATA_W-1:0]   phy_rx_data;
    wire [(DATA_W/8)-1:0] phy_rx_strb;
    wire [ST_WIDTH:0]   phy_rx_header;
    wire                 phy_rx_valid;
    wire                 phy_rx_ready;
    wire                 phy_rx_sop;
    wire                 phy_rx_eop;
    
    // Flow control
    wire [7:0]           tx_credit;
    wire [7:0]           rx_credit;
    
    // Link status
    wire                 link_training;
    wire                 link_ready;
    wire                 reg_access_ready;
    
    // ==========================================
    // Instantiate Sub-blocks
    // ==========================================
    
    // ==========================================
    // UCIe Adapter Layer
    // Handles protocol packetization, credit management
    // ==========================================
    ucsie_adapter #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W),
        .MAX_PKT_SIZE(MAX_PACKET_SIZE),
        .NUM_LANES(NUM_LANES)
    ) u_adapter (
        .clk(clk),
        .rst_n(rst_n),
        
        // Protocol interface
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx_data(tx_data),
        .tx_strb(tx_strb),
        .tx_sop(tx_sop),
        .tx_eop(tx_eop),
        
        .rx_valid(rx_valid),
        .rx_ready(rx_ready),
        .rx_data(rx_data),
        .rx_strb(rx_strb),
        .rx_sop(rx_sop),
        .rx_eop(rx_eop),
        
        // PHY interface
        .phy_tx_data(phy_tx_data),
        .phy_tx_strb(phy_tx_strb),
        .phy_tx_header(phy_tx_header),
        .phy_tx_valid(phy_tx_valid),
        .phy_tx_ready(phy_tx_ready),
        .phy_tx_sop(phy_tx_sop),
        .phy_tx_eop(phy_tx_eop),
        
        .phy_rx_data(phy_rx_data),
        .phy_rx_strb(phy_rx_strb),
        .phy_rx_header(phy_rx_header),
        .phy_rx_valid(phy_rx_valid),
        .phy_rx_ready(phy_rx_ready),
        .phy_rx_sop(phy_rx_sop),
        .phy_rx_eop(phy_rx_eop),
        
        // Flow control
        .tx_credit(tx_credit),
        .rx_credit(rx_credit),
        
        // Status
        .reg_access_ready(reg_access_ready)
    );
    
    // ==========================================
    // UCIe Physical Layer
    // Handles lane bonding, serializer/deserializer,
    // clock data recovery, and link training
    // ==========================================
    ucsie_phy #(
        .NUM_LANES(NUM_LANES),
        .DATA_W(DATA_W),
        .IDE_ENABLE(IDE_ENABLE)
    ) u_phy (
        .clk(clk),
        .rst_n(rst_n),
        
        // Adapter interface
        .tx_data(phy_tx_data),
        .tx_strb(phy_tx_strb),
        .tx_header(phy_tx_header),
        .tx_valid(phy_tx_valid),
        .tx_ready(phy_tx_ready),
        .tx_sop(phy_tx_sop),
        .tx_eop(phy_tx_eop),
        
        .rx_data(phy_rx_data),
        .rx_strb(phy_rx_strb),
        .rx_header(phy_rx_header),
        .rx_valid(phy_rx_valid),
        .rx_ready(phy_rx_ready),
        .rx_sop(phy_rx_sop),
        .rx_eop(phy_rx_eop),
        
        // Flow control
        .tx_credit(rx_credit),
        .rx_credit(tx_credit),
        
        // Lane interfaces
        .tx_lane_p(tx_lane_p),
        .tx_lane_n(tx_lane_n),
        .tx_clk_p(tx_clk_p),
        .tx_clk_n(tx_clk_n),
        .tx_strobe(tx_strobe),
        
        .rx_lane_p(rx_lane_p),
        .rx_lane_n(rx_lane_n),
        .rx_clk_p(rx_clk_p),
        .rx_clk_n(rx_clk_n),
        .rx_strobe(rx_strobe),
        
        // Sideband
        .sb_tx(sb_tx),
        .sb_rx(sb_rx),
        
        // Status
        .link_training(link_training),
        .link_ready(link_ready),
        .lane_status(lane_status)
    );
    
    // ==========================================
    // Status Outputs
    // ==========================================
    assign link_status = {reg_access_ready, link_ready, |lane_status, link_training};
    assign credit_return = {8{1'b1}};  // Full credits

endmodule

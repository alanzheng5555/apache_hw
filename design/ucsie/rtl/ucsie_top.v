// UCIe Top-Level Module with AXI Controller
// Universal Chiplet Interconnect Express
// Based on UCIe 1.0 Specification

`timescale 1ns/1ps

module ucsie_top #(
    parameter NUM_LANES = 16,           // 1-16 lanes
    parameter DATA_W = 256,             // 256-bit data path
    parameter ADDR_W = 64,              // 64-bit address
    parameter ID_W = 4,                  // AXI ID width
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
    // AXI4 Master Interface (Initiator)
    // ==========================================
    // Write Address Channel
    output wire [ID_W-1:0]     m_awid,
    output wire [ADDR_W-1:0]    m_awaddr,
    output wire [7:0]          m_awlen,
    output wire [2:0]          m_awsize,
    output wire [1:0]          m_awburst,
    output wire                 m_awvalid,
    input  wire                 m_awready,
    
    // Write Data Channel
    output wire [DATA_W-1:0]    m_wdata,
    output wire [(DATA_W/8)-1:0] m_wstrb,
    output wire                 m_wlast,
    output wire                 m_wvalid,
    input  wire                 m_wready,
    
    // Write Response Channel
    input  wire [ID_W-1:0]     m_bid,
    input  wire [1:0]          m_bresp,
    input  wire                 m_bvalid,
    output wire                 m_bready,
    
    // Read Address Channel
    output wire [ID_W-1:0]     m_arid,
    output wire [ADDR_W-1:0]    m_araddr,
    output wire [7:0]          m_arlen,
    output wire [2:0]          m_arsize,
    output wire [1:0]          m_arburst,
    output wire                 m_arvalid,
    input  wire                 m_arready,
    
    // Read Data Channel
    input  wire [ID_W-1:0]     m_rid,
    input  wire [DATA_W-1:0]    m_rdata,
    input  wire [1:0]          m_rresp,
    input  wire                 m_rlast,
    input  wire                 m_rvalid,
    output wire                 m_rready,
    
    // ==========================================
    // AXI4 Slave Interface (Responder)
    // ==========================================
    // Write Address Channel
    input  wire [ID_W-1:0]     s_awid,
    input  wire [ADDR_W-1:0]    s_awaddr,
    input  wire [7:0]          s_awlen,
    input  wire [2:0]          s_awsize,
    input  wire [1:0]          s_awburst,
    input  wire                 s_awvalid,
    output wire                 s_awready,
    
    // Write Data Channel
    input  wire [DATA_W-1:0]    s_wdata,
    input  wire [(DATA_W/8)-1:0] s_wstrb,
    input  wire                 s_wlast,
    input  wire                 s_wvalid,
    output wire                 s_wready,
    
    // Write Response Channel
    output wire [ID_W-1:0]     s_bid,
    output wire [1:0]          s_bresp,
    output wire                 s_bvalid,
    input  wire                 s_bready,
    
    // Read Address Channel
    input  wire [ID_W-1:0]     s_arid,
    input  wire [ADDR_W-1:0]    s_araddr,
    input  wire [7:0]          s_arlen,
    input  wire [2:0]          s_arsize,
    input  wire [1:0]          s_arburst,
    input  wire                 s_arvalid,
    output wire                 s_arready,
    
    // Read Data Channel
    output wire [ID_W-1:0]     s_rid,
    output wire [DATA_W-1:0]    s_rdata,
    output wire [1:0]          s_rresp,
    output wire                 s_rlast,
    output wire                 s_rvalid,
    input  wire                 s_rready,
    
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
    // Control & Status
    // ==========================================
    input  wire                 ctrl_enable,
    output wire                 ctrl_ready,
    output wire [31:0]          ctrl_status,
    output wire [3:0]          link_status,  // {init_done, train_done, lane_up, phy_up}
    output wire [7:0]          lane_status   // Per-lane status
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
    
    // Controller <-> PHY signals
    wire [DATA_W-1:0]   phy_tx_data;
    wire [(DATA_W/8)-1:0] phy_tx_strb;
    wire [3:0]          phy_tx_header;
    wire                 phy_tx_valid;
    wire                 phy_tx_ready;
    wire                 phy_tx_sop;
    wire                 phy_tx_eop;
    
    wire [DATA_W-1:0]   phy_rx_data;
    wire [(DATA_W/8)-1:0] phy_rx_strb;
    wire [3:0]          phy_rx_header;
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
    // Instantiate UCIe Controller (AXI Bridge)
    // ==========================================
    ucsie_controller #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W),
        .ID_W(ID_W),
        .NUM_LANES(NUM_LANES),
        .IDE_ENABLE(IDE_ENABLE)
    ) u_controller (
        .clk(clk),
        .rst_n(rst_n),
        
        // AXI Master (initiate remote requests)
        .m_awid(m_awid),
        .m_awaddr(m_awaddr),
        .m_awlen(m_awlen),
        .m_awsize(m_awsize),
        .m_awburst(m_awburst),
        .m_awvalid(m_awvalid),
        .m_awready(m_awready),
        .m_wdata(m_wdata),
        .m_wstrb(m_wstrb),
        .m_wlast(m_wlast),
        .m_wvalid(m_wvalid),
        .m_wready(m_wready),
        .m_bid(m_bid),
        .m_bresp(m_bresp),
        .m_bvalid(m_bvalid),
        .m_bready(m_bready),
        .m_arid(m_arid),
        .m_araddr(m_araddr),
        .m_arlen(m_arlen),
        .m_arsize(m_arsize),
        .m_arburst(m_arburst),
        .m_arvalid(m_arvalid),
        .m_arready(m_arready),
        .m_rid(m_rid),
        .m_rdata(m_rdata),
        .m_rresp(m_rresp),
        .m_rlast(m_rlast),
        .m_rvalid(m_rvalid),
        .m_rready(m_rready),
        
        // AXI Slave (respond to remote requests)
        .s_awid(s_awid),
        .s_awaddr(s_awaddr),
        .s_awlen(s_awlen),
        .s_awsize(s_awsize),
        .s_awburst(s_awburst),
        .s_awvalid(s_awvalid),
        .s_awready(s_awready),
        .s_wdata(s_wdata),
        .s_wstrb(s_wstrb),
        .s_wlast(s_wlast),
        .s_wvalid(s_wvalid),
        .s_wready(s_wready),
        .s_bid(s_bid),
        .s_bresp(s_bresp),
        .s_bvalid(s_bvalid),
        .s_bready(s_bready),
        .s_arid(s_arid),
        .s_araddr(s_araddr),
        .s_arlen(s_arlen),
        .s_arsize(s_arsize),
        .s_arburst(s_arburst),
        .s_arvalid(s_arvalid),
        .s_arready(s_arready),
        .s_rid(s_rid),
        .s_rdata(s_rdata),
        .s_rresp(s_rresp),
        .s_rlast(s_rlast),
        .s_rvalid(s_rvalid),
        .s_rready(s_rready),
        
        // UCIe PHY TX
        .ucsie_tx_valid(phy_tx_valid),
        .ucsie_tx_ready(phy_tx_ready),
        .ucsie_tx_data(phy_tx_data),
        .ucsie_tx_strb(phy_tx_strb),
        .ucsie_tx_sop(phy_tx_sop),
        .ucsie_tx_eop(phy_tx_eop),
        
        // UCIe PHY RX
        .ucsie_rx_ready(phy_rx_ready),
        .ucsie_rx_valid(phy_rx_valid),
        .ucsie_rx_data(phy_rx_data),
        .ucsie_rx_strb(phy_rx_strb),
        .ucsie_rx_sop(phy_rx_sop),
        .ucsie_rx_eop(phy_rx_eop),
        
        // Link status
        .ucsie_link_status({reg_access_ready, link_ready, |lane_status, link_training}),
        .ucsie_lane_status(lane_status),
        
        // Control
        .ctrl_enable(ctrl_enable),
        .ctrl_ready(ctrl_ready),
        .ctrl_status(ctrl_status),
        .ctrl_config(32'd0)
    );
    
    // ==========================================
    // Instantiate UCIe Adapter Layer
    // ==========================================
    ucsie_adapter #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W),
        .MAX_PKT_SIZE(MAX_PACKET_SIZE),
        .NUM_LANES(NUM_LANES)
    ) u_adapter (
        .clk(clk),
        .rst_n(rst_n),
        
        // PHY TX
        .tx_valid(phy_tx_valid),
        .tx_ready(phy_tx_ready),
        .tx_data(phy_tx_data),
        .tx_strb(phy_tx_strb),
        .tx_sop(phy_tx_sop),
        .tx_eop(phy_tx_eop),
        
        // PHY RX
        .rx_valid(phy_rx_valid),
        .rx_ready(phy_rx_ready),
        .rx_data(phy_rx_data),
        .rx_strb(phy_rx_strb),
        .rx_sop(phy_rx_sop),
        .rx_eop(phy_rx_eop),
        
        // Flow control
        .tx_credit(tx_credit),
        .rx_credit(rx_credit),
        
        // Status
        .reg_access_ready(reg_access_ready)
    );
    
    // ==========================================
    // Instantiate UCIe Physical Layer
    // ==========================================
    ucsie_phy #(
        .NUM_LANES(NUM_LANES),
        .DATA_W(DATA_W),
        .IDE_ENABLE(IDE_ENABLE)
    ) u_phy (
        .clk(clk),
        .rst_n(rst_n),
        
        // Adapter TX
        .tx_data(phy_tx_data),
        .tx_strb(phy_tx_strb),
        .tx_header(phy_tx_header),
        .tx_valid(phy_tx_valid),
        .tx_ready(phy_tx_ready),
        .tx_sop(phy_tx_sop),
        .tx_eop(phy_tx_eop),
        
        // Adapter RX
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

endmodule

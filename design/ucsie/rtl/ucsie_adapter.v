// UCIe Adapter Layer
// Handles protocol packetization, credit management,
// and protocol-layer flow control

`timescale 1ns/1ps

module ucsie_adapter #(
    parameter DATA_W = 256,
    parameter ADDR_W = 64,
    parameter MAX_PKT_SIZE = 4096,
    parameter NUM_LANES = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    
    // ==========================================
    // Protocol Interface (PCIe/CXL)
    // ==========================================
    // Transmit
    input  wire                 tx_valid,
    output wire                 tx_ready,
    input  wire [DATA_W-1:0]    tx_data,
    input  wire [(DATA_W/8)-1:0] tx_strb,
    input  wire                 tx_sop,
    input  wire                 tx_eop,
    
    // Receive
    output wire                 rx_valid,
    input  wire                 rx_ready,
    output wire [DATA_W-1:0]    rx_data,
    output wire [(DATA_W/8)-1:0] rx_strb,
    output wire                 rx_sop,
    output wire                 rx_eop,
    
    // ==========================================
    // PHY Interface
    // ==========================================
    output wire [DATA_W-1:0]   phy_tx_data,
    output wire [(DATA_W/8)-1:0] phy_tx_strb,
    output wire [3:0]          phy_tx_header,
    output wire                 phy_tx_valid,
    input  wire                 phy_tx_ready,
    output wire                 phy_tx_sop,
    output wire                 phy_tx_eop,
    
    input  wire [DATA_W-1:0]   phy_rx_data,
    input  wire [(DATA_W/8)-1:0] phy_rx_strb,
    input  wire [3:0]          phy_rx_header,
    input  wire                 phy_rx_valid,
    output wire                 phy_rx_ready,
    input  wire                 phy_rx_sop,
    input  wire                 phy_rx_eop,
    
    // ==========================================
    // Flow Control
    // ==========================================
    input  wire [7:0]           tx_credit,     // Credit from RX
    output wire [7:0]           rx_credit,     // Credit to TX
    
    // ==========================================
    // Status
    // ==========================================
    output wire                 reg_access_ready
);

    // ==========================================
    // Parameters
    // ==========================================
    localparam HDR_W = 64;              // Header width
    localparam DLLP_W = 16;             // Data Link Layer Packet
    localparam TLP_W = DATA_W + HDR_W;  // Transaction Layer Packet
    
    localparam ST_BYTES = DATA_W / 8;
    localparam HEADER_BYTES = 16;
    
    // ==========================================
    // State Machine States
    // ==========================================
    localparam IDLE        = 4'd0;
    localparam SEND_TLP    = 4'd1;
    localparam SEND_HEADER  = 4'd2;
    localparam SEND_DATA    = 4'd3;
    localparam SEND_DLLP   = 4'd4;
    localparam WAIT_CREDIT = 4'd5;
    
    // ==========================================
    // TX Signals
    // ==========================================
    reg [3:0]           tx_state;
    reg [15:0]          tx_byte_count;
    reg [15:0]          tx_rem_bytes;
    reg [11:0]          tx_dlp_seq;
    reg                 tx_in_progress;
    reg [DATA_W-1:0]    tx_data_reg;
    reg [(DATA_W/8)-1:0] tx_strb_reg;
    reg                 tx_sop_reg;
    reg                 tx_eop_reg;
    reg [7:0]           tx_credit_count;
    reg [7:0]           tx_credit_alloc;
    
    // TX FIFO
    reg [TLP_W-1:0]     tx_tlp_fifo [0:15];
    reg [3:0]           tx_wr_ptr;
    reg [3:0]           tx_rd_ptr;
    wire                tx_fifo_empty;
    wire                tx_fifo_full;
    
    // ==========================================
    // RX Signals
    // ==========================================
    reg [3:0]           rx_state;
    reg [15:0]          rx_byte_count;
    reg [15:0]          rx_rem_bytes;
    reg                 rx_in_progress;
    reg [DATA_W-1:0]    rx_data_reg;
    reg [(DATA_W/8)-1:0] rx_strb_reg;
    reg                 rx_sop_reg;
    reg                 rx_eop_reg;
    reg [7:0]           rx_credit_count;
    
    // RX FIFO
    reg [TLP_W-1:0]     rx_tlp_fifo [0:15];
    reg [3:0]           rx_wr_ptr;
    reg [3:0]           rx_rd_ptr;
    wire                rx_fifo_empty;
    wire                rx_fifo_full;
    
    // ==========================================
    // Assignments
    // ==========================================
    assign tx_ready = (tx_state == IDLE) && (tx_credit_count > 0);
    assign phy_tx_valid = (tx_state != IDLE) && (tx_fifo_empty == 1'b0);
    assign phy_tx_sop = (tx_state == SEND_HEADER);
    assign phy_tx_eop = (tx_state == SEND_DATA) && (tx_rem_bytes == 0);
    
    assign phy_rx_ready = (rx_state == IDLE) || ((rx_state == RECEIVE) && (rx_fifo_full == 1'b0));
    
    assign rx_valid = (rx_state == IDLE) && (rx_fifo_empty == 1'b0);
    assign rx_sop = rx_sop_reg;
    assign rx_eop = rx_eop_reg;
    
    assign reg_access_ready = (tx_state == IDLE) && (rx_state == IDLE);
    
    // Credit management
    assign rx_credit = 8'd16;  // Fixed credit allocation
    
    // FIFO status
    assign tx_fifo_empty = (tx_wr_ptr == tx_rd_ptr);
    assign tx_fifo_full = (tx_wr_ptr + 1) == tx_rd_ptr;
    assign rx_fifo_empty = (rx_wr_ptr == rx_rd_ptr);
    assign rx_fifo_full = (rx_wr_ptr + 1) == rx_rd_ptr;
    
    // ==========================================
    // TX Path
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE;
            tx_credit_count <= 8'd0;
            tx_dlp_seq <= 12'd0;
            tx_wr_ptr <= 4'd0;
            tx_rd_ptr <= 4'd0;
        end else begin
            case (tx_state)
                IDLE: begin
                    if (tx_valid && (tx_credit_count > 0)) begin
                        // Accept TLP
                        tx_data_reg <= tx_data;
                        tx_strb_reg <= tx_strb;
                        tx_sop_reg <= tx_sop;
                        tx_eop_reg <= tx_eop;
                        
                        // Calculate bytes
                        if (tx_eop && tx_sop) begin
                            // Single segment packet
                            tx_byte_count <= tx_sop ? DATA_W/8 : 16;
                            tx_rem_bytes <= 0;
                        end else begin
                            tx_byte_count <= DATA_W/8;
                            tx_rem_bytes <= DATA_W/8;
                        end
                        
                        // Use credit
                        tx_credit_count <= tx_credit_count - 1;
                        tx_state <= SEND_HEADER;
                    end
                end
                
                SEND_HEADER: begin
                    if (phy_tx_ready) begin
                        // Send header
                        tx_state <= SEND_DATA;
                        tx_rem_bytes <= (tx_byte_count > DATA_W/8) ? 
                                        tx_byte_count - DATA_W/8 : 16'd0;
                    end
                end
                
                SEND_DATA: begin
                    if (phy_tx_ready) begin
                        if (tx_rem_bytes > 0) begin
                            // More data to send
                            tx_state <= SEND_DATA;
                        end else begin
                            // Packet complete
                            tx_dlp_seq <= tx_dlp_seq + 1;
                            tx_state <= IDLE;
                        end
                    end
                end
            endcase
            
            // Credit update
            if (phy_rx_valid && phy_rx_sop) begin
                // Received DLLP with credits
                tx_credit_count <= tx_credit_count + rx_credit;
            end
        end
    end
    
    // TX header construction
    assign phy_tx_header = {
        3'd0,                    // Reserved
        4'd0,                    // Attr
        1'b0,                    // EP
        2'b00,                   // TD, EP
        3'd0,                    // Type
        4'd0,                    // Fmt
        12'd0,                   // Length
        32'd0                    // Address (simplified)
    };
    
    // ==========================================
    // RX Path
    // ==========================================
    localparam RECEIVE = 4'd6;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= IDLE;
            rx_credit_count <= 8'd16;
            rx_wr_ptr <= 4'd0;
            rx_rd_ptr <= 4'd0;
        end else begin
            case (rx_state)
                IDLE: begin
                    if (phy_rx_valid && phy_rx_ready) begin
                        if (phy_rx_sop) begin
                            // Start of new packet
                            rx_byte_count <= DATA_W/8;
                            rx_rem_bytes <= DATA_W/8;
                            rx_sop_reg <= 1'b1;
                            rx_state <= RECEIVE;
                        end else if (phy_rx_sop == 1'b0) begin
                            // DLLP
                            rx_credit_count <= rx_credit_count + 
                                phy_rx_data[7:0];
                            rx_state <= IDLE;
                        end
                    end
                end
                
                RECEIVE: begin
                    if (phy_rx_valid && phy_rx_ready) begin
                        rx_data_reg <= phy_rx_data;
                        rx_strb_reg <= phy_rx_strb;
                        rx_eop_reg <= phy_rx_eop;
                        
                        if (phy_rx_eop) begin
                            // Packet complete
                            rx_wr_ptr <= rx_wr_ptr + 1;
                            rx_sop_reg <= 1'b0;
                            rx_state <= IDLE;
                        end else begin
                            rx_rem_bytes <= rx_rem_bytes - DATA_W/8;
                        end
                    end
                end
            endcase
        end
    end
    
endmodule

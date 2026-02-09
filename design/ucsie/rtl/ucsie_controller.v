// UCIe Controller - AXI Interface
// Bridges AXI4 transactions to UCIe protocol

`timescale 1ns/1ps

module ucsie_controller #(
    parameter DATA_W = 256,           // 256-bit data path
    parameter ADDR_W = 64,            // 64-bit address
    parameter ID_W = 4,              // AXI ID width
    parameter NUM_LANES = 16,         // UCIe lanes
    parameter MAX_BURST = 256,        // Max burst length
    parameter IDE_ENABLE = 1,         // Enable encryption
    parameter RETIMER_ENABLE = 0      // Retimer support
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
    // UCIe PHY Interface
    // ==========================================
    // TX to remote chiplet
    input  wire                 ucsie_tx_ready,
    output wire                 ucsie_tx_valid,
    output wire [DATA_W-1:0]    ucsie_tx_data,
    output wire [(DATA_W/8)-1:0] ucsie_tx_strb,
    output wire                 ucsie_tx_sop,
    output wire                 ucsie_tx_eop,
    
    // RX from remote chiplet
    output wire                 ucsie_rx_ready,
    input  wire                 ucsie_rx_valid,
    input  wire [DATA_W-1:0]    ucsie_rx_data,
    input  wire [(DATA_W/8)-1:0] ucsie_rx_strb,
    input  wire                 ucsie_rx_sop,
    input  wire                 ucsie_rx_eop,
    
    // ==========================================
    // Link Status
    // ==========================================
    input  wire [3:0]          ucsie_link_status,
    input  wire [7:0]          ucsie_lane_status,
    
    // ==========================================
    // Control & Status
    // ==========================================
    input  wire                 ctrl_enable,
    output wire                 ctrl_ready,
    output wire [31:0]         ctrl_status,
    input  wire [31:0]          ctrl_config
);

    // ==========================================
    // Parameters
    // ==========================================
    localparam IDLE = 4'd0;
    localparam SEND_WRITE = 4'd1;
    localparam SEND_READ = 4'd2;
    localparam WAIT_RESP = 4'd3;
    localparam RECV_WRITE = 4'd4;
    localparam RECV_READ = 4'd5;
    localparam SEND_READ_DATA = 4'd6;
    
    // ==========================================
    // Write FIFO (AXI Slave → UCIe TX)
    // ==========================================
    reg [ADDR_W+32+8+3+2+ID_W-1:0] write_fifo [0:15];
    reg [3:0] wr_fifo_wrptr;
    reg [3:0] wr_fifo_rdptr;
    wire wr_fifo_empty;
    wire wr_fifo_full;
    
    assign wr_fifo_empty = (wr_fifo_wrptr == wr_fifo_rdptr);
    assign wr_fifo_full = ((wr_fifo_wrptr + 1) == wr_fifo_rdptr) ||
                         ((wr_fifo_wrptr == 4'd15) && (wr_fifo_rdptr == 4'd0));
    
    // ==========================================
    // Read FIFO (AXI Slave → UCIe TX)
    // ==========================================
    reg [ADDR_W+32+8+3+2+ID_W-1:0] read_fifo [0:15];
    reg [3:0] rd_fifo_wrptr;
    reg [3:0] rd_fifo_rdptr;
    wire rd_fifo_empty;
    wire rd_fifo_full;
    
    assign rd_fifo_empty = (rd_fifo_wrptr == rd_fifo_rdptr);
    assign rd_fifo_full = ((rd_fifo_wrptr + 1) == rd_fifo_rdptr) ||
                          ((rd_fifo_wrptr == 4'd15) && (rd_fifo_rdptr == 4'd0));
    
    // ==========================================
    // Response FIFO (UCIe RX → AXI Master)
    // ==========================================
    reg [DATA_W+2+1+ID_W-1:0] resp_fifo [0:31];
    reg [4:0] resp_fifo_wrptr;
    reg [4:0] resp_fifo_rdptr;
    wire resp_fifo_empty;
    wire resp_fifo_full;
    
    assign resp_fifo_empty = (resp_fifo_wrptr == resp_fifo_rdptr);
    assign resp_fifo_full = ((resp_fifo_wrptr + 1) == resp_fifo_rdptr) ||
                             ((resp_fifo_wrptr == 5'd31) && (resp_fifo_rdptr == 5'd0));
    
    // ==========================================
    // Read Data FIFO (UCIe RX → AXI Slave)
    // ==========================================
    reg [DATA_W+2+1+ID_W-1:0] rdata_fifo [0:31];
    reg [4:0] rdata_fifo_wrptr;
    reg [4:0] rdata_fifo_rdptr;
    wire rdata_fifo_empty;
    wire rdata_fifo_full;
    
    assign rdata_fifo_empty = (rdata_fifo_wrptr == rdata_fifo_rdptr);
    assign rdata_fifo_full = ((rdata_fifo_wrptr + 1) == rdata_fifo_rdptr) ||
                              ((rdata_fifo_wrptr == 5'd31) && (rdata_fifo_rdptr == 5'd0));
    
    // ==========================================
    // Status & Control
    // ==========================================
    reg [31:0] status_reg;
    reg [7:0] credit_count;
    reg tx_in_progress;
    reg rx_in_progress;
    
    assign ctrl_ready = (status_reg[0]);
    assign ctrl_status = status_reg;
    
    // ==========================================
    // AXI Slave - Accept Remote Requests
    // ==========================================
    // Write address
    assign s_awready = !wr_fifo_full;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_fifo_wrptr <= 4'd0;
        end else if (s_awvalid && s_awready) begin
            write_fifo[wr_fifo_wrptr] <= {
                s_awid,
                s_awaddr,
                s_awlen,
                s_awsize,
                s_awburst
            };
            wr_fifo_wrptr <= wr_fifo_wrptr + 1;
        end
    end
    
    // Write data
    reg [15:0] write_byte_count;
    reg [ID_W-1:0] write_id_reg;
    reg [ADDR_W-1:0] write_addr_reg;
    
    assign s_wready = !tx_in_progress;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_in_progress <= 1'b0;
            write_byte_count <= 16'd0;
        end else if (s_wvalid && s_wready) begin
            tx_in_progress <= 1'b1;
            write_byte_count <= write_byte_count + (DATA_W/8);
        end else if (s_wvalid && s_wlast) begin
            tx_in_progress <= 1'b0;
            write_byte_count <= 16'd0;
        end
    end
    
    // Write response
    reg [15:0] write_resp_cnt;
    
    assign s_bid = m_bid;
    assign s_bresp = m_bresp;
    assign s_bvalid = m_bvalid;
    assign m_bready = s_bready;
    
    // Read address
    assign s_arready = !rd_fifo_full;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_fifo_wrptr <= 4'd0;
        end else if (s_arvalid && s_arready) begin
            read_fifo[rd_fifo_wrptr] <= {
                s_arid,
                s_araddr,
                s_arlen,
                s_arsize,
                s_arburst
            };
            rd_fifo_wrptr <= rd_fifo_wrptr + 1;
        end
    end
    
    // ==========================================
    // AXI Master - Initiate Remote Requests
    // ==========================================
    reg [3:0] master_state;
    reg [7:0] beat_count;
    
    assign m_awid = write_fifo[wr_fifo_rdptr][ADDR_W+32+8+3+2+ID_W-1 -: ID_W];
    assign m_awaddr = write_fifo[wr_fifo_rdptr][ADDR_W+32+8+3+2-1 -: ADDR_W];
    assign m_awlen = write_fifo[wr_fifo_rdptr][32+8+3+2-1 -: 8];
    assign m_awsize = write_fifo[wr_fifo_rdptr][3+2-1 -: 3];
    assign m_awburst = write_fifo[wr_fifo_rdptr][2-1 -: 2];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            master_state <= IDLE;
            m_awvalid <= 1'b0;
            m_wvalid <= 1'b0;
            m_wlast <= 1'b0;
            m_wdata <= {DATA_W{1'b0}};
            m_wstrb <= {(DATA_W/8){1'b1}};
            m_arvalid <= 1'b0;
            m_arid <= {ID_W{1'b0}};
            m_araddr <= {ADDR_W{1'b0}};
            m_arlen <= 8'd0;
            m_arsize <= 3'd0;
            m_arburst <= 2'd0;
            wr_fifo_rdptr <= 4'd0;
            rd_fifo_rdptr <= 4'd0;
            beat_count <= 8'd0;
        end else begin
            case (master_state)
                IDLE: begin
                    if (!wr_fifo_empty && !tx_in_progress) begin
                        // Send write request
                        m_awvalid <= 1'b1;
                        m_awid <= write_fifo[wr_fifo_rdptr][ADDR_W+32+8+3+2+ID_W-1 -: ID_W];
                        m_awaddr <= write_fifo[wr_fifo_rdptr][ADDR_W+32+8+3+2-1 -: ADDR_W];
                        m_awlen <= write_fifo[wr_fifo_rdptr][32+8+3+2-1 -: 8];
                        m_awsize <= write_fifo[wr_fifo_rdptr][3+2-1 -: 3];
                        m_awburst <= write_fifo[wr_fifo_rdptr][2-1 -: 2];
                        master_state <= SEND_WRITE;
                    end else if (!rd_fifo_empty) begin
                        // Send read request
                        m_arvalid <= 1'b1;
                        m_arid <= read_fifo[rd_fifo_rdptr][ADDR_W+32+8+3+2+ID_W-1 -: ID_W];
                        m_araddr <= read_fifo[rd_fifo_rdptr][ADDR_W+32+8+3+2-1 -: ADDR_W];
                        m_arlen <= read_fifo[rd_fifo_rdptr][32+8+3+2-1 -: 8];
                        m_arsize <= read_fifo[rd_fifo_rdptr][3+2-1 -: 3];
                        m_arburst <= read_fifo[rd_fifo_rdptr][2-1 -: 2];
                        master_state <= SEND_READ;
                    end
                end
                
                SEND_WRITE: begin
                    if (m_awvalid && m_awready) begin
                        m_awvalid <= 1'b0;
                        m_wvalid <= 1'b1;
                        master_state <= WAIT_RESP;
                    end
                end
                
                SEND_READ: begin
                    if (m_arvalid && m_arready) begin
                        m_arvalid <= 1'b0;
                        master_state <= WAIT_RESP;
                    end
                end
                
                WAIT_RESP: begin
                    if (m_bvalid && m_bready) begin
                        wr_fifo_rdptr <= wr_fifo_rdptr + 1;
                        master_state <= IDLE;
                    end else if (m_rvalid && m_rready) begin
                        // Store read data
                        if (m_rlast) begin
                            rd_fifo_rdptr <= rd_fifo_rdptr + 1;
                            master_state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end
    
    // ==========================================
    // UCIe TX (Master Mode)
    // ==========================================
    assign ucsie_tx_valid = (master_state != IDLE) && !wr_fifo_empty;
    assign ucsie_tx_sop = (master_state == SEND_WRITE) || (master_state == SEND_READ);
    assign ucsie_tx_eop = (m_bvalid && m_bready) || (m_rvalid && m_rlast);
    
    // ==========================================
    // UCIe RX (Slave Mode)
    // ==========================================
    assign ucsie_rx_ready = 1'b1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 32'd0;
            credit_count <= 8'd16;
        end else begin
            // Link status
            status_reg <= {
                27'd0,
                ctrl_enable,
                ucsie_link_status
            };
            
            // Credit management
            if (ucsie_rx_valid && ucsie_rx_sop) begin
                credit_count <= credit_count - 1;
            end else if (ucsie_rx_valid && ucsie_rx_eop) begin
                credit_count <= credit_count + 1;
            end
        end
    end
    
    // ==========================================
    // Response Handling
    // ==========================================
    assign m_rready = !resp_fifo_full;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            resp_fifo_wrptr <= 5'd0;
        end else if (m_rvalid && m_rready) begin
            resp_fifo[resp_fifo_wrptr] <= {
                m_rid,
                m_rdata,
                m_rresp,
                m_rlast
            };
            resp_fifo_wrptr <= resp_fifo_wrptr + 1;
        end
    end
    
    assign s_rid = rdata_fifo[rdata_fifo_rdptr][DATA_W+2+1+ID_W-1 -: ID_W];
    assign s_rdata = rdata_fifo[rdata_fifo_rdptr][DATA_W+2+1-1 -: DATA_W];
    assign s_rresp = rdata_fifo[rdata_fifo_rdptr][2+1-1 -: 2];
    assign s_rlast = rdata_fifo[rdata_fifo_rdptr][1-1 -: 1];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_fifo_rdptr <= 5'd0;
            s_rvalid <= 1'b0;
        end else if (!rdata_fifo_empty && s_rready) begin
            s_rvalid <= 1'b1;
            if (s_rlast) begin
                rdata_fifo_rdptr <= rdata_fifo_rdptr + 1;
            end
        end else begin
            s_rvalid <= 1'b0;
        end
    end

endmodule

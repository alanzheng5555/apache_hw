// 6-Port NoC Router Module
// Supports 6 independent AXI4 ports with routing logic

`timescale 1ns/1ps

module router_6port #(
    parameter DATA_W = 64,
    parameter ADDR_W = 32,
    parameter FIFO_DEPTH = 16,
    parameter ROUTE_ENTRIES = 8,
    parameter PORTS = 6
)(
    // System
    input  wire                 clk,
    input  wire                 rst_n,
    
    // ==========================================
    // AXI4 Input Ports (Slave - inputs to router)
    // ==========================================
    // Write Address Channel
    input  wire [PORTS-1:0]     s_awvalid,
    output wire [PORTS-1:0]     s_awready,
    input  wire [ADDR_W-1:0]    s_awaddr [PORTS-1:0],
    input  wire [7:0]           s_awlen [PORTS-1:0],
    input  wire [2:0]           s_awsize [PORTS-1:0],
    input  wire [1:0]           s_awburst [PORTS-1:0],
    
    // Write Data Channel
    input  wire [PORTS-1:0]     s_wvalid,
    output wire [PORTS-1:0]     s_wready,
    input  wire [DATA_W-1:0]   s_wdata [PORTS-1:0],
    input  wire [(DATA_W/8)-1:0] s_wstrb [PORTS-1:0],
    input  wire [PORTS-1:0]     s_wlast,
    
    // Read Address Channel
    input  wire [PORTS-1:0]     s_arvalid,
    output wire [PORTS-1:0]     s_arready,
    input  wire [ADDR_W-1:0]    s_araddr [PORTS-1:0],
    input  wire [7:0]           s_arlen [PORTS-1:0],
    input  wire [2:0]           s_arsize [PORTS-1:0],
    input  wire [1:0]          s_arburst [PORTS-1:0],
    
    // Read Data Channel
    output wire [PORTS-1:0]     s_rvalid,
    input  wire [PORTS-1:0]     s_rready,
    output wire [DATA_W-1:0]   s_rdata [PORTS-1:0],
    output wire [PORTS-1:0]     s_rlast,
    
    // ==========================================
    // AXI4 Output Ports (Master - outputs from router)
    // ==========================================
    // Write Address Channel
    output wire [PORTS-1:0]     m_awvalid,
    input  wire [PORTS-1:0]     m_awready,
    output wire [ADDR_W-1:0]    m_awaddr [PORTS-1:0],
    output wire [7:0]           m_awlen [PORTS-1:0],
    output wire [2:0]           m_awsize [PORTS-1:0],
    output wire [1:0]           m_awburst [PORTS-1:0],
    
    // Write Data Channel
    output wire [PORTS-1:0]     m_wvalid,
    input  wire [PORTS-1:0]     m_wready,
    output wire [DATA_W-1:0]   m_wdata [PORTS-1:0],
    output wire [(DATA_W/8)-1:0] m_wstrb [PORTS-1:0],
    output wire [PORTS-1:0]     m_wlast,
    
    // Read Address Channel
    output wire [PORTS-1:0]     m_arvalid,
    input  wire [PORTS-1:0]     m_arready,
    output wire [ADDR_W-1:0]    m_araddr [PORTS-1:0],
    output wire [7:0]           m_arlen [PORTS-1:0],
    output wire [2:0]           m_arsize [PORTS-1:0],
    output wire [1:0]           m_arburst [PORTS-1:0],
    
    // Read Data Channel
    input  wire [PORTS-1:0]     m_rvalid,
    output wire [PORTS-1:0]     m_rready,
    input  wire [DATA_W-1:0]   m_rdata [PORTS-1:0],
    input  wire [PORTS-1:0]     m_rlast,
    
    // ==========================================
    // APB Configuration Interface
    // ==========================================
    input  wire [11:0]          paddr,
    input  wire                 pwrite,
    input  wire [31:0]         pwdata,
    input  wire                 psel,
    input  wire                 penable,
    output wire                 pready,
    output wire [31:0]          prdata
);
31:0]    
    // ==========================================
    // Parameters
    // ==========================================
    localparam PORT_ID_NOC_SLAVE = 0;
    localparam PORT_ID_NOC_MASTER = 1;
    localparam PORT_ID_AXI_SLAVE0 = 2;
    localparam PORT_ID_AXI_SLAVE1 = 3;
    localparam PORT_ID_AXI_MASTER0 = 4;
    localparam PORT_ID_AXI_MASTER1 = 5;
    
    // Address range definitions for routing
    localparam ADDR_RANGE_NOC   = 32'h0000_0000;
    localparam ADDR_RANGE_NOC_SZ = 32'h1000_0000;  // 256MB
    
    localparam ADDR_RANGE_MEM0   = 32'h1000_0000;
    localparam ADDR_RANGE_MEM0_SZ = 32'h1000_0000; // 256MB
    
    localparam ADDR_RANGE_MEM1   = 32'h2000_0000;
    localparam ADDR_RANGE_MEM1_SZ = 32'h1000_0000; // 256MB
    
    localparam ADDR_RANGE_PERI   = 32'h3000_0000;
    localparam ADDR_RANGE_PERI_SZ = 32'h1000_0000; // 256MB
    
    // ==========================================
    // Routing Table (Register-based)
    // ==========================================
    reg [2:0] route_table [ROUTE_ENTRIES-1:0];  // port_id per entry
    reg [31:0] route_addr [ROUTE_ENTRIES-1:0];  // base address per entry
    reg [31:0] route_mask [ROUTE_ENTRIES-1:0];  // address mask per entry
    
    // Route table signals
    wire [31:0] lookup_addr;
    wire [2:0] output_port;
    wire route_hit;
    
    // Initialize route table
    integer i;
    initial begin
        for (i = 0; i < ROUTE_ENTRIES; i = i + 1) begin
            route_table[i] = 3'd0;
            route_addr[i] = 32'd0;
            route_mask[i] = 32'd0;
        end
        // Default routing
        route_addr[0] = ADDR_RANGE_NOC;
        route_mask[0] = ADDR_RANGE_NOC_SZ - 1;
        route_table[0] = PORT_ID_NOC_MASTER;
        
        route_addr[1] = ADDR_RANGE_MEM0;
        route_mask[1] = ADDR_RANGE_MEM0_SZ - 1;
        route_table[1] = PORT_ID_AXI_MASTER0;
        
        route_addr[2] = ADDR_RANGE_MEM1;
        route_mask[2] = ADDR_RANGE_MEM1_SZ - 1;
        route_table[2] = PORT_ID_AXI_MASTER1;
        
        route_addr[3] = ADDR_RANGE_PERI;
        route_mask[3] = ADDR_RANGE_PERI_SZ - 1;
        route_table[3] = PORT_ID_AXI_MASTER0;
    end
    
    // Route lookup
    assign lookup_addr = s_arvalid ? s_araddr[s_arvalid] : 
                         s_awvalid ? s_awaddr[s_awvalid] : 32'd0;
    
    reg [2:0] routed_port [PORTS-1:0];
    reg [PORTS-1:0] route_hit_port;
    
    always @(*) begin
        routed_port = '{default: 3'd0};
        route_hit_port = 1'b0;
        
        // Check which input port has valid request
        for (int j = 0; j < PORTS; j = j + 1) begin
            if (s_awvalid[j] || s_arvalid[j]) begin
                // Perform route table lookup
                for (int k = 0; k < ROUTE_ENTRIES; k = k + 1) begin
                    if (route_mask[k] != 0 && 
                        ((s_awvalid[j] ? s_awaddr[j] : s_araddr[j]) & route_mask[k]) == route_addr[k]) begin
                        routed_port[j] = route_table[k];
                        route_hit_port[j] = 1'b1;
                        break;
                    end
                end
                // Default routing if no match
                if (!route_hit_port[j]) begin
                    routed_port[j] = PORT_ID_AXI_MASTER0;
                    route_hit_port[j] = 1'b1;
                end
            end
        end
    end
    
    // ==========================================
    // Port FIFOs and Routing Logic (Per Port)
    // ==========================================
    genvar port_idx;
    generate
        for (port_idx = 0; port_idx < PORTS; port_idx = port_idx + 1) begin : port_gen
            
            // Determine target port for this input
            wire [2:0] target_port = routed_port[port_idx];
            
            // Write channel routing
            assign s_awready[port_idx] = m_awready[target_port];
            assign m_awvalid[target_port] = s_awvalid[port_idx];
            assign m_awaddr[target_port] = s_awaddr[port_idx];
            assign m_awlen[target_port] = s_awlen[port_idx];
            assign m_awsize[target_port] = s_awsize[port_idx];
            assign m_awburst[target_port] = s_awburst[port_idx];
            
            assign s_wready[port_idx] = m_wready[target_port];
            assign m_wvalid[target_port] = s_wvalid[port_idx];
            assign m_wdata[target_port] = s_wdata[port_idx];
            assign m_wstrb[target_port] = s_wstrb[port_idx];
            assign m_wlast[target_port] = s_wlast[port_idx];
            
            // Read channel routing
            assign s_arready[port_idx] = m_arready[target_port];
            assign m_arvalid[target_port] = s_arvalid[port_idx];
            assign m_araddr[target_port] = s_araddr[port_idx];
            assign m_arlen[target_port] = s_arlen[port_idx];
            assign m_arsize[target_port] = s_arsize[port_idx];
            assign m_arburst[target_port] = s_arburst[port_idx];
            
            // Read response routing - crossbar style
            reg [DATA_W-1:0] rdata_reg;
            reg rvalid_reg;
            reg rlast_reg;
            
            always @(*) begin
                rdata_reg = {DATA_W{1'b0}};
                rvalid_reg = 1'b0;
                rlast_reg = 1'b0;
                
                // Check which master has valid response for this slave
                for (int m = 0; m < PORTS; m = m + 1) begin
                    if (m_rvalid[m] && (target_port == m)) begin
                        rdata_reg = m_rdata[m];
                        rvalid_reg = m_rvalid[m];
                        rlast_reg = m_rlast[m];
                    end
                end
            end
            
            assign s_rdata[port_idx] = rdata_reg;
            assign s_rvalid[port_idx] = rvalid_reg;
            assign s_rlast[port_idx] = rlast_reg;
            assign m_rready[target_port] = s_rready[port_idx];
            
        end
    endgenerate
    
    // ==========================================
    // APB Interface for Route Table Configuration
    // ==========================================
    reg pready_reg;
    reg [31:0] prdata_reg;
    
    assign pready = pready_reg;
    assign prdata = prdata_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pready_reg <= 1'b0;
            prdata_reg <= 32'd0;
        end else if (psel && penable) begin
            pready_reg <= 1'b1;
            if (pwrite) begin
                // Write to route table
                if (paddr[11:8] < ROUTE_ENTRIES) begin
                    if (paddr[3:2] == 2'b00) begin
                        route_addr[paddr[11:8]] <= pwdata;
                    end else if (paddr[3:2] == 2'b01) begin
                        route_mask[paddr[11:8]] <= pwdata;
                    end else if (paddr[3:2] == 2'b10) begin
                        route_table[paddr[11:8]] <= pwdata[2:0];
                    end
                end
            end else begin
                // Read from route table
                if (paddr[11:8] < ROUTE_ENTRIES) begin
                    if (paddr[3:2] == 2'b00) begin
                        prdata_reg <= route_addr[paddr[11:8]];
                    end else if (paddr[3:2] == 2'b01) begin
                        prdata_reg <= route_mask[paddr[11:8]];
                    end else if (paddr[3:2] == 2'b10) begin
                        prdata_reg <= {29'd0, route_table[paddr[11:8]]};
                    end else begin
                        prdata_reg <= 32'd0;
                    end
                end else begin
                    prdata_reg <= 32'd0;
                end
            end
        end else begin
            pready_reg <= 1'b0;
        end
    end

endmodule

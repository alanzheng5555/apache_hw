// NoC Router Module - Routing Table
// Stores routing rules with address matching and masking

`timescale 1ns/1ps

module router_table #(
    parameter ENTRIES = 8,
    parameter ADDR_W = 32,
    parameter PORT_W = 2  // 2 bits for 3 ports
)(
    // APB Interface
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [11:0]          paddr,
    input  wire [31:0]         pwdata,
    input  wire                 pwrite,
    input  wire                 psel,
    input  wire                 penable,
    output wire                 pready,
    output wire [31:0]         prdata,
    
    // Routing Decision Interface
    input  wire [ADDR_W-1:0]    lookup_addr,
    output wire [PORT_W-1:0]   output_port,
    output wire                 hit
);
    
    // Parameters
    localparam ENTRY_W = ADDR_W + ADDR_W + PORT_W;  // addr + mask + port
    
    // Registers
    reg [ADDR_W-1:0] route_addr [0:ENTRIES-1];
    reg [ADDR_W-1:0] route_mask [0:ENTRIES-1];
    reg [PORT_W-1:0] route_port [0:ENTRIES-1];
    reg [PORT_W-1:0] default_port;
    reg enable;
    
    // APB FSM
    reg [1:0] apb_state;
    localparam APB_IDLE = 2'd0;
    localparam APB_SETUP = 2'd1;
    localparam APB_ACCESS = 2'd2;
    
    // APB response
    assign pready = (apb_state != APB_IDLE);
    assign prdata = 32'd0;  // Read back not implemented for simplicity
    
    // APB Write FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            apb_state <= APB_IDLE;
            enable <= 1'b1;
            default_port <= 2'd0;
            
            // Initialize with some default routing
            for (integer i = 0; i < ENTRIES; i = i + 1) begin
                route_addr[i] <= 32'd0;
                route_mask[i] <= 32'd0;
                route_port[i] <= 2'd0;
            end
        end else begin
            case (apb_state)
                APB_IDLE: begin
                    if (psel && !pwrite && penable) begin
                        apb_state <= APB_ACCESS;
                    end else if (psel && pwrite && penable) begin
                        apb_state <= APB_ACCESS;
                    end else if (psel && penable) begin
                        apb_state <= APB_ACCESS;
                    end
                end
                APB_ACCESS: begin
                    if (psel && pwrite && penable) begin
                        // Write routing table entry
                        if (paddr[11:6] < ENTRIES) begin
                            case (paddr[5:2])
                                2'd0: route_addr[paddr[11:6]] <= pwdata[ADDR_W-1:0];
                                2'd1: route_mask[paddr[11:6]] <= pwdata[ADDR_W-1:0];
                                2'd2: route_port[paddr[11:6]] <= pwdata[PORT_W-1:0];
                            endcase
                        end else if (paddr[9:2] == 8'd128) begin
                            default_port <= pwdata[PORT_W-1:0];
                        end else if (paddr[9:2] == 8'd129) begin
                            enable <= pwdata[0];
                        end
                    end
                    apb_state <= APB_IDLE;
                end
                default: apb_state <= APB_IDLE;
            endcase
        end
    end
    
    // Routing Decision Logic
    // Check entries in priority order (0 is highest)
    reg [PORT_W-1:0] hit_port;
    reg hit_reg;
    integer i;
    
    always @(*) begin
        hit_port = default_port;
        hit_reg = 1'b0;
        
        if (enable) begin
            for (i = 0; i < ENTRIES; i = i + 1) begin
                if (((lookup_addr ^ route_addr[i]) & route_mask[i]) == 32'd0) begin
                    // Match found
                    if (route_port[i] != 2'd3) begin  // 2'd3 = broadcast/all
                        hit_port = route_port[i];
                        hit_reg = 1'b1;
                    end
                end
            end
        end
    end
    
    assign output_port = hit_port;
    assign hit = hit_reg;
    
endmodule

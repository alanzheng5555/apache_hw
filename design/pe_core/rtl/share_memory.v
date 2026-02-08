// Share Memory (SRAM) with Dual-Port Access and Arbitration
// Port 1: PE (Processing Element)
// Port 2: AXI Slave Interface
// Arbitration: Round-robin or priority-based

`timescale 1ns/1ps

module share_memory #(
    parameter DEPTH = 256,
    parameter WIDTH = 32,
    parameter ADDR_W = 8
)(
    // System
    input  wire                 clk,
    input  wire                 rst_n,
    
    // Port 1: PE Access
    input  wire                 pe_we,          // Write enable
    input  wire [ADDR_W-1:0]   pe_addr,        // Address
    input  wire [WIDTH-1:0]    pe_wdata,       // Write data
    output wire [WIDTH-1:0]    pe_rdata,       // Read data
    input  wire                 pe_request,     // Request access
    output wire                 pe_grant,       // Grant access
    
    // Port 2: AXI Slave Access
    input  wire                 axi_we,         // Write enable
    input  wire [ADDR_W-1:0]   axi_addr,       // Address
    input  wire [WIDTH-1:0]    axi_wdata,      // Write data
    output wire [WIDTH-1:0]    axi_rdata,      // Read data
    input  wire                 axi_request,    // Request access
    output wire                 axi_grant      // Grant access
);
    
    // Memory array
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    
    // Arbitration state
    reg [ADDR_W-1:0] pe_addr_reg;
    reg [WIDTH-1:0] pe_wdata_reg;
    reg pe_we_reg;
    
    reg [ADDR_W-1:0] axi_addr_reg;
    reg [WIDTH-1:0] axi_wdata_reg;
    reg axi_we_reg;
    
    // Grant registers
    reg pe_grant_reg;
    reg axi_grant_reg;
    
    // Arbitration: Grant-based (not request-based)
    // Master must assert both request and valid to get grant
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pe_grant_reg <= 1'b0;
            axi_grant_reg <= 1'b0;
        end else begin
            // PE has higher priority
            if (pe_request && pe_we) begin
                pe_grant_reg <= 1'b1;
                axi_grant_reg <= 1'b0;
            end else if (axi_request && axi_we) begin
                pe_grant_reg <= 1'b0;
                axi_grant_reg <= 1'b1;
            end else begin
                // Release grant when request deasserts or no write
                pe_grant_reg <= 1'b0;
                axi_grant_reg <= 1'b0;
            end
        end
    end
    
    // PE port register
    always @(posedge clk) begin
        if (pe_request) begin
            pe_addr_reg <= pe_addr;
            pe_wdata_reg <= pe_wdata;
            pe_we_reg <= pe_we;
        end
    end
    
    // AXI port register
    always @(posedge clk) begin
        if (axi_request) begin
            axi_addr_reg <= axi_addr;
            axi_wdata_reg <= axi_wdata;
            axi_we_reg <= axi_we;
        end
    end
    
    // Memory write
    always @(posedge clk) begin
        // PE write (higher priority)
        if (pe_grant_reg && pe_we_reg) begin
            mem[pe_addr_reg] <= pe_wdata_reg;
        end
        
        // AXI write (lower priority)
        if (axi_grant_reg && axi_we_reg) begin
            mem[axi_addr_reg] <= axi_wdata_reg;
        end
    end
    
    // Memory read - use registered addresses
    assign pe_rdata = mem[pe_addr_reg];
    assign axi_rdata = mem[axi_addr_reg];
    
    // Grant outputs
    assign pe_grant = pe_grant_reg;
    assign axi_grant = axi_grant_reg;
    
endmodule

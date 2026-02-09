// Mesh Router - Connects cores in a 2D mesh network
// Routes packets based on destination address

`timescale 1ns/1ps

module mesh_router #(
    parameter DATA_W = 64,
    parameter ADDR_W = 32,
    parameter CORES_X = 8,
    parameter CORES_Y = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    
    // Local core interface (connected to this core)
    input  wire                 local_awvalid,
    output wire                 local_awready,
    input  wire [ADDR_W-1:0]    local_awaddr,
    input  wire [7:0]          local_awlen,
    input  wire [2:0]           local_awsize,
    input  wire [1:0]           local_awburst,
    
    input  wire                 local_wvalid,
    output wire                 local_wready,
    input  wire [DATA_W-1:0]    local_wdata,
    input  wire [(DATA_W/8)-1:0] local_wstrb,
    input  wire                 local_wlast,
    
    input  wire                 local_arvalid,
    output wire                 local_arready,
    input  wire [ADDR_W-1:0]    local_araddr,
    input  wire [7:0]          local_arlen,
    input  wire [2:0]           local_arsize,
    input  wire [1:0]           local_arburst,
    
    output wire                 local_rvalid,
    input  wire                 local_rready,
    output wire [DATA_W-1:0]    local_rdata,
    output wire                 local_rlast,
    
    // West neighbor (if exists)
    output wire                 west_awvalid,
    input  wire                 west_awready,
    output wire [ADDR_W-1:0]    west_awaddr,
    output wire [7:0]          west_awlen,
    output wire [2:0]           west_awsize,
    output wire [1:0]           west_awburst,
    
    output wire                 west_wvalid,
    input  wire                 west_wready,
    output wire [DATA_W-1:0]    west_wdata,
    output wire [(DATA_W/8)-1:0] west_wstrb,
    output wire                 west_wlast,
    
    output wire                 west_arvalid,
    input  wire                 west_arready,
    output wire [ADDR_W-1:0]    west_araddr,
    output wire [7:0]          west_arlen,
    output wire [2:0]           west_arsize,
    output wire [1:0]           west_arburst,
    
    input  wire                 west_rvalid,
    output wire                 west_rready,
    input  wire [DATA_W-1:0]    west_rdata,
    input  wire                 west_rlast,
    
    // East neighbor (if exists)
    input  wire                 east_awvalid,
    output wire                 east_awready,
    input  wire [ADDR_W-1:0]    east_awaddr,
    input  wire [7:0]          east_awlen,
    input  wire [2:0]           east_awsize,
    input  wire [1:0]           east_awburst,
    
    input  wire                 east_wvalid,
    output wire                 east_wready,
    input  wire [DATA_W-1:0]    east_wdata,
    input  wire [(DATA_W/8)-1:0] east_wstrb,
    input  wire                 east_wlast,
    
    input  wire                 east_arvalid,
    output wire                 east_arready,
    input  wire [ADDR_W-1:0]    east_araddr,
    input  wire [7:0]          east_arlen,
    input  wire [2:0]           east_arsize,
    input  wire [1:0]           east_arburst,
    
    output wire                 east_rvalid,
    input  wire                 east_rready,
    output wire [DATA_W-1:0]    east_rdata,
    output wire                 east_rlast,
    
    // South neighbor (if exists)
    output wire                 south_awvalid,
    input  wire                 south_awready,
    output wire [ADDR_W-1:0]    south_awaddr,
    output wire [7:0]          south_awlen,
    output wire [2:0]           south_awsize,
    output wire [1:0]           south_awburst,
    
    output wire                 south_wvalid,
    input  wire                 south_wready,
    output wire [DATA_W-1:0]    south_wdata,
    output wire [(DATA_W/8)-1:0] south_wstrb,
    output wire                 south_wlast,
    
    output wire                 south_arvalid,
    input  wire                 south_arready,
    output wire [ADDR_W-1:0]    south_araddr,
    output wire [7:0]          south_arlen,
    output wire [2:0]           south_arsize,
    output wire [1:0]           south_arburst,
    
    input  wire                 south_rvalid,
    output wire                 south_rready,
    input  wire [DATA_W-1:0]    south_rdata,
    input  wire                 south_rlast,
    
    // North neighbor (if exists)
    input  wire                 north_awvalid,
    output wire                 north_awready,
    input  wire [ADDR_W-1:0]    north_awaddr,
    input  wire [7:0]          north_awlen,
    input  wire [2:0]           north_awsize,
    input  wire [1:0]           north_awburst,
    
    input  wire                 north_wvalid,
    output wire                 north_wready,
    input  wire [DATA_W-1:0]    north_wdata,
    input  wire [(DATA_W/8)-1:0] north_wstrb,
    input  wire                 north_wlast,
    
    input  wire                 north_arvalid,
    output wire                 north_arready,
    input  wire [ADDR_W-1:0]    north_araddr,
    input  wire [7:0]          north_arlen,
    input  wire [2:0]           north_arsize,
    input  wire [1:0]           north_arburst,
    
    output wire                 north_rvalid,
    input  wire                 north_rready,
    output wire [DATA_W-1:0]    north_rdata,
    output wire                 north_rlast,
    
    // Local core position
    input wire [2:0] my_x,       // Column (0-7)
    input wire [2:0] my_y        // Row (0-7)
);

    // ==========================================
    // Address Decode for Routing
    // ==========================================
    // Address format:
    // bits[31:9] - reserved/unused
    // bits[8:6]  - row (3 bits, 0-7)
    // bits[5:3]  - column (3 bits, 0-7)
    // bits[2:0]  - offset within core
    
    wire [2:0] dest_col = local_arvalid ? local_araddr[5:3] :
                         local_awvalid ? local_awaddr[5:3] : 3'd0;
    wire [2:0] dest_row = local_arvalid ? local_araddr[8:6] :
                         local_awvalid ? local_awaddr[8:6] : 3'd0;
    
    // Check if destination is local
    wire is_local = (dest_col == my_x) && (dest_row == my_y);
    
    // Determine routing direction
    wire go_west  = !is_local && (dest_col < my_x);
    wire go_east  = !is_local && (dest_col > my_x);
    wire go_south = !is_local && (dest_row < my_y);
    wire go_north = !is_local && (dest_row > my_y);
    
    // Write channel routing
    assign local_awready = is_local ? 1'b1 :
                          go_west  ? west_awready  :
                          go_east  ? east_awready  :
                          go_south ? south_awready :
                          go_north ? north_awready : 1'b0;
    
    assign west_awvalid  = go_west  ? local_awvalid  : 1'b0;
    assign east_awvalid  = go_east  ? local_awvalid  : 1'b0;
    assign south_awvalid = go_south ? local_awvalid  : 1'b0;
    assign north_awvalid = go_north ? local_awvalid  : 1'b0;
    
    assign west_awaddr  = go_west  ? local_awaddr  : {ADDR_W{1'b0}};
    assign east_awaddr  = go_east  ? local_awaddr  : {ADDR_W{1'b0}};
    assign south_awaddr = go_south ? local_awaddr  : {ADDR_W{1'b0}};
    assign north_awaddr = go_north ? local_awaddr  : {ADDR_W{1'b0}};
    
    assign west_awlen  = go_west  ? local_awlen  : 8'd0;
    assign east_awlen  = go_east  ? local_awlen  : 8'd0;
    assign south_awlen = go_south ? local_awlen  : 8'd0;
    assign north_awlen = go_north ? local_awlen  : 8'd0;
    
    assign west_awsize  = go_west  ? local_awsize  : 3'd0;
    assign east_awsize  = go_east  ? local_awsize  : 3'd0;
    assign south_awsize = go_south ? local_awsize  : 3'd0;
    assign north_awsize = go_north ? local_awsize  : 3'd0;
    
    assign west_awburst  = go_west  ? local_awburst  : 2'd0;
    assign east_awburst  = go_east  ? local_awburst  : 2'd0;
    assign south_awburst = go_south ? local_awburst  : 2'd0;
    assign north_awburst = go_north ? local_awburst  : 2'd0;
    
    // Write data routing
    assign local_wready = is_local ? 1'b1 :
                          go_west  ? west_wready  :
                          go_east  ? east_wready  :
                          go_south ? south_wready :
                          go_north ? north_wready : 1'b0;
    
    assign west_wvalid  = go_west  ? local_wvalid  : 1'b0;
    assign east_wvalid  = go_east  ? local_wvalid  : 1'b0;
    assign south_wvalid = go_south ? local_wvalid  : 1'b0;
    assign north_wvalid = go_north ? local_wvalid  : 1'b0;
    
    assign west_wdata  = go_west  ? local_wdata  : {DATA_W{1'b0}};
    assign east_wdata  = go_east  ? local_wdata  : {DATA_W{1'b0}};
    assign south_wdata = go_south ? local_wdata  : {DATA_W{1'b0}};
    assign north_wdata = go_north ? local_wdata  : {DATA_W{1'b0}};
    
    assign west_wstrb  = go_west  ? local_wstrb  : {(DATA_W/8){1'b0}};
    assign east_wstrb  = go_east  ? local_wstrb  : {(DATA_W/8){1'b0}};
    assign south_wstrb = go_south ? local_wstrb  : {(DATA_W/8){1'b0}};
    assign north_wstrb = go_north ? local_wstrb  : {(DATA_W/8){1'b0}};
    
    assign west_wlast  = go_west  ? local_wlast  : 1'b0;
    assign east_wlast  = go_east  ? local_wlast  : 1'b0;
    assign south_wlast = go_south ? local_wlast  : 1'b0;
    assign north_wlast = go_north ? local_wlast  : 1'b0;
    
    // Read channel routing
    assign local_arready = is_local ? 1'b1 :
                           go_west  ? west_arready  :
                           go_east  ? east_arready  :
                           go_south ? south_arready :
                           go_north ? north_arready : 1'b0;
    
    assign west_arvalid  = go_west  ? local_arvalid  : 1'b0;
    assign east_arvalid  = go_east  ? local_arvalid  : 1'b0;
    assign south_arvalid = go_south ? local_arvalid  : 1'b0;
    assign north_arvalid = go_north ? local_arvalid  : 1'b0;
    
    assign west_araddr  = go_west  ? local_araddr  : {ADDR_W{1'b0}};
    assign east_araddr  = go_east  ? local_araddr  : {ADDR_W{1'b0}};
    assign south_araddr = go_south ? local_araddr  : {ADDR_W{1'b0}};
    assign north_araddr = go_north ? local_araddr  : {ADDR_W{1'b0}};
    
    assign west_arlen  = go_west  ? local_arlen  : 8'd0;
    assign east_arlen  = go_east  ? local_arlen  : 8'd0;
    assign south_arlen = go_south ? local_arlen  : 8'd0;
    assign north_arlen = go_north ? local_arlen  : 8'd0;
    
    assign west_arsize  = go_west  ? local_arsize  : 3'd0;
    assign east_arsize  = go_east  ? local_arsize  : 3'd0;
    assign south_arsize = go_south ? local_arsize  : 3'd0;
    assign north_arsize = go_north ? local_arsize  : 3'd0;
    
    assign west_arburst  = go_west  ? local_arburst  : 2'd0;
    assign east_arburst  = go_east  ? local_arburst  : 2'd0;
    assign south_arburst = go_south ? local_arburst  : 2'd0;
    assign north_arburst = go_north ? local_arburst  : 2'd0;
    
    // Read response routing
    assign west_rready  = go_west  ? local_rready  : 1'b0;
    assign east_rready  = go_east  ? local_rready  : 1'b0;
    assign south_rready = go_south ? local_rready  : 1'b0;
    assign north_rready = go_north ? local_rready  : 1'b0;
    
    assign local_rvalid = is_local ? 1'b1 :
                          west_rvalid  || east_rvalid  ||
                          south_rvalid || north_rvalid;
    
    assign local_rdata = west_rvalid  ? west_rdata  :
                        east_rvalid  ? east_rdata  :
                        south_rvalid ? south_rdata :
                        north_rvalid ? north_rdata : {DATA_W{1'b0}};
    
    assign local_rlast = west_rvalid  ? west_rlast  :
                        east_rvalid  ? east_rlast  :
                        south_rvalid ? south_rlast :
                        north_rvalid ? north_rlast : 1'b0;

endmodule

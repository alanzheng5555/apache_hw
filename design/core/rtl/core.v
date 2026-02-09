// Core Module - Integrates Router + PE
// Core has: 1 NOC master, 1 NOC slave, 2 AXI slave, 2 AXI master (all independent)

`timescale 1ns/1ps

module core #(
    parameter DATA_W = 64,
    parameter ADDR_W = 32,
    parameter PE_DATA_WIDTH = 32,
    parameter PE_VECTOR_WIDTH = 16,
    parameter ROUTER_PORTS = 6,    // 0:NOC_s, 1:NOC_m, 2:axi_s0, 3:axi_s1, 4:axi_m0, 5:axi_m1
    parameter FIFO_DEPTH = 16,
    parameter ROUTE_ENTRIES = 8
)(
    // System signals
    input  wire                 clk,
    input  wire                 rst_n,
    
    // ==========================================
    // NOC Interface (1 Master + 1 Slave)
    // ==========================================
    // NOC Slave (receives transactions from NOC)
    input  wire                 noc_s_awvalid,
    output wire                 noc_s_awready,
    input  wire [ADDR_W-1:0]    noc_s_awaddr,
    input  wire [7:0]           noc_s_awlen,
    input  wire [2:0]           noc_s_awsize,
    input  wire [1:0]           noc_s_awburst,
    
    input  wire                 noc_s_wvalid,
    output wire                 noc_s_wready,
    input  wire [DATA_W-1:0]    noc_s_wdata,
    input  wire [(DATA_W/8)-1:0] noc_s_wstrb,
    input  wire                 noc_s_wlast,
    
    input  wire                 noc_s_arvalid,
    output wire                 noc_s_arready,
    input  wire [ADDR_W-1:0]    noc_s_araddr,
    input  wire [7:0]           noc_s_arlen,
    input  wire [2:0]           noc_s_arsize,
    input  wire [1:0]           noc_s_arburst,
    
    output wire                 noc_s_rvalid,
    input  wire                 noc_s_rready,
    output wire [DATA_W-1:0]    noc_s_rdata,
    output wire                 noc_s_rlast,
    
    // NOC Master (initiates transactions to NOC)
    output wire                 noc_m_awvalid,
    input  wire                 noc_m_awready,
    output wire [ADDR_W-1:0]    noc_m_awaddr,
    output wire [7:0]           noc_m_awlen,
    output wire [2:0]           noc_m_awsize,
    output wire [1:0]           noc_m_awburst,
    
    output wire                 noc_m_wvalid,
    input  wire                 noc_m_wready,
    output wire [DATA_W-1:0]    noc_m_wdata,
    output wire [(DATA_W/8)-1:0] noc_m_wstrb,
    output wire                 noc_m_wlast,
    
    output wire                 noc_m_arvalid,
    input  wire                 noc_m_arready,
    output wire [ADDR_W-1:0]    noc_m_araddr,
    output wire [7:0]           noc_m_arlen,
    output wire [2:0]           noc_m_arsize,
    output wire [1:0]           noc_m_arburst,
    
    input  wire                 noc_m_rvalid,
    output wire                 noc_m_rready,
    input  wire [DATA_W-1:0]    noc_m_rdata,
    input  wire                 noc_m_rlast,
    
    // ==========================================
    // AXI4 Slave Ports (2 ports) - External masters access core
    // ==========================================
    // AXI Slave Port 0
    input  wire                 s0_awvalid,
    output wire                 s0_awready,
    input  wire [ADDR_W-1:0]    s0_awaddr,
    input  wire [7:0]          s0_awlen,
    input  wire [2:0]           s0_awsize,
    input  wire [1:0]           s0_awburst,
    
    input  wire                 s0_wvalid,
    output wire                 s0_wready,
    input  wire [DATA_W-1:0]    s0_wdata,
    input  wire [(DATA_W/8)-1:0] s0_wstrb,
    input  wire                 s0_wlast,
    
    input  wire                 s0_arvalid,
    output wire                 s0_arready,
    input  wire [ADDR_W-1:0]    s0_araddr,
    input  wire [7:0]          s0_arlen,
    input  wire [2:0]           s0_arsize,
    input  wire [1:0]           s0_arburst,
    
    output wire                 s0_rvalid,
    input  wire                 s0_rready,
    output wire [DATA_W-1:0]    s0_rdata,
    output wire                 s0_rlast,
    
    // AXI Slave Port 1
    input  wire                 s1_awvalid,
    output wire                 s1_awready,
    input  wire [ADDR_W-1:0]    s1_awaddr,
    input  wire [7:0]          s1_awlen,
    input  wire [2:0]           s1_awsize,
    input  wire [1:0]           s1_awburst,
    
    input  wire                 s1_wvalid,
    output wire                 s1_wready,
    input  wire [DATA_W-1:0]    s1_wdata,
    input  wire [(DATA_W/8)-1:0] s1_wstrb,
    input  wire                 s1_wlast,
    
    input  wire                 s1_arvalid,
    output wire                 s1_arready,
    input  wire [ADDR_W-1:0]    s1_araddr,
    input  wire [7:0]          s1_arlen,
    input  wire [2:0]           s1_arsize,
    input  wire [1:0]           s1_arburst,
    
    output wire                 s1_rvalid,
    input  wire                 s1_rready,
    output wire [DATA_W-1:0]    s1_rdata,
    output wire                 s1_rlast,
    
    // ==========================================
    // AXI4 Master Ports (2 ports) - Core accesses external slaves
    // ==========================================
    // AXI Master Port 0
    output wire                 m0_awvalid,
    input  wire                 m0_awready,
    output wire [ADDR_W-1:0]    m0_awaddr,
    output wire [7:0]          m0_awlen,
    output wire [2:0]           m0_awsize,
    output wire [1:0]           m0_awburst,
    
    output wire                 m0_wvalid,
    input  wire                 m0_wready,
    output wire [DATA_W-1:0]    m0_wdata,
    output wire [(DATA_W/8)-1:0] m0_wstrb,
    output wire                 m0_wlast,
    
    output wire                 m0_arvalid,
    input  wire                 m0_arready,
    output wire [ADDR_W-1:0]    m0_araddr,
    output wire [7:0]          m0_arlen,
    output wire [2:0]           m0_arsize,
    output wire [1:0]           m0_arburst,
    
    input  wire                 m0_rvalid,
    output wire                 m0_rready,
    input  wire [DATA_W-1:0]    m0_rdata,
    input  wire                 m0_rlast,
    
    // AXI Master Port 1
    output wire                 m1_awvalid,
    input  wire                 m1_awready,
    output wire [ADDR_W-1:0]    m1_awaddr,
    output wire [7:0]          m1_awlen,
    output wire [2:0]           m1_awsize,
    output wire [1:0]           m1_awburst,
    
    output wire                 m1_wvalid,
    input  wire                 m1_wready,
    output wire [DATA_W-1:0]    m1_wdata,
    output wire [(DATA_W/8)-1:0] m1_wstrb,
    output wire                 m1_wlast,
    
    output wire                 m1_arvalid,
    input  wire                 m1_arready,
    output wire [ADDR_W-1:0]    m1_araddr,
    output wire [7:0]          m1_arlen,
    output wire [2:0]           m1_arsize,
    output wire [1:0]           m1_arburst,
    
    input  wire                 m1_rvalid,
    output wire                 m1_rready,
    input  wire [DATA_W-1:0]    m1_rdata,
    input  wire                 m1_rlast,
    
    // ==========================================
    // PE Control Signals
    // ==========================================
    input  wire                 pe_start,
    input  wire [31:0]          pe_instruction,
    output wire                 pe_done
);

    // ==========================================
    // Internal Signals - Router Interconnects
    // ==========================================
    // Router has 6 ports: [0]NOC_s, [1]NOC_m, [2]axi_s0, [3]axi_s1, [4]axi_m0, [5]axi_m1
    
    // Write Address Channel - Slave side (inputs to router)
    wire [ROUTER_PORTS-1:0]     router_s_awvalid;
    wire [ROUTER_PORTS-1:0]     router_s_awready;
    wire [ADDR_W-1:0]          router_s_awaddr [ROUTER_PORTS-1:0];
    wire [7:0]                 router_s_awlen [ROUTER_PORTS-1:0];
    wire [2:0]                 router_s_awsize [ROUTER_PORTS-1:0];
    wire [1:0]                 router_s_awburst [ROUTER_PORTS-1:0];
    
    // Write Data Channel - Slave side
    wire [ROUTER_PORTS-1:0]     router_s_wvalid;
    wire [ROUTER_PORTS-1:0]     router_s_wready;
    wire [DATA_W-1:0]          router_s_wdata [ROUTER_PORTS-1:0];
    wire [(DATA_W/8)-1:0]      router_s_wstrb [ROUTER_PORTS-1:0];
    wire [ROUTER_PORTS-1:0]     router_s_wlast;
    
    // Read Address Channel - Slave side
    wire [ROUTER_PORTS-1:0]     router_s_arvalid;
    wire [ROUTER_PORTS-1:0]     router_s_arready;
    wire [ADDR_W-1:0]          router_s_araddr [ROUTER_PORTS-1:0];
    wire [7:0]                 router_s_arlen [ROUTER_PORTS-1:0];
    wire [2:0]                 router_s_arsize [ROUTER_PORTS-1:0];
    wire [1:0]                 router_s_arburst [ROUTER_PORTS-1:0];
    
    // Read Data Channel - Slave side
    wire [ROUTER_PORTS-1:0]     router_s_rvalid;
    wire [ROUTER_PORTS-1:0]     router_s_rready;
    wire [DATA_W-1:0]          router_s_rdata [ROUTER_PORTS-1:0];
    wire [ROUTER_PORTS-1:0]     router_s_rlast;
    
    // Write Address Channel - Master side (outputs from router)
    wire [ROUTER_PORTS-1:0]     router_m_awvalid;
    wire [ROUTER_PORTS-1:0]     router_m_awready;
    wire [ADDR_W-1:0]          router_m_awaddr [ROUTER_PORTS-1:0];
    wire [7:0]                 router_m_awlen [ROUTER_PORTS-1:0];
    wire [2:0]                 router_m_awsize [ROUTER_PORTS-1:0];
    wire [1:0]                 router_m_awburst [ROUTER_PORTS-1:0];
    
    // Write Data Channel - Master side
    wire [ROUTER_PORTS-1:0]     router_m_wvalid;
    wire [ROUTER_PORTS-1:0]     router_m_wready;
    wire [DATA_W-1:0]          router_m_wdata [ROUTER_PORTS-1:0];
    wire [(DATA_W/8)-1:0]      router_m_wstrb [ROUTER_PORTS-1:0];
    wire [ROUTER_PORTS-1:0]     router_m_wlast;
    
    // Read Address Channel - Master side
    wire [ROUTER_PORTS-1:0]     router_m_arvalid;
    wire [ROUTER_PORTS-1:0]     router_m_arready;
    wire [ADDR_W-1:0]          router_m_araddr [ROUTER_PORTS-1:0];
    wire [7:0]                 router_m_arlen [ROUTER_PORTS-1:0];
    wire [2:0]                 router_m_arsize [ROUTER_PORTS-1:0];
    wire [1:0]                 router_m_arburst [ROUTER_PORTS-1:0];
    
    // Read Data Channel - Master side
    wire [ROUTER_PORTS-1:0]     router_m_rvalid;
    wire [ROUTER_PORTS-1:0]     router_m_rready;
    wire [DATA_W-1:0]          router_m_rdata [ROUTER_PORTS-1:0];
    wire [ROUTER_PORTS-1:0]     router_m_rlast;
    
    // ==========================================
    // Router Instance (6-port)
    // ==========================================
    router_6port #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W),
        .FIFO_DEPTH(FIFO_DEPTH),
        .ROUTE_ENTRIES(ROUTE_ENTRIES)
    ) u_router (
        .clk(clk),
        .rst_n(rst_n),
        
        // Slave ports (inputs to router)
        .s_awvalid(router_s_awvalid),
        .s_awready(router_s_awready),
        .s_awaddr(router_s_awaddr),
        .s_awlen(router_s_awlen),
        .s_awsize(router_s_awsize),
        .s_awburst(router_s_awburst),
        
        .s_wvalid(router_s_wvalid),
        .s_wready(router_s_wready),
        .s_wdata(router_s_wdata),
        .s_wstrb(router_s_wstrb),
        .s_wlast(router_s_wlast),
        
        .s_arvalid(router_s_arvalid),
        .s_arready(router_s_arready),
        .s_araddr(router_s_araddr),
        .s_arlen(router_s_arlen),
        .s_arsize(router_s_arsize),
        .s_arburst(router_s_arburst),
        
        .s_rvalid(router_s_rvalid),
        .s_rready(router_s_rready),
        .s_rdata(router_s_rdata),
        .s_rlast(router_s_rlast),
        
        // Master ports (outputs from router)
        .m_awvalid(router_m_awvalid),
        .m_awready(router_m_awready),
        .m_awaddr(router_m_awaddr),
        .m_awlen(router_m_awlen),
        .m_awsize(router_m_awsize),
        .m_awburst(router_m_awburst),
        
        .m_wvalid(router_m_wvalid),
        .m_wready(router_m_wready),
        .m_wdata(router_m_wdata),
        .m_wstrb(router_m_wstrb),
        .m_wlast(router_m_wlast),
        
        .m_arvalid(router_m_arvalid),
        .m_arready(router_m_arready),
        .m_araddr(router_m_araddr),
        .m_arlen(router_m_arlen),
        .m_arsize(router_m_arsize),
        .m_arburst(router_m_arburst),
        
        .m_rvalid(router_m_rvalid),
        .m_rready(router_m_rready),
        .m_rdata(router_m_rdata),
        .m_rlast(router_m_rlast),
        
        // APB configuration (not used in this version)
        .paddr(12'h000),
        .pwrite(1'b0),
        .pwdata(32'h00000000),
        .psel(1'b0),
        .penable(1'b0),
        .pready(),
        .prdata()
    );
    
    // ==========================================
    // PE Instance
    // ==========================================
    pe_core_complete #(
        .DATA_WIDTH(PE_DATA_WIDTH),
        .VECTOR_WIDTH(PE_VECTOR_WIDTH)
    ) u_pe (
        .clk(clk),
        .rst_n(rst_n),
        .start(pe_start),
        .instruction(pe_instruction),
        .done(pe_done),
        .data_in(),
        .data_out(),
        .mem_addr(),
        .mem_req(),
        .mem_data_out(),
        .mem_data_in(),
        .mem_ack()
    );
    
    // ==========================================
    // Port Mapping - Router Port 0 = NOC Slave
    // ==========================================
    assign router_s_awvalid[0] = noc_s_awvalid;
    assign noc_s_awready = router_s_awready[0];
    assign router_s_awaddr[0] = noc_s_awaddr;
    assign router_s_awlen[0] = noc_s_awlen;
    assign router_s_awsize[0] = noc_s_awsize;
    assign router_s_awburst[0] = noc_s_awburst;
    
    assign router_s_wvalid[0] = noc_s_wvalid;
    assign noc_s_wready = router_s_wready[0];
    assign router_s_wdata[0] = noc_s_wdata;
    assign router_s_wstrb[0] = noc_s_wstrb;
    assign router_s_wlast[0] = noc_s_wlast;
    
    assign router_s_arvalid[0] = noc_s_arvalid;
    assign noc_s_arready = router_s_arready[0];
    assign router_s_araddr[0] = noc_s_araddr;
    assign router_s_arlen[0] = noc_s_arlen;
    assign router_s_arsize[0] = noc_s_arsize;
    assign router_s_arburst[0] = noc_s_arburst;
    
    assign noc_s_rvalid = router_s_rvalid[0];
    assign router_s_rready[0] = noc_s_rready;
    assign noc_s_rdata = router_s_rdata[0];
    assign noc_s_rlast = router_s_rlast[0];
    
    // ==========================================
    // Port Mapping - Router Port 1 = NOC Master
    // ==========================================
    assign noc_m_awvalid = router_m_awvalid[1];
    assign router_m_awready[1] = noc_m_awready;
    assign noc_m_awaddr = router_m_awaddr[1];
    assign noc_m_awlen = router_m_awlen[1];
    assign noc_m_awsize = router_m_awsize[1];
    assign noc_m_awburst = router_m_awburst[1];
    
    assign noc_m_wvalid = router_m_wvalid[1];
    assign router_m_wready[1] = noc_m_wready;
    assign noc_m_wdata = router_m_wdata[1];
    assign noc_m_wstrb = router_m_wstrb[1];
    assign noc_m_wlast = router_m_wlast[1];
    
    assign noc_m_arvalid = router_m_arvalid[1];
    assign router_m_arready[1] = noc_m_arready;
    assign noc_m_araddr = router_m_araddr[1];
    assign noc_m_arlen = router_m_arlen[1];
    assign noc_m_arsize = router_m_arsize[1];
    assign noc_m_arburst = router_m_arburst[1];
    
    assign router_m_rvalid[1] = noc_m_rvalid;
    assign noc_m_rready = router_m_rready[1];
    assign router_m_rdata[1] = noc_m_rdata;
    assign router_m_rlast[1] = noc_m_rlast;
    
    // ==========================================
    // Port Mapping - Router Port 2 = AXI Slave 0
    // ==========================================
    assign router_s_awvalid[2] = s0_awvalid;
    assign s0_awready = router_s_awready[2];
    assign router_s_awaddr[2] = s0_awaddr;
    assign router_s_awlen[2] = s0_awlen;
    assign router_s_awsize[2] = s0_awsize;
    assign router_s_awburst[2] = s0_awburst;
    
    assign router_s_wvalid[2] = s0_wvalid;
    assign s0_wready = router_s_wready[2];
    assign router_s_wdata[2] = s0_wdata;
    assign router_s_wstrb[2] = s0_wstrb;
    assign router_s_wlast[2] = s0_wlast;
    
    assign router_s_arvalid[2] = s0_arvalid;
    assign s0_arready = router_s_arready[2];
    assign router_s_araddr[2] = s0_araddr;
    assign router_s_arlen[2] = s0_arlen;
    assign router_s_arsize[2] = s0_arsize;
    assign router_s_arburst[2] = s0_arburst;
    
    assign s0_rvalid = router_s_rvalid[2];
    assign router_s_rready[2] = s0_rready;
    assign s0_rdata = router_s_rdata[2];
    assign s0_rlast = router_s_rlast[2];
    
    // ==========================================
    // Port Mapping - Router Port 3 = AXI Slave 1
    // ==========================================
    assign router_s_awvalid[3] = s1_awvalid;
    assign s1_awready = router_s_awready[3];
    assign router_s_awaddr[3] = s1_awaddr;
    assign router_s_awlen[3] = s1_awlen;
    assign router_s_awsize[3] = s1_awsize;
    assign router_s_awburst[3] = s1_awburst;
    
    assign router_s_wvalid[3] = s1_wvalid;
    assign s1_wready = router_s_wready[3];
    assign router_s_wdata[3] = s1_wdata;
    assign router_s_wstrb[3] = s1_wstrb;
    assign router_s_wlast[3] = s1_wlast;
    
    assign router_s_arvalid[3] = s1_arvalid;
    assign s1_arready = router_s_arready[3];
    assign router_s_araddr[3] = s1_araddr;
    assign router_s_arlen[3] = s1_arlen;
    assign router_s_arsize[3] = s1_arsize;
    assign router_s_arburst[3] = s1_arburst;
    
    assign s1_rvalid = router_s_rvalid[3];
    assign router_s_rready[3] = s1_rready;
    assign s1_rdata = router_s_rdata[3];
    assign s1_rlast = router_s_rlast[3];
    
    // ==========================================
    // Port Mapping - Router Port 4 = AXI Master 0
    // ==========================================
    assign m0_awvalid = router_m_awvalid[4];
    assign router_m_awready[4] = m0_awready;
    assign m0_awaddr = router_m_awaddr[4];
    assign m0_awlen = router_m_awlen[4];
    assign m0_awsize = router_m_awsize[4];
    assign m0_awburst = router_m_awburst[4];
    
    assign m0_wvalid = router_m_wvalid[4];
    assign router_m_wready[4] = m0_wready;
    assign m0_wdata = router_m_wdata[4];
    assign m0_wstrb = router_m_wstrb[4];
    assign m0_wlast = router_m_wlast[4];
    
    assign m0_arvalid = router_m_arvalid[4];
    assign router_m_arready[4] = m0_arready;
    assign m0_araddr = router_m_araddr[4];
    assign m0_arlen = router_m_arlen[4];
    assign m0_arsize = router_m_arsize[4];
    assign m0_arburst = router_m_arburst[4];
    
    assign router_m_rvalid[4] = m0_rvalid;
    assign m0_rready = router_m_rready[4];
    assign router_m_rdata[4] = m0_rdata;
    assign router_m_rlast[4] = m0_rlast;
    
    // ==========================================
    // Port Mapping - Router Port 5 = AXI Master 1
    // ==========================================
    assign m1_awvalid = router_m_awvalid[5];
    assign router_m_awready[5] = m1_awready;
    assign m1_awaddr = router_m_awaddr[5];
    assign m1_awlen = router_m_awlen[5];
    assign m1_awsize = router_m_awsize[5];
    assign m1_awburst = router_m_awburst[5];
    
    assign m1_wvalid = router_m_wvalid[5];
    assign router_m_wready[5] = m1_wready;
    assign m1_wdata = router_m_wdata[5];
    assign m1_wstrb = router_m_wstrb[5];
    assign m1_wlast = router_m_wlast[5];
    
    assign m1_arvalid = router_m_arvalid[5];
    assign router_m_arready[5] = m1_arready;
    assign m1_araddr = router_m_araddr[5];
    assign m1_arlen = router_m_arlen[5];
    assign m1_arsize = router_m_arsize[5];
    assign m1_arburst = router_m_arburst[5];
    
    assign router_m_rvalid[5] = m1_rvalid;
    assign m1_rready = router_m_rready[5];
    assign router_m_rdata[5] = m1_rdata;
    assign router_m_rlast[5] = m1_rlast;

endmodule

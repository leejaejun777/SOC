
`timescale 1 ns / 1 ps

	module myip_v1_0 #
	(
		// Users to add parameters here

		// BRAM_W Parameters
		parameter integer C_BRAM_W_DWIDTH	= 32,
		parameter integer C_BRAM_W_AWIDTH	= 10,
		parameter integer C_BRAM_W_DEPTH	= 815,

		// BRAM_I Parameters
		parameter integer C_BRAM_I_DWIDTH	= 32,
		parameter integer C_BRAM_I_AWIDTH	= 8,
		parameter integer C_BRAM_I_DEPTH	= 196,

		// AXI4-Stream Parameters
		parameter integer C_S01_AXIS_TDATA_WIDTH	= 32,

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here

		// AXI4-Stream Interface for S01 (input data)
		input wire                                  s01_axis_aclk,
		input wire                                  s01_axis_aresetn,
		input wire                                  s01_axis_tvalid,
		output wire                                 s01_axis_tready,
		input wire [C_S01_AXIS_TDATA_WIDTH-1:0]    s01_axis_tdata,
		input wire [(C_S01_AXIS_TDATA_WIDTH/8)-1:0] s01_axis_tkeep,
		input wire                                  s01_axis_tlast,

		// BRAM Interface ports
		output wire                                 bram_w_ena,
		output wire                                 bram_w_wea,
		output wire [C_BRAM_W_AWIDTH-1:0]          bram_w_addra,
		output wire [C_BRAM_W_DWIDTH-1:0]          bram_w_dina,
	// BRAM_W data input (from top BRAM instance)
	input wire [C_BRAM_W_DWIDTH-1:0]           bram_w_douta,

		output wire                                 bram_i_ena,
		output wire                                 bram_i_wea,
		output wire [C_BRAM_I_AWIDTH-1:0]          bram_i_addra,
		output wire [C_BRAM_I_DWIDTH-1:0]          bram_i_dina,

		// logic control
		output wire 								RUN_start,

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

	// Internal signals
	wire BRAM_W_en;
	wire BRAM_I_en;

// Instantiation of Axi Bus Interface S00_AXI
	myip_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myip_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		.BRAM_W_en(BRAM_W_en),
		.BRAM_I_en(BRAM_I_en),
		.RUN_start(RUN_start)
	);

	// Add user logic here

	// Instantiation of AXI4-Stream DMA Interface S01_AXI_DMA
	myip_v1_0_S01_AXI_DMA # (
		.BRAM_W_DWIDTH(C_BRAM_W_DWIDTH),
		.BRAM_W_AWIDTH(C_BRAM_W_AWIDTH),
		.BRAM_W_DEPTH(C_BRAM_W_DEPTH),
		.BRAM_I_DWIDTH(C_BRAM_I_DWIDTH),
		.BRAM_I_AWIDTH(C_BRAM_I_AWIDTH),
		.BRAM_I_DEPTH(C_BRAM_I_DEPTH),
		.C_S_AXIS_TDATA_WIDTH(C_S01_AXIS_TDATA_WIDTH)
	) myip_v1_0_S01_AXI_DMA_inst (
		.S_AXIS_ACLK(s01_axis_aclk),
		.S_AXIS_ARESETN(s01_axis_aresetn),
		.S_AXIS_TVALID(s01_axis_tvalid),
		.S_AXIS_TREADY(s01_axis_tready),
		.S_AXIS_TDATA(s01_axis_tdata),
		.S_AXIS_TKEEP(s01_axis_tkeep),
		.S_AXIS_TLAST(s01_axis_tlast),
		.BRAM_W_en(BRAM_W_en),
		.BRAM_I_en(BRAM_I_en),
		.bram_w_ena(bram_w_ena),
		.bram_w_wea(bram_w_wea),
		.bram_w_addra(bram_w_addra),
		.bram_w_dina(bram_w_dina),
		.bram_i_ena(bram_i_ena),
		.bram_i_wea(bram_i_wea),
		.bram_i_addra(bram_i_addra),
		.bram_i_dina(bram_i_dina)
	);

	// User logic ends

	endmodule

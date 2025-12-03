`timescale 1ns / 1ps

module top #
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

	// BRAM_O Parameters
	parameter integer C_BRAM_O_DWIDTH	= 32,
	parameter integer C_BRAM_O_AWIDTH	= 10,
	parameter integer C_BRAM_O_DEPTH	= 576,

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

	// AXI4-Stream Slave Interface (S01)
	input wire                                  s01_axis_aclk,
	input wire                                  s01_axis_aresetn,
	input wire                                  s01_axis_tvalid,
	output wire                                 s01_axis_tready,
	input wire [C_S01_AXIS_TDATA_WIDTH-1:0]    s01_axis_tdata,
	input wire [(C_S01_AXIS_TDATA_WIDTH/8)-1:0] s01_axis_tkeep,
	input wire                                  s01_axis_tlast,

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

	///////////////////////////////////////////////
	//////////////////// wires ////////////////////
	///////////////////////////////////////////////

	// BRAM_W Port A (AXI-Stream Write Interface)
	wire bram_w_ena;
	wire bram_w_wea;
	wire [C_BRAM_W_AWIDTH-1:0] bram_w_addra;
	wire [C_BRAM_W_DWIDTH-1:0] bram_w_dina;
	wire [C_BRAM_W_DWIDTH-1:0] bram_w_douta;

	// BRAM_W Port B (Core interface - unused)
	wire bram_w_enb = 1'b0;
	wire bram_w_web = 1'b0;
	wire [C_BRAM_W_AWIDTH-1:0] bram_w_addrb;
	wire [C_BRAM_W_DWIDTH-1:0] bram_w_dinb;
	wire [C_BRAM_W_DWIDTH-1:0] bram_w_doutb;

    // BRAM_I Port A (AXI-Stream Write Interface)
	wire bram_i_ena;
	wire bram_i_wea;
	wire [C_BRAM_I_AWIDTH-1:0] bram_i_addra;
	wire [C_BRAM_I_DWIDTH-1:0] bram_i_dina;
	wire [C_BRAM_I_DWIDTH-1:0] bram_i_douta;

	// BRAM_I Port B (Core interface - unused)
	wire bram_i_enb = 1'b0;
	wire bram_i_web = 1'b0;
	wire [C_BRAM_I_AWIDTH-1:0] bram_i_addrb;
	wire [C_BRAM_I_DWIDTH-1:0] bram_i_dinb;
	wire [C_BRAM_I_DWIDTH-1:0] bram_i_doutb;

	// BRAM_O Port A 
	wire bram_o_ena;
    wire bram_o_wea;
	wire [C_BRAM_O_AWIDTH-1:0] bram_o_addra;
    wire [C_BRAM_O_AWIDTH-1:0] bram_o_dina;
	wire [C_BRAM_O_DWIDTH-1:0] bram_o_douta;

	// BRAM_O Port B (Core interface - unused)
	wire bram_o_enb = 1'b0;
	wire bram_o_web = 1'b0;
	wire [C_BRAM_O_AWIDTH-1:0] bram_o_addrb;
	wire [C_BRAM_O_DWIDTH-1:0] bram_o_dinb;
	wire [C_BRAM_O_DWIDTH-1:0] bram_o_doutb;


    // logic control
    wire RUN_start;

	///////////////////////////////////////////////
	//////////////////// wires ////////////////////
	///////////////////////////////////////////////

	// ===================================================================
	// Instantiation of myip_v1_0 (S00 AXI-Lite + S01 AXI4-Stream DMA)
	// ===================================================================
	myip_v1_0 # (
		.C_BRAM_W_DWIDTH(C_BRAM_W_DWIDTH),
		.C_BRAM_W_AWIDTH(C_BRAM_W_AWIDTH),
		.C_BRAM_W_DEPTH(C_BRAM_W_DEPTH),
		.C_BRAM_I_DWIDTH(C_BRAM_I_DWIDTH),
		.C_BRAM_I_AWIDTH(C_BRAM_I_AWIDTH),
		.C_BRAM_I_DEPTH(C_BRAM_I_DEPTH),
		.C_S01_AXIS_TDATA_WIDTH(C_S01_AXIS_TDATA_WIDTH),
		.C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myip_v1_0_inst (
		// AXI4-Stream Slave (S01)
		.s01_axis_aclk(s00_axi_aclk),
		.s01_axis_aresetn(s00_axi_aresetn),
		.s01_axis_tvalid(s01_axis_tvalid),
		.s01_axis_tready(s01_axis_tready),
		.s01_axis_tdata(s01_axis_tdata),
		.s01_axis_tkeep(s01_axis_tkeep),
		.s01_axis_tlast(s01_axis_tlast),
		// BRAM_W Interface
		.bram_w_ena(bram_w_ena),
		.bram_w_wea(bram_w_wea),
		.bram_w_addra(bram_w_addra),
		.bram_w_dina(bram_w_dina),
		// BRAM_I Interface
		.bram_i_ena(bram_i_ena),
		.bram_i_wea(bram_i_wea),
		.bram_i_addra(bram_i_addra),
		.bram_i_dina(bram_i_dina),
        // logic control
        .RUN_start(RUN_start),
		// AXI-Lite Slave (S00)
		.s00_axi_aclk(s00_axi_aclk),
		.s00_axi_aresetn(s00_axi_aresetn),
		.s00_axi_awaddr(s00_axi_awaddr),
		.s00_axi_awprot(s00_axi_awprot),
		.s00_axi_awvalid(s00_axi_awvalid),
		.s00_axi_awready(s00_axi_awready),
		.s00_axi_wdata(s00_axi_wdata),
		.s00_axi_wstrb(s00_axi_wstrb),
		.s00_axi_wvalid(s00_axi_wvalid),
		.s00_axi_wready(s00_axi_wready),
		.s00_axi_bresp(s00_axi_bresp),
		.s00_axi_bvalid(s00_axi_bvalid),
		.s00_axi_bready(s00_axi_bready),
		.s00_axi_araddr(s00_axi_araddr),
		.s00_axi_arprot(s00_axi_arprot),
		.s00_axi_arvalid(s00_axi_arvalid),
		.s00_axi_arready(s00_axi_arready),
		.s00_axi_rdata(s00_axi_rdata),
		.s00_axi_rresp(s00_axi_rresp),
		.s00_axi_rvalid(s00_axi_rvalid),
		.s00_axi_rready(s00_axi_rready)
	);

	// ===================================================================
	// BRAM_W Instantiation (Weight BRAM)
	// ===================================================================
	// Note: Replace with your actual BRAM IP instantiation
	// Example using Xilinx BRAM with write-only port
	blk_mem_gen_w	bram_w_inst (			// width 32, depth 815
		// Port A: AXI-Stream Write
        .clka	(s00_axi_aclk),
        .ena	(bram_w_ena	 ),
        .wea	(bram_w_wea	 ),
        .addra	(bram_w_addra),
        .dina	(bram_w_dina ),
        .douta	(bram_w_douta),
		// Port B: Core Interface (unused)
        .clkb	(s00_axi_aclk),
        .enb	(bram_w_enb),
        .web	(bram_w_web),
        .addrb	(bram_w_addrb),
        .dinb	(bram_w_dinb),
        .doutb	(bram_w_doutb)
    );


	// ===================================================================
	// BRAM_I Instantiation (Input BRAM)
	// ===================================================================
	// Note: Replace with your actual BRAM IP instantiation
	// Example using Xilinx BRAM with write-only port
	blk_mem_gen_i	bram_i_inst (				// width 32, depth 196
		// Port A: AXI-Stream Write
        .clka	(s00_axi_aclk),
        .ena	(bram_i_ena	 ),
        .wea	(bram_i_wea	 ),
        .addra	(bram_i_addra),
        .dina	(bram_i_dina ),
        .douta	(bram_i_douta),
		// Port B: Core Interface (unused)
        .clkb	(s00_axi_aclk),
        .enb	(bram_i_enb),
        .web	(bram_i_web),
        .addrb	(bram_i_addrb),
        .dinb	(bram_i_dinb),
        .doutb	(bram_i_doutb)
    );

	// ===================================================================
	// BRAM_O Instantiation (Output BRAM)
	// ===================================================================
	// Note: Replace with your actual BRAM IP instantiation
	// Read-only port with dual interface
	blk_mem_gen_o	bram_o_inst (				// width 32, depth 576
		// Port A: M_AXIS Read Interface
        .clka	(s00_axi_aclk),
        .ena	(bram_o_ena	 ),
        .wea	(bram_o_wea	 ),
        .addra	(bram_o_addra),
        .dina	(bram_o_dina ),
        .douta	(bram_o_douta),
		// Port B: Core Interface (unused)
        .clkb	(s00_axi_aclk),
        .enb	(bram_o_enb),
        .web	(bram_o_web),
        .addrb	(bram_o_addrb),
        .dinb	(bram_o_dinb),
        .doutb	(bram_o_doutb)
    );

endmodule

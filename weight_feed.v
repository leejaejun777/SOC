module weight_feed(
	input  wire        clk,
	input  wire        rstn, 
	input  wire        en_in,
    input  wire        en_out,  
	input  wire [31:0] dinA,
    input  wire [31:0] dinB,
    input  wire [31:0] dinC,
    input  wire [31:0] dinD, 
	output wire [7:0] doutA,
    output wire [7:0] doutB,
    output wire [7:0] doutC,
    output wire [7:0] doutD
);

// weight registers (4 x 4 bytes)
reg [31:0] dataA;
reg [31:0] dataB;
reg [31:0] dataC;
reg [31:0] dataD;

// output registers
reg [7:0] doutA_reg;
reg [7:0] doutB_reg;
reg [7:0] doutC_reg;
reg [7:0] doutD_reg;

// MSB first version------------------------------
// data storage logic
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dataA <= 32'b0;
        dataB <= 32'b0;
        dataC <= 32'b0;
        dataD <= 32'b0;
    end else if (en_in) begin
        dataA <= dinA;
        dataB <= dinB;
        dataC <= dinC;
        dataD <= dinD;
    end else if (en_out) begin
        dataA <= {dataA[23:0], 8'b0};
        dataB <= {dataB[23:0], 8'b0};
        dataC <= {dataC[23:0], 8'b0};
        dataD <= {dataD[23:0], 8'b0};
    end
end

// data out logic 
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        doutA_reg <= 8'b0;
        doutB_reg <= 8'b0;
        doutC_reg <= 8'b0;
        doutD_reg <= 8'b0;
    end else if (en_out) begin
		doutA_reg <= dataA[31:24];
        doutB_reg <= dataB[31:24];
        doutC_reg <= dataC[31:24];
        doutD_reg <= dataD[31:24];
    end
end

assign doutA = doutA_reg;
assign doutB = doutB_reg;
assign doutC = doutC_reg;
assign doutD = doutD_reg;
//-----------------------------------------------   

/* LSB first version-----------------------------
// data storage logic
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dataA <= 32'b0;
        dataB <= 32'b0;
        dataC <= 32'b0;
        dataD <= 32'b0;
    end else if (en_in) begin
        dataA <= dinA;
        dataB <= dinB;
        dataC <= dinC;
        dataD <= dinD;
    end else if (en_out) begin
        dataA <= {8'b0, dataA[31:8]};
        dataB <= {8'b0, dataB[31:8]};
        dataC <= {8'b0, dataC[31:8]};
        dataD <= {8'b0, dataD[31:8]};
    end
end

// data out logic 
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        doutA_reg <= 8'b0;
        doutB_reg <= 8'b0;
        doutC_reg <= 8'b0;
        doutD_reg <= 8'b0;
    end else if (en_out) begin
		doutA_reg <= dataA[7:0];
        doutB_reg <= dataB[7:0];
        doutC_reg <= dataC[7:0];
        doutD_reg <= dataD[7:0];
    end
end

assign doutA = doutA_reg;
assign doutB = doutB_reg;
assign doutC = doutC_reg;
assign doutD = doutD_reg;
//-----------------------------------------------
*/
endmodule

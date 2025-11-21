module weight_feed(
	input  wire        clk,
	input  wire        rstn, 
	input  wire        en_in,
    input  wire        en_out,  
	input  wire [31:0] dinA,
    input  wire [31:0] dinB,
    input  wire [31:0] dinC,
    input  wire [31:0] dinD, 
	output reg  [7:0] doutA,
    output reg  [7:0] doutB,
    output reg  [7:0] doutC,
    output reg  [7:0] doutD
);


reg [31:0] dataA;
reg [31:0] dataB;
reg [31:0] dataC;
reg [31:0] dataD;


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
        doutA <= 8'b0;
        doutB <= 8'b0;
        doutC <= 8'b0;
        doutD <= 8'b0;
    end else if (en_out) begin
        doutA <= dataA[7:0];
        doutB <= dataB[7:0];
        doutC <= dataC[7:0];
        doutD <= dataD[7:0];
    end
end

endmodule
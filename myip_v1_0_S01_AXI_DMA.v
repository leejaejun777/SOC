`timescale 1 ns / 1 ps

	module myip_v1_0_S01_AXI_DMA #
	(
		// Users to add parameters here

		parameter BRAM_W_DWIDTH	= 32,
		parameter BRAM_W_AWIDTH	= 10,
		parameter BRAM_W_DEPTH	= 815,

		parameter BRAM_I_DWIDTH	= 32,
		parameter BRAM_I_AWIDTH	= 8,
		parameter BRAM_I_DEPTH	= 196,



		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32

	)
	(
	    // AXI4-Stream Interface Signals
	    input wire                                  S_AXIS_ACLK,    // 클럭
	    input wire                                  S_AXIS_ARESETN, // 리셋 (Active Low)
	
	    input wire                                  S_AXIS_TVALID,  // Master가 데이터를 보낼 준비가 됨
	    output wire                                 S_AXIS_TREADY,  // Slave(나)가 데이터를 받을 준비가 됨
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     S_AXIS_TDATA,   // 실제 데이터
	    input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TKEEP,   // 바이트 유효성 (보통 모두 1)
	    input wire                                  S_AXIS_TLAST,   // 패킷의 마지막 데이터임을 알림

	    // BRAM Write Control Signals
	    input wire                                  BRAM_W_en,      // Weight BRAM 쓰기 활성화
	    input wire                                  BRAM_I_en,      // Input BRAM 쓰기 활성화

		// BRAM_W Interface (Write Port)
		output wire                                 bram_w_ena,
		output wire                                 bram_w_wea,
		output wire [BRAM_W_AWIDTH-1:0]            bram_w_addra,
		output wire [BRAM_W_DWIDTH-1:0]            bram_w_dina,

		// BRAM_I Interface (Write Port)
		output wire                                 bram_i_ena,
		output wire                                 bram_i_wea,
		output wire [BRAM_I_AWIDTH-1:0]            bram_i_addra,
		output wire [BRAM_I_DWIDTH-1:0]            bram_i_dina

	);

		// 내부 신호 선언
		wire axis_write_handshake;
		reg [BRAM_W_AWIDTH-1:0] bram_w_addr_cnt;    // Weight BRAM 주소 카운터
		reg [BRAM_I_AWIDTH-1:0] bram_i_addr_cnt;    // Input BRAM 주소 카운터
		reg backpressure_flag_w;                     // Weight BRAM backpressure
		reg backpressure_flag_i;                     // Input BRAM backpressure
		reg packet_done;

		// Active flags: external control signals are 1-cycle pulses.
		// Latch them into _active registers that remain asserted until transfer completes.
		reg bram_w_active; // stays high while writing to W BRAM
		reg bram_i_active; // stays high while writing to I BRAM

		// --- AXI4-Stream 핸드셰이크 ---
		// Master가 보내고(TVALID=1) && Slave가 받을 수 있을 때(TREADY=1)
		assign axis_write_handshake = S_AXIS_TVALID && S_AXIS_TREADY;

		// -------------------------------------------------------------------
		// BRAM_W: start on BRAM_W_en pulse (synchronous to S_AXIS_ACLK),
		//         keep bram_w_active until BRAM_W transfer finishes (address wraps)
		//         OR S_AXIS_TLAST is asserted (packet ends)
		// -------------------------------------------------------------------
		always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
			if (~S_AXIS_ARESETN) begin
				bram_w_active <= 1'b0;
			end else begin
				// latch start pulse
				if (BRAM_W_en) begin
					bram_w_active <= 1'b1;
				end else if (bram_w_active && axis_write_handshake && (bram_w_addr_cnt == BRAM_W_DEPTH-1 || S_AXIS_TLAST)) begin
					// finish when last address written OR packet ends (TLAST)
					bram_w_active <= 1'b0;
				end
			end
		end

		// BRAM_W 주소 카운터
		always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
			if (~S_AXIS_ARESETN) begin
				bram_w_addr_cnt <= 0;
			end else if (bram_w_active && axis_write_handshake) begin
				// BRAM_W가 가득 차면 주소 리셋, 아니면 증가
				if (bram_w_addr_cnt == BRAM_W_DEPTH - 1) begin
					bram_w_addr_cnt <= 0;
				end else begin
					bram_w_addr_cnt <= bram_w_addr_cnt + 1;
				end
			end
		end

		// Weight BRAM Backpressure 제어 (active 중에만 체크)
		always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
			if (~S_AXIS_ARESETN) begin
				backpressure_flag_w <= 1'b0;
			end else if (bram_w_active) begin
				if (bram_w_addr_cnt >= (BRAM_W_DEPTH - 1)) begin
					backpressure_flag_w <= 1'b1;
				end else begin
					backpressure_flag_w <= 1'b0;
				end
			end else begin
				backpressure_flag_w <= 1'b0;
			end
		end

		// Weight BRAM 제어 신호
		assign bram_w_addra = bram_w_addr_cnt;
		assign bram_w_ena   = axis_write_handshake && bram_w_active;
		assign bram_w_wea   = axis_write_handshake && bram_w_active;
		assign bram_w_dina  = S_AXIS_TDATA;

		// -------------------------------------------------------------------
		// BRAM_I: start on BRAM_I_en pulse (synchronous to S_AXIS_ACLK),
		//         keep bram_i_active until transfer finishes
		//         OR S_AXIS_TLAST is asserted (packet ends)
		// -------------------------------------------------------------------
		always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
			if (~S_AXIS_ARESETN) begin
				bram_i_active <= 1'b0;
			end else begin
				if (BRAM_I_en) begin
					bram_i_active <= 1'b1;
				end else if (bram_i_active && axis_write_handshake && (bram_i_addr_cnt == BRAM_I_DEPTH-1 || S_AXIS_TLAST)) begin
					// finish when last address written OR packet ends (TLAST)
					bram_i_active <= 1'b0;
				end
			end
		end

		// BRAM_I 주소 카운터
		always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
			if (~S_AXIS_ARESETN) begin
				bram_i_addr_cnt <= 0;
			end else if (bram_i_active && axis_write_handshake) begin
				// BRAM_I가 가득 차면 주소 리셋, 아니면 증가
				if (bram_i_addr_cnt == BRAM_I_DEPTH - 1) begin
					bram_i_addr_cnt <= 0;
				end else begin
					bram_i_addr_cnt <= bram_i_addr_cnt + 1;
				end
			end
		end

		// Input BRAM Backpressure 제어
		always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
			if (~S_AXIS_ARESETN) begin
				backpressure_flag_i <= 1'b0;
			end else if (bram_i_active) begin
				if (bram_i_addr_cnt >= (BRAM_I_DEPTH - 1)) begin
					backpressure_flag_i <= 1'b1;
				end else begin
					backpressure_flag_i <= 1'b0;
				end
			end else begin
				backpressure_flag_i <= 1'b0;
			end
		end

		// Input BRAM 제어 신호
		assign bram_i_addra = bram_i_addr_cnt;
		assign bram_i_ena   = axis_write_handshake && bram_i_active;
		assign bram_i_wea   = axis_write_handshake && bram_i_active;
		assign bram_i_dina  = S_AXIS_TDATA;

		// ===================================================================
		// 통합 TREADY 제어 (둘 중 하나라도 backpressure이면 정지)
		// ===================================================================
		assign S_AXIS_TREADY = ~(backpressure_flag_w || backpressure_flag_i);

		// --- 패킷 끝 감지 (TLAST) ---
		always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
			if (~S_AXIS_ARESETN) begin
				packet_done <= 1'b0;
			end else begin
				if (axis_write_handshake && S_AXIS_TLAST) begin
					packet_done <= 1'b1;  // 패킷 끝 감지
				end else begin
					packet_done <= 1'b0;  // 한 사이클만 유지
				end
			end
		end
endmodule

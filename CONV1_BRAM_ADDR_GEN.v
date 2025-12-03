/*
 * ======================================================================================
 * Module Name: CONV1_BRAM_ADDR_GEN
 * Description: Generates BRAM read addresses for CONV1 layer with specific timing sequences.
 * * [1] Address Calculation Logic (Why +7, +14...?)
 * --------------------------------------------------------------------------------------
 * - Input Image Width : 28 pixels
 * - BRAM Data Width   : 32-bit (4 pixels per address)
 * - Addresses per Row : 28 pixels / 4 = 7 addresses
 * * Therefore, the start address of each row relative to the Base Address is:
 * - Row 0: Base + 0
 * - Row 1: Base + 7  (1 * 7)
 * - Row 2: Base + 14 (2 * 7)
 * - Row 3: Base + 21 (3 * 7)
 * - Row 4: Base + 28 (4 * 7)
 * - Row 5: Base + 35 (5 * 7)
 *
 * [2] Operation Sequence (25 Cycles per Tile) 
 * --------------------------------------------------------------------------------------
 * Step 0 ~ 3  : [Read] Row 0 & 1 (Addr: Base, Base+1, Base+7, Base+8) -> 4 addrs
 * Step 4 ~ 6  : [Rest] 3 Cycles
 * Step 7 ~ 8  : [Read] Row 2     (Addr: Base+14, Base+15)             -> 2 addrs
 * Step 9 ~ 11 : [Rest] 3 Cycles
 * Step 12 ~ 13: [Read] Row 3     (Addr: Base+21, Base+22)             -> 2 addrs
 * Step 14 ~ 16: [Rest] 3 Cycles
 * Step 17 ~ 18: [Read] Row 4     (Addr: Base+28, Base+29)             -> 2 addrs
 * Step 19 ~ 21: [Rest] 3 Cycles
 * Step 22 ~ 23: [Read] Row 5     (Addr: Base+35, Base+36)             -> 2 addrs
 * Step 24     : [Rest] 1 Cycle   (End of Tile -> Update c, d)
 * ======================================================================================
 */
`timescale 1ns / 1ps

module CONV1_BRAM_ADDR_GEN (
    input wire clk,
    input wire rst_n,
    input wire start,

    // BRAM Interface (0~195 range)
    output reg [7:0] bram_addr,
    output reg bram_en,

    // Status Signals
    output reg done,      // 전체 모든 타일 처리 완료 (Global Done)
    output reg seq_done,  // [NEW] 현재 타일 시퀀스(Step 24) 완료 (Sequence Done)
    output reg busy,
    
    // Debug Outputs
    output reg [3:0] current_d,
    output reg [3:0] current_c,
    output reg [4:0] seq_step
);

    // --- Parameters ---
    localparam IMG_WIDTH = 28;
    
    // --- Internal Registers ---
    reg [3:0] cnt_d;   // Vertical Tile Index (0 ~ 11)
    reg [3:0] cnt_c;   // Horizontal Tile Index (0 ~ 11)
    reg [4:0] seq_cnt; // Sequence Counter (0 ~ 24)
    
    // --- Base Address Calculation ---
    reg [9:0] start_pixel_idx;
    reg [7:0] base_addr;

    always @(*) begin
        // Calculate Top-Left Pixel Index for current tile (Stride=2)
        start_pixel_idx = (((cnt_d << 1)) * IMG_WIDTH) + (cnt_c << 1);
        // Convert Pixel Index to BRAM Address (Divide by 4)
        base_addr = start_pixel_idx[9:2];
    end

    // --- State Machine & Logic ---
    localparam IDLE = 1'b0;
    localparam RUN  = 1'b1;
    reg state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cnt_d <= 0;
            cnt_c <= 0;
            seq_cnt <= 5'd31; // Idle 상태에서 의미 없는 값으로 설정
            bram_addr <= 0;
            bram_en <= 0;
            busy <= 0;
            done <= 0;
            seq_done <= 0; // Reset new signal
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    seq_done <= 0;
                    if (start) begin
                        state <= RUN;
                        busy <= 1;
                        cnt_d <= 0;
                        cnt_c <= 0;
                        seq_cnt <= 0;
                    end else begin
                        busy <= 0;
                        bram_en <= 0;
                    end
                end

                RUN: begin
                    // --- Sequence Logic (0 ~ 24 Step) ---
                    case (seq_cnt)
                        // [Start] Row 0 & 1 (4 Addresses)
                        5'd0: begin bram_addr <= base_addr + 0;  bram_en <= 1; end
                        5'd1: begin bram_addr <= base_addr + 1;  bram_en <= 1; end
                        5'd2: begin bram_addr <= base_addr + 7;  bram_en <= 1; end
                        5'd3: begin bram_addr <= base_addr + 8;  bram_en <= 1; end
                        
                        // [Rest] 3 Cycles
                        5'd4, 5'd5, 5'd6: begin bram_en <= 0; end
                        
                        // [Row 2] 2 Addresses
                        5'd7: begin bram_addr <= base_addr + 14; bram_en <= 1; end
                        5'd8: begin bram_addr <= base_addr + 15; bram_en <= 1; end
                        
                        // [Rest] 3 Cycles
                        5'd9, 5'd10, 5'd11: begin bram_en <= 0; end
                        
                        // [Row 3] 2 Addresses
                        5'd12: begin bram_addr <= base_addr + 21; bram_en <= 1; end
                        5'd13: begin bram_addr <= base_addr + 22; bram_en <= 1; end
                        
                        // [Rest] 3 Cycles
                        5'd14, 5'd15, 5'd16: begin bram_en <= 0; end
                        
                        // [Row 4] 2 Addresses
                        5'd17: begin bram_addr <= base_addr + 28; bram_en <= 1; end
                        5'd18: begin bram_addr <= base_addr + 29; bram_en <= 1; end
                        
                        // [Rest] 3 Cycles
                        5'd19, 5'd20, 5'd21: begin bram_en <= 0; end
                        
                        // [Row 5] 2 Addresses
                        5'd22: begin bram_addr <= base_addr + 35; bram_en <= 1; end
                        5'd23: begin bram_addr <= base_addr + 36; bram_en <= 1; end
                        
                        // [Step 24] Last step of sequence
                        5'd24: begin 
                            bram_en <= 0; 
                        end
                        
                        default: begin bram_en <= 0; end
                    endcase

                    // --- Counter Updates & Seq Done Logic ---
                    if (seq_cnt == 24) begin
                        seq_cnt <= 0; 
                        seq_done <= 1; // [NEW] 타일 시퀀스 완료 플래그 발생 (1클럭 Pulse)
                        
                        // Tile Update
                        if (cnt_c == 11) begin
                            cnt_c <= 0;
                            if (cnt_d == 11) begin
                                state <= IDLE;
                                done <= 1;
                                busy <= 0;
                            end else begin
                                cnt_d <= cnt_d + 1;
                            end
                        end else begin
                            cnt_c <= cnt_c + 1;
                        end
                    end else begin
                        seq_cnt <= seq_cnt + 1;
                        seq_done <= 0; // 그 외 구간에서는 0 유지
                    end
                end
            endcase
        end
    end
    
    // Debug Outputs
    always @(posedge clk) begin
        current_d <= cnt_d;
        current_c <= cnt_c;
        seq_step <= seq_cnt;
    end

endmodule
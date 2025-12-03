`timescale 1ns / 1ps

module CONV1_INPUT_FEED (
    input wire clk,
    input wire rst_n,

    // Inputs
    input wire [31:0] bram_data,
    input wire [4:0] seq_step,
    input wire [3:0] cnt_c,

    // FIFO Interface
    output reg wr_en_0, output reg [2:0] wr_len_0, output reg [39:0] wr_data_0, 
    output reg wr_en_1, output reg [2:0] wr_len_1, output reg [39:0] wr_data_1, 
    output reg wr_en_2, output reg [2:0] wr_len_2, output reg [39:0] wr_data_2, 
    output reg wr_en_3, output reg [2:0] wr_len_3, output reg [39:0] wr_data_3 
);

    // --- Pipeline Registers ---
    reg [4:0] step_d1;
    reg [3:0] c_d1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step_d1 <= 0;
            c_d1 <= 0;
        end else begin
            step_d1 <= seq_step;
            c_d1 <= cnt_c;
        end
    end

    // --- Data Storage ---
    reg [31:0] buf_bram_data; // Low Addr Data 저장용
    
    wire c_is_odd = c_d1[0]; // 0: Even, 1: Odd

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf_bram_data <= 0;
            wr_en_0 <= 0; wr_len_0 <= 0; wr_data_0 <= 0;
            wr_en_1 <= 0; wr_len_1 <= 0; wr_data_1 <= 0;
            wr_en_2 <= 0; wr_len_2 <= 0; wr_data_2 <= 0;
            wr_en_3 <= 0; wr_len_3 <= 0; wr_data_3 <= 0;
        end else begin
            // Default: Disable Writes
            wr_en_0 <= 0; wr_en_1 <= 0; wr_en_2 <= 0; wr_en_3 <= 0;

            case (step_d1)
                // ============================================================
                // [Row 0] Addr 0, 1 -> Feeds Col 0, 1
                // ============================================================
                
                // [Step 0] Addr 0 Data (Low)
                5'd0: begin
                    buf_bram_data <= bram_data; // Save for Col 1 usage in next step

                    if (!c_is_odd) begin 
                        // [Even] Write 4 Byte to Col 0
                        wr_en_0 <= 1; wr_len_0 <= 4; 
                        wr_data_0 <= {8'h00, bram_data}; 
                    end else begin
                        // [Odd] Write 2 Byte to Col 0 (Upper half)
                        wr_en_0 <= 1; wr_len_0 <= 2; 
                        wr_data_0 <= {24'h000000, bram_data[31:16]}; 
                    end
                end

                // [Step 1] Addr 1 Data (High)
                5'd1: begin
                    if (!c_is_odd) begin 
                        // [Even]
                        // Col 0: 나머지 1 Byte (bram_data[7:0])
                        wr_en_0 <= 1; wr_len_0 <= 1; 
                        wr_data_0 <= {32'h00000000, bram_data[7:0]};

                        // Col 1: 5 Byte 한번에 (Low의 상위 3B + High의 하위 2B)
                        wr_en_1 <= 1; wr_len_1 <= 5; 
                        wr_data_1 <= {bram_data[15:0], buf_bram_data[31:8]};
                    end else begin
                        // [Odd]
                        // Col 0: 나머지 3 Byte (bram_data[23:0])
                        wr_en_0 <= 1; wr_len_0 <= 3; 
                        wr_data_0 <= {16'h0000, bram_data[23:0]};

                        // Col 1: 5 Byte 한번에 (Low의 상위 1B + High 전체)
                        wr_en_1 <= 1; wr_len_1 <= 5;
                        wr_data_1 <= {bram_data, buf_bram_data[31:24]};
                    end
                end


                // ============================================================
                // [Row 1, 2, 3, 4] -> Feeds All Cols (0, 1, 2, 3)
                // ============================================================
                
                // Low Data Arrives: Save & First Write to Col 0, 2
                5'd2, 5'd7, 5'd12, 5'd17: begin
                    buf_bram_data <= bram_data;

                    if (!c_is_odd) begin 
                        wr_en_0 <= 1; wr_len_0 <= 4; wr_data_0 <= {8'h00, bram_data};
                        wr_en_2 <= 1; wr_len_2 <= 4; wr_data_2 <= {8'h00, bram_data};
                    end else begin
                        wr_en_0 <= 1; wr_len_0 <= 2; wr_data_0 <= {24'h00, bram_data[31:16]};
                        wr_en_2 <= 1; wr_len_2 <= 2; wr_data_2 <= {24'h00, bram_data[31:16]};
                    end
                end

                // High Data Arrives: Remainder to Col 0, 2 & Batch to Col 1, 3
                5'd3, 5'd8, 5'd13, 5'd18: begin
                    if (!c_is_odd) begin 
                        // Col 0 & 2: Remainder 1 Byte
                        wr_en_0 <= 1; wr_len_0 <= 1; wr_data_0 <= {32'h0, bram_data[7:0]};
                        wr_en_2 <= 1; wr_len_2 <= 1; wr_data_2 <= {32'h0, bram_data[7:0]};

                        // Col 1 & 3: Batch 5 Byte
                        wr_en_1 <= 1; wr_len_1 <= 5; wr_data_1 <= {bram_data[15:0], buf_bram_data[31:8]};
                        wr_en_3 <= 1; wr_len_3 <= 5; wr_data_3 <= {bram_data[15:0], buf_bram_data[31:8]};
                    end else begin
                        // Col 0 & 2: Remainder 3 Byte
                        wr_en_0 <= 1; wr_len_0 <= 3; wr_data_0 <= {16'h0000, bram_data[23:0]};
                        wr_en_2 <= 1; wr_len_2 <= 3; wr_data_2 <= {16'h0000, bram_data[23:0]};

                        // Col 1 & 3: Batch 5 Byte
                        wr_en_1 <= 1; wr_len_1 <= 5; wr_data_1 <= {bram_data, buf_bram_data[31:24]};
                        wr_en_3 <= 1; wr_len_3 <= 5; wr_data_3 <= {bram_data, buf_bram_data[31:24]};
                    end
                end

                // ============================================================
                // [Row 5] Addr 35, 36 -> Feeds Col 2, 3 ONLY (Disable Col 0, 1)
                // ============================================================

                // Low Data (Addr 35)
                5'd22: begin
                    buf_bram_data <= bram_data;

                    if (!c_is_odd) begin 
                        // Only Write to Col 2
                        wr_en_2 <= 1; wr_len_2 <= 4; wr_data_2 <= {8'h00, bram_data};
                    end else begin
                        // Only Write to Col 2
                        wr_en_2 <= 1; wr_len_2 <= 2; wr_data_2 <= {24'h00, bram_data[31:16]};
                    end
                    // wr_en_0 is 0 by default
                end

                // High Data (Addr 36)
                5'd23: begin
                    if (!c_is_odd) begin 
                        // Only Write to Col 2 & 3
                        wr_en_2 <= 1; wr_len_2 <= 1; wr_data_2 <= {32'h0, bram_data[7:0]};
                        wr_en_3 <= 1; wr_len_3 <= 5; wr_data_3 <= {bram_data[15:0], buf_bram_data[31:8]};
                    end else begin
                        // Only Write to Col 2 & 3
                        wr_en_2 <= 1; wr_len_2 <= 3; wr_data_2 <= {16'h0000, bram_data[23:0]};
                        wr_en_3 <= 1; wr_len_3 <= 5; wr_data_3 <= {bram_data, buf_bram_data[31:24]};
                    end
                    // wr_en_0, wr_en_1 are 0 by default
                end

                default: begin
                    // Idle steps
                end
            endcase
        end
    end

endmodule
`timescale 1ns / 1ps

module tb_CONV1_INPUT_FULL;

    // --- Inputs ---
    reg clk;
    reg rst_n;
    reg start;
    reg rd_en; // PE Read Enable

    // --- Outputs ---
    wire [7:0] bram_addr;
    wire bram_en;
    wire done;
    wire busy;
    wire seq_done;

    // FIFO Outputs
    wire [7:0] rd_data_0, rd_data_1, rd_data_2, rd_data_3;
    wire empty_0, empty_1, empty_2, empty_3;
    wire [3:0] count_0, count_1, count_2, count_3;

    // --- File I/O ---
    integer f_log;

    // --- Mock BRAM Logic ---
    reg [31:0] bram_data_sim;
    reg [7:0] byte3, byte2, byte1, byte0;
    
    // --- DUT Instantiation ---
    CONV1_INPUT u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .bram_addr(bram_addr),
        .bram_en(bram_en),
        .bram_data(bram_data_sim),
        .rd_en(rd_en),
        .rd_data_0(rd_data_0), .empty_0(empty_0), .count_0(count_0),
        .rd_data_1(rd_data_1), .empty_1(empty_1), .count_1(count_1),
        .rd_data_2(rd_data_2), .empty_2(empty_2), .count_2(count_2),
        .rd_data_3(rd_data_3), .empty_3(empty_3), .count_3(count_3),
        .done(done),
        .busy(busy),
        .seq_done(seq_done)
    );

    // --- Clock Generation ---
    always #5 clk = ~clk;

    // --- BRAM Simulation (28x28 Full Image) ---
    always @(posedge clk) begin
        if (bram_en) begin
            // Byte 값 = Address * 4 + offset (0~783 픽셀 인덱스와 동일)
            byte3 = (bram_addr * 4) + 3;
            byte2 = (bram_addr * 4) + 2;
            byte1 = (bram_addr * 4) + 1;
            byte0 = (bram_addr * 4) + 0;
            bram_data_sim <= {byte3, byte2, byte1, byte0};
        end
    end

    // --- Auto Read Control Logic ---
    reg pe_active;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en <= 0;
            pe_active <= 0;
        end else begin
            
            if (!pe_active && count_0 > 2) begin
        pe_active <= 1;
        rd_en <= 1;
        $display("[System] PE Read Started (Buffered Enough Data)");
    end
        end
    end

    // --- Data Logging (Decimal Format) ---
    always @(posedge clk) begin
        if (rd_en) begin
            // CSV 포맷: Time, Data0, Data1, Data2, Data3
            // 수정: %h -> %0d (Unsigned Decimal)
            $fwrite(f_log, "%0t", $time);
            
            if (!empty_0) $fwrite(f_log, ",%0d", rd_data_0); else $fwrite(f_log, ",xx");
            if (!empty_1) $fwrite(f_log, ",%0d", rd_data_1); else $fwrite(f_log, ",xx");
            if (!empty_2) $fwrite(f_log, ",%0d", rd_data_2); else $fwrite(f_log, ",xx");
            if (!empty_3) $fwrite(f_log, ",%0d", rd_data_3); else $fwrite(f_log, ",xx");
            
            $fwrite(f_log, "\n");
        end
    end

    // --- Main Stimulus ---
    initial begin
        // 파일 열기
        f_log = $fopen("fifo_read_trace_decimal.csv", "w"); // 파일명 변경
        if (f_log == 0) begin
            $display("Error: Could not open log file.");
            $finish;
        end
        $fwrite(f_log, "Time,FIFO0,FIFO1,FIFO2,FIFO3\n"); // Header

        // 초기화
        clk = 0; rst_n = 1; start = 0; rd_en = 0;
        
        $display("=== FULL IMAGE SIMULATION START (DECIMAL LOG) ===");
        
        // Reset
        #20 rst_n = 0;
        #20 rst_n = 1;
        #20;

        // Start
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait until DONE
        $display("[System] Processing... (Waiting for DONE signal)");
        wait(done);
        
        $display("[System] DONE signal received. Waiting for FIFOs to drain...");
        
        // FIFO 잔여 데이터 처리 대기
        #500; 

        $display("=== SIMULATION FINISHED ===");
        $fclose(f_log);
        $finish;
    end

endmodule
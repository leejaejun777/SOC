`timescale 1ns / 1ps

module CONV1_INPUT (
    input wire clk,
    input wire rst_n,
    input wire start,

    // BRAM Interface
    output wire [7:0] bram_addr,
    output wire bram_en,
    input wire [31:0] bram_data, // From External BRAM

    // FIFO Read Interface (To Systolic Array / PE)
    input wire rd_en, // Common Read Enable for all FIFOs (Systolic Step)
    output wire [7:0] rd_data_0, output wire empty_0, output wire [3:0] count_0,
    output wire [7:0] rd_data_1, output wire empty_1, output wire [3:0] count_1,
    output wire [7:0] rd_data_2, output wire empty_2, output wire [3:0] count_2,
    output wire [7:0] rd_data_3, output wire empty_3, output wire [3:0] count_3,

    // Global Status
    output wire done,
    output wire busy,
    output wire seq_done
);

    // --- Internal Signals ---
    // AddrGen -> InputFeed
    wire [4:0] w_seq_step;
    wire [3:0] w_cnt_c;
    
    // InputFeed -> FIFOs
    wire wr_en_0, wr_en_1, wr_en_2, wr_en_3;
    wire [2:0] wr_len_0, wr_len_1, wr_len_2, wr_len_3;
    wire [39:0] wr_data_0, wr_data_1, wr_data_2, wr_data_3;
    
    // FIFO Full Signals (Not used for flow control in this specific design, but good to have)
    wire full_0, full_1, full_2, full_3;

    // --- 1. Address Generator Instance ---
    CONV1_BRAM_ADDR_GEN u_addr_gen (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .bram_addr(bram_addr),
        .bram_en(bram_en),
        .done(done),
        .seq_done(seq_done),
        .busy(busy),
        .current_d(), // Open (Debug only)
        .current_c(w_cnt_c),
        .seq_step(w_seq_step)
    );

    // --- 2. Input Feed Logic Instance ---
    CONV1_INPUT_FEED u_input_feed (
        .clk(clk),
        .rst_n(rst_n),
        .bram_data(bram_data),
        .seq_step(w_seq_step),
        .cnt_c(w_cnt_c),
        
        // FIFO 0
        .wr_en_0(wr_en_0), .wr_data_0(wr_data_0), .wr_len_0(wr_len_0),
        // FIFO 1
        .wr_en_1(wr_en_1), .wr_data_1(wr_data_1), .wr_len_1(wr_len_1),
        // FIFO 2
        .wr_en_2(wr_en_2), .wr_data_2(wr_data_2), .wr_len_2(wr_len_2),
        // FIFO 3
        .wr_en_3(wr_en_3), .wr_data_3(wr_data_3), .wr_len_3(wr_len_3)
    );

    // --- 3. FIFO Instances (4x) ---
    // Parameters: DATA_WIDTH=8, FIFO_DEPTH=16 (Safe size), MAX_WR=5
    localparam FIFO_DEPTH = 8; 

    Multi_Input_Shift_Register_FIFO #(
        .DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH), .MAX_WR_BYTES(5)
    ) u_fifo_0 (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en_0), .wr_data(wr_data_0), .wr_len(wr_len_0), .full(full_0),
        .rd_en(rd_en), .rd_data(rd_data_0), .empty(empty_0), .data_count(count_0)
    );

    Multi_Input_Shift_Register_FIFO #(
        .DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH), .MAX_WR_BYTES(5)
    ) u_fifo_1 (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en_1), .wr_data(wr_data_1), .wr_len(wr_len_1), .full(full_1),
        .rd_en(rd_en), .rd_data(rd_data_1), .empty(empty_1), .data_count(count_1)
    );

    Multi_Input_Shift_Register_FIFO #(
        .DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH), .MAX_WR_BYTES(5)
    ) u_fifo_2 (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en_2), .wr_data(wr_data_2), .wr_len(wr_len_2), .full(full_2),
        .rd_en(rd_en), .rd_data(rd_data_2), .empty(empty_2), .data_count(count_2)
    );

    Multi_Input_Shift_Register_FIFO #(
        .DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH), .MAX_WR_BYTES(5)
    ) u_fifo_3 (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en_3), .wr_data(wr_data_3), .wr_len(wr_len_3), .full(full_3),
        .rd_en(rd_en), .rd_data(rd_data_3), .empty(empty_3), .data_count(count_3)
    );

endmodule
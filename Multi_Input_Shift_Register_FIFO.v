`timescale 1ns / 1ps

module Multi_Input_Shift_Register_FIFO #(
    parameter DATA_WIDTH = 8,    // 기본 데이터 폭 (1 Byte)
    parameter FIFO_DEPTH = 8,    // FIFO 깊이 (입력이 4Byte씩 들어오므로 8은 금방 찹니다. 필요시 늘리세요)
    parameter MAX_WR_BYTES = 5   // 최대 한 번에 쓸 수 있는 바이트 수
)(
    input wire clk,
    input wire rst_n,

    // Write Interface (Variable Length)
    input wire wr_en,
    input wire [(DATA_WIDTH * MAX_WR_BYTES)-1 : 0] wr_data, // 32-bit (4 Byte)
    input wire [2:0] wr_len,     // 입력 바이트 수 (1 ~ 5)
    output wire full,            // 공간 부족 경고 (이번 데이터가 다 못 들어갈 경우)

    // Read Interface (Single Byte)
    input wire rd_en,
    output wire [DATA_WIDTH-1 : 0] rd_data, // 항상 mem[0] (1 Byte)
    output wire empty,

    // Status
    output reg [$clog2(FIFO_DEPTH):0] data_count
);

    // --- Internal Memory ---
    reg [DATA_WIDTH-1 : 0] mem [0 : FIFO_DEPTH-1];
    integer i;

    // --- Status Logic ---
    assign empty = (data_count == 0);
    
    // Full 로직 변경: "이번에 들어올 데이터(wr_len)를 받을 공간이 없으면 Full"
    // (엄밀히 말하면 'Not Enough Space' 신호에 가깝습니다)
    assign full = (data_count + wr_len > FIFO_DEPTH);

    // Read Data는 항상 맨 앞(0번지)
    assign rd_data = mem[0];

    // --- Main Logic ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_count <= 0;
            for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            
            // --- CASE 1: Read & Write Simultaneous ---
            // (1개 나가고, wr_len개 들어옴)
            // 공간 체크: (현재 - 1 + 들어올것) <= 깊이
            if (rd_en && !empty && wr_en && (data_count - 1 + wr_len <= FIFO_DEPTH)) begin
                
                // 1. Shift Operation (1칸 당기기)
                for (i = 0; i < FIFO_DEPTH - 1; i = i + 1) begin
                    mem[i] <= mem[i+1];
                end
                
                // 2. Write Operation (데이터 덮어쓰기)
                // Shift가 일어났으므로, 데이터가 들어갈 시작점은 (data_count - 1)입니다.
                // Verilog Non-blocking 할당 특성상, 아래 코드가 위 Shift 코드보다 나중에(우선순위 높게) 기술되면 덮어씌워집니다.
                
                if (wr_len >= 1) mem[data_count - 1]     <= wr_data[DATA_WIDTH*1-1 : DATA_WIDTH*0];
                if (wr_len >= 2) mem[data_count]         <= wr_data[DATA_WIDTH*2-1 : DATA_WIDTH*1];
                if (wr_len >= 3) mem[data_count + 1]     <= wr_data[DATA_WIDTH*3-1 : DATA_WIDTH*2];
                if (wr_len >= 4) mem[data_count + 2]     <= wr_data[DATA_WIDTH*4-1 : DATA_WIDTH*3];
                if (wr_len >= 5) mem[data_count + 3]     <= wr_data[DATA_WIDTH*5-1 : DATA_WIDTH*4];

                // 3. Update Count
                data_count <= data_count - 1 + wr_len;
            end
            
            // --- CASE 2: Read Only ---
            else if (rd_en && !empty) begin
                // Shift
                for (i = 0; i < FIFO_DEPTH - 1; i = i + 1) begin
                    mem[i] <= mem[i+1];
                end
                mem[FIFO_DEPTH-1] <= 0; // Clean up last
                data_count <= data_count - 1;
            end
            
            // --- CASE 3: Write Only ---
            // 공간 체크: (현재 + 들어올것) <= 깊이
            else if (wr_en && (data_count + wr_len <= FIFO_DEPTH)) begin
                // Append at the end
                if (wr_len >= 1) mem[data_count]         <= wr_data[DATA_WIDTH*1-1 : DATA_WIDTH*0];
                if (wr_len >= 2) mem[data_count + 1]     <= wr_data[DATA_WIDTH*2-1 : DATA_WIDTH*1];
                if (wr_len >= 3) mem[data_count + 2]     <= wr_data[DATA_WIDTH*3-1 : DATA_WIDTH*2];
                if (wr_len >= 4) mem[data_count + 3]     <= wr_data[DATA_WIDTH*4-1 : DATA_WIDTH*3];
                if (wr_len >= 5) mem[data_count + 4]     <= wr_data[DATA_WIDTH*5-1 : DATA_WIDTH*4];
                
                data_count <= data_count + wr_len;
            end
        end
    end

endmodule
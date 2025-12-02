def get_2x2_input_trace_stride2():
    trace_output = []
    cycle_count = 0
    
    # 24x24 출력을 2x2 블록으로 처리 -> 가로 12번, 세로 12번 반복
    # d: 세로 블록 인덱스 (0~11), c: 가로 블록 인덱스 (0~11)
    for d in range(12):
        for c in range(12):
            
            # 현재 타일의 기준 좌표 (Top-Left)
            # Stride가 2이므로 2를 곱해줍니다.
            base_row = d * 2
            base_col = c * 2
            
            step_str = f"cycle {cycle_count} (Tile at d={d}, c={c})\n"
            
            # PE 4개의 오프셋 (Row Offset, Col Offset)
            # col0(0,0), col1(0,1), col2(1,0), col3(1,1)
            pe_configs = [
                ("col0", 0, 0),
                ("col1", 0, 1),
                ("col2", 1, 0),
                ("col3", 1, 1)
            ]
            
            for pe_name, r_off, c_off in pe_configs:
                window_rows = []
                for b in range(5): # Kernel Row (0~4)
                    row_pixels = []
                    for a in range(5): # Kernel Col (0~4)
                        # 주소 계산
                        # Row = (기준 행) + (커널 행 b) + (PE 오프셋 r_off)
                        # Col = (기준 열) + (커널 열 a) + (PE 오프셋 c_off)
                        row = base_row + b + r_off
                        col = base_col + a + c_off
                        
                        pixel_index = (row * 28) + col
                        row_pixels.append(str(pixel_index))
                    
                    window_rows.append(", ".join(row_pixels))
                
                # 5개의 행을 탭으로 연결하여 한 줄에 출력
                col_data = "\t\t".join(window_rows)
                step_str += f"{pe_name} : {col_data}\n"
            
            step_str += "\n" # 공백 라인 추가
            trace_output.append(step_str)
            cycle_count += 1
            
    return "".join(trace_output)

# 결과 확인 (앞부분)
print(get_2x2_input_trace_stride2()[:])

def get_2x2_bram_addr_stride2():
    # 설정: 이미지 너비 28, BRAM 폭 4 bytes (1 Address = 4 Pixels)
    IMAGE_WIDTH = 28
    BRAM_WIDTH = 4
    ADDRS_PER_ROW = IMAGE_WIDTH // BRAM_WIDTH # 7 addresses per row
    
    trace_output = []
    cycle_count = 0
    
    # d: 0~11, c: 0~11 (총 144 Cycles)
    for d in range(12):
        for c in range(12):
            
            base_row = d * 2
            base_col = c * 2
            
            step_str = f"Cycle {cycle_count} (Tile d={d}, c={c})\n"
            step_str += "-" * 100 + "\n"
            
            pe_configs = [
                ("col0", 0, 0),
                ("col1", 0, 1),
                ("col2", 1, 0),
                ("col3", 1, 1)
            ]
            
            # 테이블 헤더 추가
            step_str += "PE\tRow0 Addr\tRow1 Addr\tRow2 Addr\tRow3 Addr\tRow4 Addr\n"
            
            for pe_name, r_off, c_off in pe_configs:
                row_addrs = []
                for b in range(5):
                    # 현재 Row와 Col 범위 계산
                    current_row = base_row + b + r_off
                    start_col = base_col + c_off
                    
                    # Row 시작 주소 (offset)
                    row_base_addr = current_row * ADDRS_PER_ROW
                    
                    # 5픽셀(start ~ start+4)이 걸쳐있는 로컬 주소(0~6) 계산
                    local_start = start_col // BRAM_WIDTH
                    local_end = (start_col + 4) // BRAM_WIDTH
                    
                    real_start = row_base_addr + local_start
                    real_end = row_base_addr + local_end
                    
                    if real_start == real_end:
                        row_addrs.append(f"{real_start}")
                    else:
                        row_addrs.append(f"{real_start} {real_end}")
                
                # 출력 포맷팅
                addr_line = "\t".join(row_addrs)
                step_str += f"{pe_name} :\t{addr_line}\n"
            
            step_str += "=" * 100 + "\n"
            trace_output.append(step_str)
            cycle_count += 1
            
    return "".join(trace_output)

# 결과 확인 (원하는 만큼 조정 [:] 하면 전체 출력)
print(get_2x2_bram_addr_stride2()[0:100])

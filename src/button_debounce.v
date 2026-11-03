`timescale 1ns / 1ps

// 버튼 입력의 채터링을 제거하여 안정적인 신호 출력
// DEBOUNCE_LIMIT: 입력 상태 유지 시간 설정 (100 MHz, 999,999 기준 약 10 ms)
module debouncer #(parameter DEBOUNCE_LIMIT = 20'd999_999) (
    input      clk,
    input      reset,
    input      noisy_btn,  // 노이즈가 포함된 원본 버튼 입력
    output reg clean_btn
);
    reg [19:0] r_count;
    reg r_btn_state=0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin   // 하이 활성 리셋
            r_count <= 0;
            r_btn_state <= 0;
            clean_btn <= 0;
        end else if (noisy_btn == r_btn_state) begin  // 기존 상태와 같으면 카운터 초기화
            r_count <= 0;
        end else begin
            if (r_count < DEBOUNCE_LIMIT)  // 변경된 상태의 유지 시간 측정
                r_count <= r_count + 1;
            else begin  // 설정 시간 동안 유지된 버튼 상태 반영
                r_btn_state <= noisy_btn;
                clean_btn <= noisy_btn;
                r_count <= 0;  // 다음 상태 변경을 위한 카운터 초기화
            end
        end
    end
endmodule

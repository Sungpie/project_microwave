`timescale 1ns / 1ps

module servo_controller #(
    parameter integer CLOCK_HZ = 100_000_000,
    parameter integer FRAME_US = 20_000,
    parameter integer CLOSED_US = 1_000,
    parameter integer OPEN_US = 2_000
)(
    input clk,
    input reset,
    input clean_door,
    output door,
    output door_inhibit
    );

    // 100 MHz에서 오버플로를 방지하기 위해 중간 연산에 64비트를 사용한다.
    localparam integer FRAME_CYCLES = (64'd1 * CLOCK_HZ * FRAME_US) / 1_000_000;
    localparam integer CLOSED_CYCLES = (64'd1 * CLOCK_HZ * CLOSED_US) / 1_000_000;
    localparam integer OPEN_CYCLES = (64'd1 * CLOCK_HZ * OPEN_US) / 1_000_000;
    localparam integer COUNTER_WIDTH = (FRAME_CYCLES <= 1) ? 1 : $clog2(FRAME_CYCLES);

    reg [COUNTER_WIDTH-1:0] frame_count;
    reg [COUNTER_WIDTH-1:0] pulse_width;
    reg prev_door;
    reg door_open;

    // 위치 레지스터가 바뀌기 전 버튼 에지에서도 동작을 억제한다.
    assign door_inhibit = door_open || (clean_door && !prev_door);

    // 디바운스된 버튼을 한 번 누를 때마다 목표 위치를 한 번만 변경한다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_door <= 0;
            door_open <= 0;
        end else begin
            prev_door <= clean_door;
            if (clean_door && !prev_door)
                door_open <= ~door_open;
        end
    end

    // 불완전한 PWM 펄스를 방지하도록 프레임 경계에서 펄스 폭을 갱신한다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            frame_count <= 0;
            pulse_width <= CLOSED_CYCLES;
        end else if (frame_count == FRAME_CYCLES - 1) begin
            frame_count <= 0;
            pulse_width <= door_open ? OPEN_CYCLES : CLOSED_CYCLES;
        end else begin
            frame_count <= frame_count + 1'b1;
        end
    end

    assign door = !reset && (frame_count < pulse_width);
endmodule

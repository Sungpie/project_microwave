`timescale 1ns / 1ps


module tb_top_microwave;
    reg clk = 0;
    reg reset = 1;
    reg noisy_start = 0;
    reg noisy_add30 = 0;
    reg noisy_stop = 0;
    reg noisy_door = 0;
    wire [3:0] position;
    wire [7:0] seg;
    wire buzzer, door;
    reg [13:0] paused_seconds;

    // Basys 3와 동일한 100 MHz 클럭.
    always #5 clk = ~clk;

    top_microwave dut (
        .clk(clk), .reset(reset),
        .noisy_start(noisy_start), .noisy_add30(noisy_add30),
        .noisy_stop(noisy_stop), .noisy_door(noisy_door),
        .position(position), .seg(seg), .buzzer(buzzer), .door(door)
    );

    // 시뮬레이션 전용: 디바운스, 타이머, 알림 및 서보 주기를 단축한다.
    // 이 값은 합성된 하드웨어에 영향을 주지 않는다.
    defparam dut.u_debouncer_start.DEBOUNCE_LIMIT = 3;
    defparam dut.u_debouncer_add30.DEBOUNCE_LIMIT = 3;
    defparam dut.u_debouncer_stop.DEBOUNCE_LIMIT = 3;
    defparam dut.u_debouncer_door.DEBOUNCE_LIMIT = 3;
    defparam dut.u_main_controller.CLOCK_HZ = 100;
    defparam dut.u_play_melody.CLOCK_HZ = 1000;
    defparam dut.u_play_melody.BEEP_HZ = 100;
    defparam dut.u_servo_controller.FRAME_US = 200;
    defparam dut.u_servo_controller.CLOSED_US = 10;
    defparam dut.u_servo_controller.OPEN_US = 20;

    // 디바운서를 통과하도록 각 버튼을 충분히 오래 누르고 놓는다.
    task press_button(input integer button);
        begin
            @(negedge clk);
            case (button)
                0: noisy_start = 1;
                1: noisy_add30 = 1;
                2: noisy_stop = 1;
                3: noisy_door = 1;
            endcase
            repeat (10) @(negedge clk);
            noisy_start = 0;
            noisy_add30 = 0;
            noisy_stop = 0;
            noisy_door = 0;
            repeat (10) @(negedge clk);
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        reset = 0;

        press_button(1); // 30초 추가
        if (dut.seg_data !== 30) $fatal(1, "ADD failed");
        press_button(0); // 시작
        repeat (250) @(negedge clk);
        if (dut.seg_data >= 30) $fatal(1, "Countdown failed");
        press_button(2); // 정지
        paused_seconds = dut.seg_data;
        repeat (200) @(negedge clk);
        if (dut.seg_data !== paused_seconds) $fatal(1, "STOP failed");

        press_button(3); // 문 열림
        repeat (20010) @(negedge clk);
        if (!dut.u_servo_controller.door_open ||
            dut.u_servo_controller.pulse_width != 2000)
            $fatal(1, "Door open failed");
        press_button(3); // 문 닫힘
        repeat (20010) @(negedge clk);
        if (dut.u_servo_controller.door_open ||
            dut.u_servo_controller.pulse_width != 1000)
            $fatal(1, "Door close failed");

        press_button(0); // 시간이 끝날 때까지 재개
        wait (dut.timeout);
        repeat (2) @(negedge clk);
        if (dut.seg_data !== 0 || !dut.u_play_melody.alert_active)
            $fatal(1, "Timeout alert failed");
        repeat (500) @(negedge clk);
        if (!dut.display_blank || position !== 4'b1111)
            $fatal(1, "FND blink failed");

        $display("PASS: buttons, timer, door and timeout alert");
        $finish;
    end

    initial begin
        #1_000_000;
        $fatal(1, "Simulation timed out");
    end
endmodule

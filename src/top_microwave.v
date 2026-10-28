`timescale 1ns / 1ps

module top_microwave(
    input clk,
    input noisy_start,
    input noisy_add30,
    input noisy_stop,
    input reset,
    input noisy_door,
    output [3:0] position,
    output [7:0] seg,
    output buzzer,
    output door
    );

    wire clean_start;
    wire clean_add30;
    wire clean_stop;
    wire [13:0] seg_data;
    wire timeout;
    wire display_blank;
    wire clean_door;

    debouncer u_debouncer_start (
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_start),  // raw noisy button input
        .clean_btn(clean_start)
    );

    debouncer u_debouncer_add30 (
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_add30),
        .clean_btn(clean_add30)
    );

    debouncer u_debouncer_stop (
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_stop),
        .clean_btn(clean_stop)
    );

    main_controller u_main_controller(
        .clk(clk),
        .btn({clean_stop, clean_add30, clean_start}),   
        .reset(reset),
        .seg_data(seg_data),
        .timeout(timeout)
    );

    fnd_controller u_fnd_controller (
        .clk(clk),
        .reset(reset),
        .seconds(seg_data),
        .blank(display_blank),
        .position(position),
        .seg(seg)
    );

    play_melody u_play_melody(
        .clk(clk),
        .reset(reset),
        .btn({clean_stop, clean_add30, clean_start}),
        .timeout(timeout),
        .buzzer(buzzer),
        .display_blank(display_blank)
    );

    debouncer u_debouncer_door (
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_door),
        .clean_btn(clean_door)
    );

    servo_controller u_servo_controller(
        .clk(clk),
        .reset(reset),
        .clean_door(clean_door),
        .door(door)
    );

endmodule

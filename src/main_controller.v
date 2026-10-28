`timescale 1ns / 1ps

module main_controller #(
    parameter integer CLOCK_HZ = 100_000_000
)(
    input clk,
    input [2:0] btn, // [0]: start, [1]: add 30 seconds, [2]: stop
    input reset,
    output [13:0] seg_data, // remaining time in seconds
    output reg timeout      // one clock pulse when cooking finishes
);
    localparam [13:0] MAX_SECONDS = 14'd5999; // 99:59
    localparam integer COUNTER_WIDTH = (CLOCK_HZ <= 1) ? 1 : $clog2(CLOCK_HZ);

    reg [2:0] prev_btn;
    reg running;
    reg [13:0] remaining_seconds;
    reg [COUNTER_WIDTH-1:0] second_counter;

    wire [2:0] press = btn & ~prev_btn;
    wire second_tick = running && (second_counter == CLOCK_HZ - 1);
    wire [14:0] added_seconds = {1'b0, remaining_seconds} + 15'd30
                                 - (second_tick ? 15'd1 : 15'd0);

    assign seg_data = remaining_seconds;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_btn <= 3'b000;
            running <= 1'b0;
            remaining_seconds <= 0;
            second_counter <= 0;
            timeout <= 0;
        end else begin
            prev_btn <= btn;
            timeout <= 0;

            if (!running || press[2] || second_tick)
                second_counter <= 0;
            else
                second_counter <= second_counter + 1'b1;

            // Stop has priority when multiple buttons are pressed together.
            if (press[2]) begin
                running <= 1'b0;
            end else begin
                if (press[1]) begin
                    if (added_seconds > MAX_SECONDS)
                        remaining_seconds <= MAX_SECONDS;
                    else
                        remaining_seconds <= added_seconds[13:0];
                end else if (second_tick) begin
                    remaining_seconds <= remaining_seconds - 1'b1;
                end

                if (second_tick && remaining_seconds == 1 && !press[1]) begin
                    running <= 1'b0;
                    timeout <= 1'b1;
                end else if (press[0] && (remaining_seconds != 0 || press[1]))
                    running <= 1'b1;
            end
        end
    end
endmodule

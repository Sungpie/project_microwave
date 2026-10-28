`timescale 1ns / 1ps

module play_melody #(
    parameter integer CLOCK_HZ = 100_000_000,
    parameter integer BEEP_HZ = 2_000,
    parameter integer BEEP_MS = 100
)(
    input clk,
    input reset,
    input [2:0] btn,
    input timeout,
    output reg buzzer,
    output display_blank
);
    // Button beep: 2 kHz for 100 ms at the default settings.
    localparam integer BEEP_HALF = CLOCK_HZ / (2 * BEEP_HZ);
    localparam integer BEEP_CYCLES = (CLOCK_HZ / 1000) * BEEP_MS;
    // Completion melody: C5, E5, G5, each played for half a second.
    localparam integer NOTE_C = (CLOCK_HZ / (2 * 523) < 1) ? 1 : CLOCK_HZ / (2 * 523);
    localparam integer NOTE_E = (CLOCK_HZ / (2 * 659) < 1) ? 1 : CLOCK_HZ / (2 * 659);
    localparam integer NOTE_G = (CLOCK_HZ / (2 * 784) < 1) ? 1 : CLOCK_HZ / (2 * 784);
    localparam integer MAX_HALF = (BEEP_HALF > NOTE_C) ? BEEP_HALF : NOTE_C;
    localparam integer TONE_WIDTH = (MAX_HALF <= 1) ? 1 : $clog2(MAX_HALF);
    localparam integer TIME_WIDTH = (BEEP_CYCLES <= 1) ? 1 : $clog2(BEEP_CYCLES);
    localparam integer PHASE_CYCLES = (CLOCK_HZ / 2 < 1) ? 1 : CLOCK_HZ / 2;
    localparam integer PHASE_WIDTH = (PHASE_CYCLES <= 1) ? 1 : $clog2(PHASE_CYCLES);

    reg [2:0] prev_btn;
    reg sounding;
    reg [TONE_WIDTH-1:0] tone_count;
    reg [TIME_WIDTH-1:0] duration_count;
    reg alert_active;
    reg [2:0] alert_phase; // 0,2,4: lit and playing; 1,3,5: off
    reg [PHASE_WIDTH-1:0] phase_count;
    reg [TONE_WIDTH-1:0] note_half;
    wire button_pressed = |(btn & ~prev_btn);

    assign display_blank = alert_active && alert_phase[0];

    always @* begin
        case (alert_phase)
            3'd0: note_half = NOTE_C;
            3'd2: note_half = NOTE_E;
            default: note_half = NOTE_G;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_btn <= 0;
            sounding <= 0;
            tone_count <= 0;
            duration_count <= 0;
            alert_active <= 0;
            alert_phase <= 0;
            phase_count <= 0;
            buzzer <= 0;
        end else begin
            prev_btn <= btn;
            if (timeout && !button_pressed) begin
                alert_active <= 1;
                alert_phase <= 0;
                phase_count <= 0;
                sounding <= 0;
                tone_count <= 0;
                duration_count <= 0;
                buzzer <= 1;
            end else if (button_pressed) begin
                // Any new button press dismisses the alert and starts a beep.
                alert_active <= 0;
                sounding <= 1;
                tone_count <= 0;
                duration_count <= 0;
                buzzer <= 1;
            end else if (alert_active) begin
                if (phase_count == PHASE_CYCLES - 1) begin
                    phase_count <= 0;
                    tone_count <= 0;
                    if (alert_phase == 5) begin
                        alert_active <= 0;
                        buzzer <= 0;
                    end else begin
                        alert_phase <= alert_phase + 1'b1;
                        buzzer <= alert_phase[0]; // next phase is ON after an OFF
                    end
                end else begin
                    phase_count <= phase_count + 1'b1;
                    if (alert_phase[0]) begin
                        buzzer <= 0;
                    end else if (tone_count == note_half - 1'b1) begin
                        tone_count <= 0;
                        buzzer <= ~buzzer;
                    end else begin
                        tone_count <= tone_count + 1'b1;
                    end
                end
            end else if (sounding) begin
                if (duration_count == BEEP_CYCLES - 1) begin
                    sounding <= 0;
                    duration_count <= 0;
                    tone_count <= 0;
                    buzzer <= 0;
                end else begin
                    duration_count <= duration_count + 1'b1;
                    if (tone_count == BEEP_HALF - 1) begin
                        tone_count <= 0;
                        buzzer <= ~buzzer;
                    end else begin
                        tone_count <= tone_count + 1'b1;
                    end
                end
            end else begin
                buzzer <= 0;
            end
        end
    end
endmodule

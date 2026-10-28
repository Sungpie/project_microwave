`timescale 1ns / 1ps

// Basys 3: anodes and segment outputs are active low.
module fnd_controller(
    input clk,
    input reset,
    input [13:0] seconds,
    input blank,
    output reg [3:0] position,
    output reg [7:0] seg
);
    reg [16:0] scan_counter;
    reg [3:0] digit;
    wire [13:0] minutes = seconds / 60;
    wire [13:0] seconds_in_minute = seconds % 60;

    always @(posedge clk or posedge reset) begin
        if (reset)
            scan_counter <= 0;
        else
            scan_counter <= scan_counter + 1'b1;
    end

    always @* begin
        case (scan_counter[16:15])
            2'd0: begin position = 4'b1110; digit = seconds_in_minute % 10; end
            2'd1: begin position = 4'b1101; digit = seconds_in_minute / 10; end
            2'd2: begin position = 4'b1011; digit = minutes % 10; end
            2'd3: begin position = 4'b0111; digit = minutes / 10; end
            default: begin position = 4'b1111; digit = 0; end
        endcase

        // seg[6:0] = {g,f,e,d,c,b,a}; seg[7] is the decimal point.
        case (digit)
            4'd0: seg = 8'b11000000;
            4'd1: seg = 8'b11111001;
            4'd2: seg = 8'b10100100;
            4'd3: seg = 8'b10110000;
            4'd4: seg = 8'b10011001;
            4'd5: seg = 8'b10010010;
            4'd6: seg = 8'b10000010;
            4'd7: seg = 8'b11111000;
            4'd8: seg = 8'b10000000;
            4'd9: seg = 8'b10010000;
            default: seg = 8'b11111111;
        endcase
        if (blank) begin
            position = 4'b1111;
            seg = 8'b11111111;
        end
    end
endmodule

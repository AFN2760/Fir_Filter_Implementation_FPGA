`timescale 1ns / 1ps
module uart_rx (
    input  wire       clk,
    input  wire       reset,    // active high
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid
);
    parameter CLK_PER_BIT = 868; // 100MHz / 115200 baud

    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [9:0] clk_cnt;
    reg [2:0] bit_idx;
    reg [1:0] state;
    reg [7:0] rx_data;

    always @(posedge clk) begin
        valid <= 1'b0;
        if (reset) begin
            state   <= IDLE;
            clk_cnt <= 0;
            bit_idx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (rx == 1'b0) begin       // falling edge = start bit
                        clk_cnt <= 1;
                        state   <= START;
                    end
                end
                START: begin
                    if (clk_cnt == CLK_PER_BIT/2) begin
                        if (rx == 1'b0) begin   // confirm start bit at midpoint
                            clk_cnt <= 1;
                            bit_idx <= 0;
                            state   <= DATA;
                        end else
                            state <= IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    if (clk_cnt == CLK_PER_BIT) begin
                        rx_data[bit_idx] <= rx;
                        clk_cnt <= 1;
                        if (bit_idx == 3'd7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    if (clk_cnt == CLK_PER_BIT) begin
                        valid   <= 1'b1;
                        data    <= rx_data;
                        state   <= IDLE;
                        clk_cnt <= 0;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule
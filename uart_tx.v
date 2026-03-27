`timescale 1ns / 1ps
module uart_tx (
    input  wire       clk,
    input  wire       reset,    // active high
    input  wire [7:0] data,
    input  wire       start,
    output reg        tx,
    output reg        busy
);
    parameter CLK_PER_BIT = 868;

    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [9:0] clk_cnt;
    reg [2:0] bit_idx;
    reg [1:0] state;
    reg [7:0] tx_data;

    always @(posedge clk) begin
        if (reset) begin
            state   <= IDLE;
            tx      <= 1'b1;
            busy    <= 1'b0;
            clk_cnt <= 0;
            bit_idx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (start) begin
                        tx_data <= data;
                        busy    <= 1'b1;
                        clk_cnt <= 1;
                        state   <= START;
                    end
                end
                START: begin
                    tx <= 1'b0;     // start bit
                    if (clk_cnt == CLK_PER_BIT) begin
                        clk_cnt <= 1;
                        bit_idx <= 0;
                        state   <= DATA;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    tx <= tx_data[bit_idx];
                    if (clk_cnt == CLK_PER_BIT) begin
                        clk_cnt <= 1;
                        if (bit_idx == 3'd7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    tx <= 1'b1;     // stop bit
                    if (clk_cnt == CLK_PER_BIT) begin
                        state   <= IDLE;
                        busy    <= 1'b0;
                        clk_cnt <= 0;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule
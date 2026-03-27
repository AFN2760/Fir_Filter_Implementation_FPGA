`timescale 1ns / 1ps
module top (
    input  wire clk,
    input  wire reset_btn,
    input  wire uart_rx_pin,
    output wire uart_tx_pin
);
    wire fir_reset_n = ~reset_btn;

    // ----------------------------------------------------------------
    // UART RX
    // ----------------------------------------------------------------
    wire [7:0] rx_byte;
    wire       rx_valid;

    uart_rx #(.CLK_PER_BIT(868)) u_rx (
        .clk   (clk),
        .reset (reset_btn),
        .rx    (uart_rx_pin),
        .data  (rx_byte),
        .valid (rx_valid)
    );

    // ----------------------------------------------------------------
    // UART TX
    // ----------------------------------------------------------------
    reg  [7:0] tx_byte;
    reg        tx_start;
    wire       tx_busy;

    uart_tx #(.CLK_PER_BIT(868)) u_tx (
        .clk   (clk),
        .reset (reset_btn),
        .data  (tx_byte),
        .start (tx_start),
        .tx    (uart_tx_pin),
        .busy  (tx_busy)
    );

    // ----------------------------------------------------------------
    // FIR Filter
    // ----------------------------------------------------------------
    reg  signed [15:0] fir_in_data;
    reg                fir_in_valid;
    wire signed [31:0] fir_out_data;
    wire               fir_out_valid;
    wire               fir_in_ready;

    FIR fir_inst (
        .clk               (clk),
        .reset             (fir_reset_n),
        .s_axis_fir_tdata  (fir_in_data),
        .s_axis_fir_tvalid (fir_in_valid),
        .s_axis_fir_tlast  (1'b0),
        .s_axis_fir_tready (fir_in_ready),
        .m_axis_fir_tdata  (fir_out_data),
        .m_axis_fir_tvalid (fir_out_valid),
        .m_axis_fir_tlast  (),
        .m_axis_fir_tkeep  (),
        .m_axis_fir_tready (1'b1)
    );

    // ----------------------------------------------------------------
    // State machine
    // Each byte transmission has two states:
    //   SEND: pulse tx_start, move to WAIT
    //   WAIT: wait for tx_busy to go HIGH then LOW, move to next
    // This properly handles the 1-clock delay before tx_busy asserts.
    // ----------------------------------------------------------------
    localparam S_RECV_B0  = 4'd0,
               S_RECV_B1  = 4'd1,
               S_FILTER   = 4'd2,
               S_SEND_B0  = 4'd3,
               S_WAIT_B0  = 4'd4,
               S_SEND_B1  = 4'd5,
               S_WAIT_B1  = 4'd6,
               S_SEND_B2  = 4'd7,
               S_WAIT_B2  = 4'd8,
               S_SEND_B3  = 4'd9,
               S_WAIT_B3  = 4'd10;

    reg [3:0]          state;
    reg [7:0]          byte_lo;
    reg signed [31:0]  result;
    reg                fir_sent;
    reg                tx_was_busy;    // tracks that busy went high before we check low

    always @(posedge clk) begin
        tx_start     <= 1'b0;
        fir_in_valid <= 1'b0;

        if (reset_btn) begin
            state        <= S_RECV_B0;
            fir_sent     <= 1'b0;
            tx_was_busy  <= 1'b0;
            fir_in_data  <= 16'sd0;
        end else begin
            case (state)

                // ---- Receive low byte (LSB) of 16-bit sample ----
                S_RECV_B0: begin
                    if (rx_valid) begin
                        byte_lo <= rx_byte;
                        state   <= S_RECV_B1;
                    end
                end

                // ---- Receive high byte (MSB), assemble sample ----
                S_RECV_B1: begin
                    if (rx_valid) begin
                        fir_in_data <= $signed({rx_byte, byte_lo});
                        fir_sent    <= 1'b0;
                        state       <= S_FILTER;
                    end
                end

                // ---- Pulse FIR valid, wait for output ----
                S_FILTER: begin
                    if (!fir_sent) begin
                        fir_in_valid <= 1'b1;
                        fir_sent     <= 1'b1;
                    end
                    if (fir_out_valid) begin
                        result <= fir_out_data;
                        state  <= S_SEND_B0;
                    end
                end

                // ---- Send byte 0 (bits 7:0) ----
                S_SEND_B0: begin
                    tx_byte     <= result[7:0];
                    tx_start    <= 1'b1;
                    tx_was_busy <= 1'b0;
                    state       <= S_WAIT_B0;
                end
                S_WAIT_B0: begin
                    if (tx_busy)             tx_was_busy <= 1'b1;
                    if (tx_was_busy && !tx_busy) state   <= S_SEND_B1;
                end

                // ---- Send byte 1 (bits 15:8) ----
                S_SEND_B1: begin
                    tx_byte     <= result[15:8];
                    tx_start    <= 1'b1;
                    tx_was_busy <= 1'b0;
                    state       <= S_WAIT_B1;
                end
                S_WAIT_B1: begin
                    if (tx_busy)             tx_was_busy <= 1'b1;
                    if (tx_was_busy && !tx_busy) state   <= S_SEND_B2;
                end

                // ---- Send byte 2 (bits 23:16) ----
                S_SEND_B2: begin
                    tx_byte     <= result[23:16];
                    tx_start    <= 1'b1;
                    tx_was_busy <= 1'b0;
                    state       <= S_WAIT_B2;
                end
                S_WAIT_B2: begin
                    if (tx_busy)             tx_was_busy <= 1'b1;
                    if (tx_was_busy && !tx_busy) state   <= S_SEND_B3;
                end

                // ---- Send byte 3 (bits 31:24) ----
                S_SEND_B3: begin
                    tx_byte     <= result[31:24];
                    tx_start    <= 1'b1;
                    tx_was_busy <= 1'b0;
                    state       <= S_WAIT_B3;
                end
                S_WAIT_B3: begin
                    if (tx_busy)             tx_was_busy <= 1'b1;
                    if (tx_was_busy && !tx_busy) state   <= S_RECV_B0;
                end

                default: state <= S_RECV_B0;
            endcase
        end
    end

endmodule
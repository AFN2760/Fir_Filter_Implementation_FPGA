`timescale 1ns / 1ps
module FIR #(
    // ============================================================
    // STEP 1: Change NUM_TAPS to your desired number of taps
    //         (must be odd for a symmetric linear-phase FIR)
    //         e.g. 15, 17, 31, 63 ...
    // ============================================================
    parameter NUM_TAPS = 16
)(
    input  wire clk,
    input  wire reset,
    /* AXI-Stream input */
    input  wire signed [15:0] s_axis_fir_tdata,
    input  wire s_axis_fir_tvalid,
    input  wire s_axis_fir_tlast,
    output wire s_axis_fir_tready,
    /* AXI-Stream output */
    output reg  signed [31:0] m_axis_fir_tdata,
    output reg  m_axis_fir_tvalid,
    output reg  m_axis_fir_tlast,
    output reg  [3:0] m_axis_fir_tkeep,
    input  wire m_axis_fir_tready
);
    /* ---------------------------------------------------------
       AXI input is always ready
    --------------------------------------------------------- */
    assign s_axis_fir_tready = 1'b1;
    wire in_xfer  = s_axis_fir_tvalid && s_axis_fir_tready;
    wire out_xfer = m_axis_fir_tvalid && m_axis_fir_tready;

    /* ---------------------------------------------------------
       Shift register - size driven by NUM_TAPS automatically
    --------------------------------------------------------- */
    reg signed [15:0] x[0:NUM_TAPS-1];
    integer i;

    always @(posedge clk) begin
        if (!reset) begin
            for (i = 0; i < NUM_TAPS; i = i + 1)
                x[i] <= 16'sd0;
        end
        else if (in_xfer) begin
            x[0] <= s_axis_fir_tdata;
            for (i = 1; i < NUM_TAPS; i = i + 1)
                x[i] <= x[i-1];
        end
    end

    /* ---------------------------------------------------------
       FIR coefficients
       STEP 2: Replace ONLY the values inside the initial block
               with the new coefficients from the Python script.
               Do NOT change anything else.
    --------------------------------------------------------- */
    reg signed [15:0] h[0:NUM_TAPS-1];

    initial begin
        // --------------------------------------------------------
        // Paste your Python-generated coefficients here.
        // Current coefficients are for a 16-tap bandpass filter.
        // --------------------------------------------------------
        h[0]  = 16'hFF0B; // -245
        h[1]  = 16'hFDF0; // -528
        h[2]  = 16'hFDBB; // -581
        h[3]  = 16'h0000; //  0
        h[4]  = 16'h05A3; //  1443
        h[5]  = 16'h0DE3; //  3555
        h[6]  = 16'h163E; //  5694
        h[7]  = 16'h1B87; //  7047
        h[8]  = 16'h1B87; //  7047
        h[9]  = 16'h163E; //  5694
        h[10] = 16'h0DE3; //  3555
        h[11] = 16'h05A3; //  1443
        h[12] = 16'h0000; //  0
        h[13] = 16'hFDBB; // -581
        h[14] = 16'hFDF0; // -528
        h[15] = 16'hFF0B; // -245
        // --------------------------------------------------------
    end

    /* ---------------------------------------------------------
       Multiply-Accumulate - loop bound driven by NUM_TAPS
    --------------------------------------------------------- */
    reg signed [35:0] acc;
    integer j;

    always @(*) begin
        acc = 36'sd0;
        for (j = 0; j < NUM_TAPS; j = j + 1)
            acc = acc + x[j] * h[j];
    end

    /* ---------------------------------------------------------
       Output register & AXI control
    --------------------------------------------------------- */
    always @(posedge clk) begin
        if (!reset) begin
            m_axis_fir_tvalid <= 1'b0;
            m_axis_fir_tdata  <= 32'sd0;
            m_axis_fir_tlast  <= 1'b0;
            m_axis_fir_tkeep  <= 4'hF;
        end
        else begin
            if (in_xfer && (!m_axis_fir_tvalid || m_axis_fir_tready)) begin
                m_axis_fir_tdata  <= acc >>> 15;
                m_axis_fir_tvalid <= 1'b1;
                m_axis_fir_tlast  <= s_axis_fir_tlast;
                m_axis_fir_tkeep  <= 4'hF;
            end
            else if (out_xfer) begin
                m_axis_fir_tvalid <= 1'b0;
            end
        end
    end

endmodule
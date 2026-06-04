`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2026 13:31:09
// Design Name: 
// Module Name: viterbi_k7_axis
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module viterbi_k7_axis #
(
    parameter SEQ_LEN   = 256,
    parameter METRIC_W  = 8
)
(
    input  wire clk,
    input  wire rst_n,

    // ================= AXI INPUT (SLAVE) =================
    input  wire [31:0] S_AXIS_TDATA,
    input  wire       S_AXIS_TVALID,
    output reg        S_AXIS_TREADY,
    input  wire       S_AXIS_TLAST,

    // ================= AXI OUTPUT (MASTER) =================
    output reg  [7:0] M_AXIS_TDATA,
    output reg        M_AXIS_TVALID,
    input  wire       M_AXIS_TREADY,
    output reg        M_AXIS_TLAST
);

    localparam N_STATES = 64;

    // =========================
    // PATH METRICS
    // =========================
    reg [METRIC_W-1:0] path_metric [0:N_STATES-1];
    reg [METRIC_W-1:0] path_metric_nxt [0:N_STATES-1];

    // =========================
    // BACKPOINTER MEMORY
    // =========================
    reg [5:0] backptr [0:SEQ_LEN-1][0:N_STATES-1];

    // =========================
    // CONTROL
    // =========================
    reg [15:0] symbol_cnt;
    reg [15:0] tb_index;

    reg decoding;
    reg traceback;

    reg [5:0] current_state;

    integer i;

    // =========================
    // ENCODER MODEL (171,133)
    // =========================
    function [1:0] enc;
        input bit_in;
        input [5:0] state;
        reg [6:0] shift;
        begin
            shift = {bit_in, state};
            enc[1] = shift[6]^shift[5]^shift[4]^shift[3]^shift[0];
            enc[0] = shift[6]^shift[4]^shift[3]^shift[1]^shift[0];
        end
    endfunction

    reg [1:0] exp;
    reg [METRIC_W-1:0] br_metric;
    reg [5:0] next_state;

    // =========================
    // AXI HANDSHAKE
    // =========================
    wire rx_fire = S_AXIS_TVALID & S_AXIS_TREADY;
    wire tx_fire = M_AXIS_TVALID & M_AXIS_TREADY;

    wire rx_bit0 = S_AXIS_TDATA[0];
    wire rx_bit1 = S_AXIS_TDATA[1];

    // =========================
    // MAIN LOGIC
    // =========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin

            decoding <= 0;
            traceback <= 0;

            S_AXIS_TREADY <= 1;

            M_AXIS_TVALID <= 0;
            M_AXIS_TLAST  <= 0;

            symbol_cnt <= 0;
            tb_index   <= 0;

            current_state <= 0;

            for (i=0;i<N_STATES;i=i+1)
                path_metric[i] <= {METRIC_W{1'b1}};

            path_metric[0] <= 0;

        end else begin

            // Default
            M_AXIS_TVALID <= 0;
            M_AXIS_TLAST  <= 0;

            // ================= INPUT / DECODING =================
            if (rx_fire) begin

                if (!decoding && !traceback) begin
                    decoding   <= 1;
                    symbol_cnt <= 0;

                    for (i=0;i<N_STATES;i=i+1)
                        path_metric[i] <= {METRIC_W{1'b1}};

                    path_metric[0] <= 0;
                end

                if (decoding) begin

                    for (i=0;i<N_STATES;i=i+1)
                        path_metric_nxt[i] = {METRIC_W{1'b1}};

                    for (i=0;i<N_STATES;i=i+1) begin

                        // input 0
                        exp = enc(0, i);
                        br_metric = (exp[1]^rx_bit1) + (exp[0]^rx_bit0);
                        next_state = {1'b0, i[5:1]};

                        if (path_metric[i] + br_metric < path_metric_nxt[next_state]) begin
                            path_metric_nxt[next_state] = path_metric[i] + br_metric;
                            backptr[symbol_cnt][next_state] <= i;
                        end

                        // input 1
                        exp = enc(1, i);
                        br_metric = (exp[1]^rx_bit1) + (exp[0]^rx_bit0);
                        next_state = {1'b1, i[5:1]};

                        if (path_metric[i] + br_metric < path_metric_nxt[next_state]) begin
                            path_metric_nxt[next_state] = path_metric[i] + br_metric;
                            backptr[symbol_cnt][next_state] <= i;
                        end
                    end

                    for (i=0;i<N_STATES;i=i+1)
                        path_metric[i] <= path_metric_nxt[i];

                    symbol_cnt <= symbol_cnt + 1;

                    // End of frame
                    if (S_AXIS_TLAST || symbol_cnt == SEQ_LEN-1) begin
                        decoding  <= 0;
                        traceback <= 1;
                        tb_index  <= symbol_cnt;

                        current_state <= 0;
                        for (i=1;i<N_STATES;i=i+1)
                            if (path_metric[i] < path_metric[current_state])
                                current_state <= i;
                    end
                end
            end

            // ================= TRACEBACK =================
            else if (traceback) begin

                if (M_AXIS_TREADY || !M_AXIS_TVALID) begin
                    M_AXIS_TVALID <= 1;
                    M_AXIS_TDATA  <= current_state[5];

                    current_state <= backptr[tb_index][current_state];

                    if (tb_index == 0) begin
                        traceback <= 0;
                        M_AXIS_TLAST <= 1;
                    end else begin
                        tb_index <= tb_index - 1;
                    end
                end
            end
        end
    end

endmodule
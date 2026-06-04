module viterbi_k7 #
(
    parameter SEQ_LEN = 256,
    parameter TB_LEN  = 40,
    parameter METRIC_W = 8
)
(
    input clk,
    input rst_n,
    input start,

    input rx_valid,
    input rx_bit0,
    input rx_bit1,

    output reg ready,
    output reg out_valid,
    output reg out_bit
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
            enc[1] = shift[6]^shift[5]^shift[4]^shift[3]^shift[0]; //171
            enc[0] = shift[6]^shift[4]^shift[3]^shift[1]^shift[0]; //133
        end
    endfunction

    reg [1:0] exp;
    reg [METRIC_W-1:0] br_metric;
    reg [5:0] next_state;

    // =========================
    // MAIN LOGIC
    // =========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1;
            decoding <= 0;
            traceback <= 0;
            out_valid <= 0;
            symbol_cnt <= 0;
            tb_index <= 0;
            current_state <= 0;

            for (i=0;i<N_STATES;i=i+1)
                path_metric[i] <= 8'h7F;

            path_metric[0] <= 0;
        end
        else begin

            out_valid <= 0;

            // ================= START =================
            if (start && ready) begin
                ready <= 0;
                decoding <= 1;
                symbol_cnt <= 0;

                for (i=0;i<N_STATES;i=i+1)
                    path_metric[i] <= 8'h7F;

                path_metric[0] <= 0;
            end

            // ================= ACS =================
            else if (decoding && rx_valid) begin

                for (i=0;i<N_STATES;i=i+1)
                    path_metric_nxt[i] = 8'h7F;

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

                // START TRACEBACK
                if (symbol_cnt == SEQ_LEN-1) begin
                    decoding <= 0;
                    traceback <= 1;
                    tb_index <= SEQ_LEN-1;

                    // find best state
                    current_state <= 0;
                    for (i=1;i<N_STATES;i=i+1)
                        if (path_metric[i] < path_metric[current_state])
                            current_state <= i;

                    $display("TRACEBACK STARTED at %0t", $time);
                end
            end

            // ================= TRACEBACK =================
            else if (traceback) begin

                out_bit <= current_state[5]; // MSB = decoded bit
                out_valid <= 1;

                current_state <= backptr[tb_index][current_state];

                if (tb_index == 0) begin
                    traceback <= 0;
                    ready <= 1;
                end else begin
                    tb_index <= tb_index - 1;
                end
            end
        end
    end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2026 13:31:34
// Design Name: 
// Module Name: tb_viterbi_axis
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

module tb_viterbi_axis;

reg clk=0;
always #5 clk = ~clk;

reg rst_n;

reg [7:0] s_tdata;
reg s_tvalid;
wire s_tready;
reg s_tlast;

wire [7:0] m_tdata;
wire m_tvalid;
reg m_tready;
wire m_tlast;

viterbi_k7_axis dut (
    .clk(clk),
    .rst_n(rst_n),

    .S_AXIS_TDATA(s_tdata),
    .S_AXIS_TVALID(s_tvalid),
    .S_AXIS_TREADY(s_tready),
    .S_AXIS_TLAST(s_tlast),

    .M_AXIS_TDATA(m_tdata),
    .M_AXIS_TVALID(m_tvalid),
    .M_AXIS_TREADY(m_tready),
    .M_AXIS_TLAST(m_tlast)
);

integer i;

initial begin
    rst_n = 0;
    s_tvalid = 0;
    m_tready = 1;
    #20 rst_n = 1;

    // Send frame
    for (i=0;i<256;i=i+1) begin
        @(posedge clk);
        s_tdata  <= $random;
        s_tvalid <= 1;
        s_tlast  <= (i==255);
    end

    @(posedge clk);
    s_tvalid <= 0;

    #10000;
    $finish;
end

endmodule
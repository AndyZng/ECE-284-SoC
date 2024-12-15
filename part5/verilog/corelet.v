module corelet(
    clk,
    reset,
    inst,
    l0_in,
    ofifo_out,
    ofifo_o_valid
);

parameter row = 8;
parameter col = 8;
parameter bw = 4;
parameter psum_bw = 16;

input clk, reset;
input [34:0] inst;
input signed [row*bw-1:0] l0_in;
output signed [col*psum_bw-1:0] ofifo_out;
output ofifo_o_valid;

wire mode = inst[34]; // 0=WS, 1=OS
wire l0_rd = inst[3];
wire l0_wr = inst[2];
wire ofifo_rd = inst[6];
wire execute = inst[1];
wire load = inst[0];

// L0
wire signed [row*bw-1:0] l0_out;
wire l0_o_full;
wire l0_o_ready;

l0 #(.row(row), .bw(bw)) l0_inst(
    .clk(clk),
    .in(l0_in),
    .out(l0_out),
    .rd(l0_rd),
    .wr(l0_wr),
    .o_full(l0_o_full),
    .reset(reset),
    .o_ready(l0_o_ready)
);

wire ififo_wr = (mode == 1) ? inst[5] : 1'b0;
wire ififo_rd = (mode == 1) ? inst[4] : 1'b0;
wire signed [row*bw-1:0] ififo_out;
wire ififo_o_full, ififo_o_ready;

ififo #(.row(row), .bw(bw)) ififo_inst(
    .clk(clk),
    .reset(reset),
    .wr(ififo_wr),
    .rd(ififo_rd),
    .in(l0_in),
    .out(ififo_out),
    .o_full(ififo_o_full),
    .o_ready(ififo_o_ready)
);

wire [1:0] mac_inst_w = inst[1:0];
wire signed [psum_bw*col-1:0] mac_in_n = {psum_bw*col{1'b0}};

wire signed [row*bw-1:0] selected_weights = (mode == 0) ? l0_out : ififo_out;
wire signed [psum_bw*col-1:0] mac_out_s;
wire [col-1:0] mac_valid;

mac_array #(
    .bw(bw),
    .psum_bw(psum_bw),
    .col(col),
    .row(row)
) mac_array_instance (
    .clk(clk),
    .reset(reset),
    .out_s(mac_out_s),
    .in_w(selected_weights),
    .in_n(mac_in_n),
    .inst_w(mac_inst_w),
    .valid(mac_valid)
);

// OFIFO
ofifo #(.col(col), .bw(psum_bw)) ofifo_inst(
    .clk(clk),
    .in(mac_out_s),
    .out(ofifo_out),
    .rd(ofifo_rd),
    .wr(mac_valid),
    .o_full(),
    .reset(reset),
    .o_ready(),
    .o_valid(ofifo_o_valid)
);

endmodule

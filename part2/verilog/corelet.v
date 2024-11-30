module corelet(clk, reset, inst, l0_in, sfp_out);

	parameter row = 8;
	parameter col = 8;
	parameter bw = 4;
	parameter psum_bw = 16;

	input clk, reset;
	input [33:0] inst;
	input [row*bw-1:0] l0_in;
	output [col*psum_bw-1:0] sfp_out;

	// L0
	wire l0_rd, l0_wr;
	wire [row*bw-1:0] l0_out;
	wire l0_o_full;
	wire l0_o_ready;

	assign l0_rd = inst[3];
	assign l0_wr = inst[2];

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

	// MAC array
	wire [1:0] mac_inst_w;
	wire [psum_bw*col-1:0] mac_in_n;
	wire [psum_bw*col-1:0] mac_out_s;
	wire [col-1:0] mac_valid;

	assign mac_inst_w = inst[1:0];
	assign mac_in_n = {psum_bw*col{1'b0}};

	mac_array #(
		.bw(bw),
		.psum_bw(psum_bw),
		.col(col),
		.row(row)
	) mac_array_instance (
		.clk(clk),
		.reset(reset),
		.out_s(mac_out_s),
		.in_w(l0_out),
		.in_n(mac_in_n),
		.inst_w(mac_inst_w),
		.valid(mac_valid)
	);

	// OFIFO
	wire ofifo_rd;
	wire [psum_bw*col-1:0]ofifo_out;
	wire ofifo_o_full;
	wire ofifo_o_ready;
	wire ofifo_o_valid;

	assign ofifo_rd = inst[6];
	
	ofifo #(.col(col), .bw(psum_bw)) ofifo_inst(
		.clk(clk),
		.in(mac_out_s),
		.out(ofifo_out),
		.rd(ofifo_rd),
		.wr(mac_valid),
		.o_full(ofifo_o_full),
		.reset(reset),
		.o_ready(ofifo_o_ready),
		.o_valid(ofifo_o_valid)
	);

	// SFPs
	wire sfp_acc, sfp_relu;
	
	assign sfp_acc = inst[33];
	assign sfp_relu = 0;

	genvar i;
	for (i = 0; i < col; i = i + 1) begin
		sfp #(.bw(psum_bw)) sfp_instance (
			.clk(clk),
			.reset(reset),
			.acc(sfp_acc),
			.relu(sfp_relu),
			.in(ofifo_out[psum_bw*(i+1)-1:psum_bw*i]),
			.out(sfp_out[psum_bw*(i+1)-1:psum_bw*i])
		);
	end

endmodule

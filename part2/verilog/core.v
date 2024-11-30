module core(clk, reset, inst, D_xmem, ofifo_valid, sfp_out);

	parameter bw = 4;
	parameter psum_bw = 16;
	parameter col = 8;
	parameter row = 8;

	input clk, reset;
	input [33:0] inst;
	input [bw*row-1:0] D_xmem;

	output ofifo_valid;
	output [col*psum_bw-1:0] sfp_out;

	// TODO: read/write to SRAM

	wire [row*bw-1:0] corelet_in;

	corelet #(.bw(bw), .col(col), .row(row)) corelet_instance (
		.clk(clk),
		.reset(reset),
		.inst(inst),
		.l0_in(corelet_in),
		.sfp_out(sfp_out)
	);

endmodule	
















module sfp(clk, reset, acc, relu, in, out);

	parameter bw = 16;

	input clk, reset;
	input acc, relu;
	input [bw-1:0] in;
	output [bw-1:0] out;

	reg [bw-1:0] psum_q;

	assign out = psum_q;

	always @ (posedge clk) begin
		if(reset)
			psum_q <= 0;
		if(acc == 1)
			psum_q <= psum_q + in;
		else if (relu == 1)
			psum_q <= (in >= 0) ? in : 0;
	end

endmodule

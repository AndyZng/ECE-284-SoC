module core (
    clk,
    reset,
    inst,
    D_xmem,
    sfp_out,
    ofifo_valid
);

parameter row = 8;
parameter col = 8;
parameter bw = 4;
parameter psum_bw = 16;

input clk, reset;
input [33:0] inst;
input [bw*row-1:0] D_xmem; // [31:0]
output [psum_bw*col-1:0] sfp_out; // [127:0]
output ofifo_valid;

// Extract control signals from inst
wire acc;
wire CEN_pmem;
wire WEN_pmem;
wire [10:0] A_pmem;
wire CEN_xmem;
wire WEN_xmem;
wire [10:0] A_xmem;
wire ofifo_rd;
wire l0_rd;
wire l0_wr;
wire execute;
wire load;

assign acc         = inst[33];
assign CEN_pmem    = inst[32];
assign WEN_pmem    = inst[31];
assign A_pmem      = inst[30:20];
assign CEN_xmem    = inst[19];
assign WEN_xmem    = inst[18];
assign A_xmem      = inst[17:7];
assign ofifo_rd    = inst[6];
assign l0_rd       = inst[3];
assign l0_wr       = inst[2];
assign execute     = inst[1];
assign load        = inst[0];

// xmem instance
wire [bw*row-1:0] Q_xmem; // [31:0]
sram_32b_w2048 xmem_inst (
    .CLK(clk),
    .D(D_xmem),
    .Q(Q_xmem),
    .CEN(CEN_xmem),
    .WEN(WEN_xmem),
    .A(A_xmem)
);

// pmem instance
wire [psum_bw*col-1:0] Q_pmem; // [127:0]
sram_128b_w2048 pmem_inst (
    .CLK(clk),
    .D(sfp_out),
    .Q(Q_pmem),
    .CEN(CEN_pmem),
    .WEN(WEN_pmem),
    .A(A_pmem)
);

// l0_in
wire [bw*row-1:0] l0_in;
assign l0_in = Q_xmem;

// Instantiate corelet
wire [psum_bw*col-1:0] ofifo_out;
wire ofifo_o_valid;
corelet #(
    .row(row),
    .col(col),
    .bw(bw),
    .psum_bw(psum_bw)
) corelet_inst (
    .clk(clk),
    .reset(reset),
    .inst(inst),
    .l0_in(l0_in),
    .ofifo_out(ofifo_out),
    .ofifo_o_valid(ofifo_o_valid)
);

assign ofifo_valid = ofifo_o_valid;

// Instantiate SFPs
genvar i;
generate
    for (i = 0; i < col; i = i + 1) begin : sfp_gen
        sfp #(.bw(psum_bw)) sfp_instance (
            .clk(clk),
            .reset(reset),
            .acc(acc),
            .relu(0), // adjust later
            .in(ofifo_out[psum_bw*(i+1)-1:psum_bw*i]),
            .prev_psum(Q_pmem[psum_bw*(i+1)-1:psum_bw*i]),
            .out(sfp_out[psum_bw*(i+1)-1:psum_bw*i])
        );
    end
endgenerate

endmodule

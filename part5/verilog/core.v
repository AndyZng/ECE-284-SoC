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
input [34:0] inst;
input signed [bw*row-1:0] D_xmem; 
output signed [psum_bw*col-1:0] sfp_out; 
output ofifo_valid;

// Extract control signals from inst
wire mode = inst[34];
wire acc         = inst[33];
wire CEN_pmem    = inst[32];
wire WEN_pmem    = inst[31];
wire [10:0] A_pmem= inst[30:20];
wire CEN_xmem    = inst[19];
wire WEN_xmem    = inst[18];
wire [10:0] A_xmem= inst[17:7];
wire ofifo_rd    = inst[6];
wire l0_rd       = inst[3];
wire l0_wr       = inst[2];
wire execute     = inst[1];
wire load        = inst[0];

wire signed [bw*row-1:0] Q_xmem;
sram_32b_w2048 xmem_inst (
    .CLK(clk),
    .D(D_xmem),
    .Q(Q_xmem),
    .CEN(CEN_xmem),
    .WEN(WEN_xmem),
    .A(A_xmem)
);

wire signed [psum_bw*col-1:0] Q_pmem;
sram_128b_w2048 pmem_inst (
    .CLK(clk),
    .D(sfp_out),
    .Q(Q_pmem),
    .CEN(CEN_pmem),
    .WEN(WEN_pmem),
    .A(A_pmem)
);

// l0_in
wire signed [bw*row-1:0] l0_in = Q_xmem;

// Corelet inst
wire signed [psum_bw*col-1:0] ofifo_out;
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

// SFP for accumulation / ReLU
genvar i;
generate
    for (i = 0; i < col; i = i + 1) begin : sfp_gen
        sfp #(.bw(psum_bw)) sfp_instance (
            .clk(clk),
            .reset(reset),
            .acc(acc),
            .relu(1'b0), // currently no relu
            .in(ofifo_out[psum_bw*(i+1)-1:psum_bw*i]),
            .prev_psum(Q_pmem[psum_bw*(i+1)-1:psum_bw*i]),
            .out(sfp_out[psum_bw*(i+1)-1:psum_bw*i])
        );
    end
endgenerate

endmodule

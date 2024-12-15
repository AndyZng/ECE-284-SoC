module core (
    input clk,
    input reset,
    input [33:0] inst,
    input [bw*row-1:0] D_xmem,
    output [psum_bw*col-1:0] sfp_out,
    output ofifo_valid
);

parameter row = 8;
parameter col = 8;
parameter bw = 4;
parameter psum_bw = 16;

input clk, reset;
input [33:0] inst;
input [bw*row-1:0] D_xmem;  // Data input from memory
output [psum_bw*col-1:0] sfp_out;  // Final output from PEs
output ofifo_valid;

// Control signals extraction
wire acc;
wire CEN_xmem;
wire WEN_xmem;
wire [10:0] A_xmem;
wire CEN_pmem;
wire WEN_pmem;
wire [10:0] A_pmem;
wire ofifo_rd;
wire execute;
wire load;
wire [1:0] mode_control;

assign acc = inst[33];
assign CEN_xmem = inst[32];
assign WEN_xmem = inst[31];
assign A_xmem = inst[30:20];
assign CEN_pmem = inst[19];
assign WEN_pmem = inst[18];
assign A_pmem = inst[17:7];
assign ofifo_rd = inst[6];
assign execute = inst[1];
assign load = inst[0];
assign mode_control = inst[5:4];  // 2-bit control for PE mode

// Instantiate IFIFO to load weight and input data into PE
wire [bw-1:0] ififo_out;
wire ififo_empty;
ififo #(.bw(bw)) ififo_inst (
    .clk(clk),
    .reset(reset),
    .data_in(D_xmem),
    .write_enable(WEN_xmem),
    .read_enable(execute),
    .data_out(ififo_out),
    .full(),
    .empty(ififo_empty)
);

// Instantiate multiple PEs in the array
genvar i;
generate
    for (i = 0; i < col; i = i + 1) begin : pe_gen
        pe #(
            .bw(bw),
            .psum_bw(psum_bw)
        ) pe_inst (
            .clk(clk),
            .reset(reset),
            .input_data(ififo_out),
            .weight_data(D_xmem),  // Assuming D_xmem contains weight data
            .mode_control(mode_control),
            .write_enable(execute),
            .read_enable(ofifo_rd),
            .output_data(sfp_out[psum_bw*(i+1)-1:psum_bw*i]),
            .valid(ofifo_valid)
        );
    end
endgenerate

endmodule

module ififo (clk, in, out, rd, wr, o_full, reset, o_ready);
  parameter row  = 8;
  parameter bw = 4;

  input  clk;
  input  wr;
  input  rd;
  input  reset;
  input  signed [row*bw-1:0] in;
  output signed [row*bw-1:0] out;
  output o_full;
  output o_ready;

  wire [row-1:0] empty;
  wire [row-1:0] full;
  reg [row-1:0] rd_en;

  assign o_ready = ~&full;
  assign o_full  = &full;

  genvar i;
  for (i=0; i<row ; i=i+1) begin : row_num
      fifo_depth64 #(.bw(bw)) fifo_instance (
         .rd_clk(clk),
         .wr_clk(clk),
         .rd(rd_en[i]),
         .wr(wr),
         .o_empty(empty[i]),
         .o_full(full[i]),
         .in(in[bw*(i+1)-1:bw*i]),
         .out(out[bw*(i+1)-1:bw*i]),
         .reset(reset)
      );
  end

  always @ (posedge clk) begin
   if (reset) begin
      rd_en <= {row{1'b0}};
   end else begin
      rd_en <= {row{rd}};
   end
  end

endmodule

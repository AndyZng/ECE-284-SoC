// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter row = 8;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  input  [row*bw-1:0] in_w; 
  input  [1:0] inst_w;         // inst_w[1]=execute, inst_w[0]=load_kernel
  input  [psum_bw*col-1:0] in_n;
  output [col-1:0] valid;

  // In output-stationary mode:
  // - `execute`=1: MACs accumulate partial sums internally.
  // - `execute`=0: MACs output the final accumulated sums.
  wire execute = inst_w[1]; 
  // load_kernel = inst_w[0] if needed for kernel loading inside mac_row

  reg    [2*row-1:0] inst_w_temp;
  wire   [psum_bw*col*(row+1)-1:0] temp;
  wire   [row*col-1:0] valid_temp;

  genvar i;

  // In OS mode, we still use 'temp' for final output, but now
  // the rows will produce final sums only when execute=0.
  // The top row of `temp` is initialized to the input partial sums (in_n).
  assign temp[psum_bw*col*1-1:psum_bw*col*0] = in_n;

  // The final output is taken from the last row of the array
  // after execution completes.
  assign out_s = temp[psum_bw*col*(row+1)-1 : psum_bw*col*row];

  // 'valid' is asserted after execution completes. The bottom row
  // (last row_num) gives the final valid signals.
  assign valid = valid_temp[row*col-1:row*col-8];

  // Instantiate mac_row for each row of the array
  // Note: mac_row must be modified to work in OS mode:
  // - It should hold partial sums internally while execute=1.
  // - When execute=0, it should produce final psums in its out_s port.
  // - inst_w_temp passing is maintained as in original code, but now
  //   mac_row will use execute=inst_w_temp[x] internally for OS mode logic.
  
  for (i = 1; i < row+1 ; i=i+1) begin : row_num
      mac_row #(.bw(bw), .psum_bw(psum_bw)) mac_row_instance (
         .clk(clk),
         .reset(reset),
         .in_w(in_w[bw*i-1:bw*(i-1)]),
         .inst_w(inst_w_temp[2*i-1:2*(i-1)]), // This includes execute and load_kernel signals pipelined
         .in_n(temp[psum_bw*col*i-1:psum_bw*col*(i-1)]), 
         .valid(valid_temp[col*i-1:col*(i-1)]),
         .out_s(temp[psum_bw*col*(i+1)-1:psum_bw*col*(i)])
      );
  end

  always @ (posedge clk) begin
    // Pipeline inst_w down through inst_w_temp
    // This allows each row to see a delayed version of inst_w
    // as in the original code. OS logic in mac_row should rely on execute signal.
    inst_w_temp[1:0]   <= inst_w; 
    inst_w_temp[3:2]   <= inst_w_temp[1:0]; 
    inst_w_temp[5:4]   <= inst_w_temp[3:2]; 
    inst_w_temp[7:6]   <= inst_w_temp[5:4]; 
    inst_w_temp[9:8]   <= inst_w_temp[7:6]; 
    inst_w_temp[11:10] <= inst_w_temp[9:8]; 
    inst_w_temp[13:12] <= inst_w_temp[11:10]; 
    inst_w_temp[15:14] <= inst_w_temp[13:12]; 
  end

endmodule

`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;    // 3x3 kernel flattened to 9
parameter len_onij = 16;  // example output length placeholder
parameter col = 8;
parameter row = 8;
parameter len_nij = 36;   // example input length placeholder
parameter NUM_IC = 64;
parameter NUM_OC = 64;
parameter ARRAY_SIZE = 8;
integer ic_tile, oc_tile, kij;

reg clk = 0;
reg reset = 1;

wire [33:0] inst_q; 

reg [1:0]  inst_w_q = 0; 
reg [bw*row-1:0] D_xmem_q = 0;
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;

reg [1:0]  inst_w;
reg [bw*row-1:0] D_xmem;
reg [psum_bw*col-1:0] answer;

reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [8*50:1] w_file_name; // longer file name to accommodate tile info
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;

integer x_file, x_scan_file ; 
integer w_file, w_scan_file ;
integer out_file, out_scan_file ;
integer captured_data; 
integer t, i, j;
integer error;

assign inst_q[33] = acc_q;
assign inst_q[32] = 1'b1; // no pmem used in test
assign inst_q[31] = 1'b1;
assign inst_q[30:20] = 11'b0;
assign inst_q[19]   = CEN_xmem_q;
assign inst_q[18]   = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6]    = ofifo_rd_q;
assign inst_q[5]    = ififo_wr_q;
assign inst_q[4]    = ififo_rd_q;
assign inst_q[3]    = l0_rd_q;
assign inst_q[2]    = l0_wr_q;
assign inst_q[1]    = execute_q;
assign inst_q[0]    = load_q;

core  #(.bw(bw), .col(col), .row(row)) core_instance (
    .clk(clk), 
    .inst(inst_q),
    .ofifo_valid(ofifo_valid),
    .D_xmem(D_xmem_q), 
    .sfp_out(sfp_out), 
    .reset(reset)
); 

initial begin 

  inst_w   = 0; 
  D_xmem   = 0;
  CEN_xmem = 1;
  WEN_xmem = 1;
  A_xmem   = 0;
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd    = 0;
  l0_wr    = 0;
  execute  = 0;
  load     = 0;
  error    = 0;
  acc      = 0;

  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

  // Load Activation Data
  x_file = $fopen("activation.txt", "r");
  // skip header lines
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);

  // Reset sequence
  #0.5 clk = 0;   reset = 1;
  #0.5 clk = 1; 
  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 0;
    #0.5 clk = 1;  
  end
  #0.5 clk = 0; reset = 0;
  #0.5 clk = 1; 

  // Write Activation data into xmem
  for (t=0; t<len_nij; t=t+1) begin  
    #0.5 clk = 0;
    x_scan_file = $fscanf(x_file,"%32b", D_xmem);
    WEN_xmem = 0; CEN_xmem = 0; 
    if (t>0) A_xmem = A_xmem + 1;
    #0.5 clk = 1;   
  end
  #0.5 clk = 0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
  #0.5 clk = 1; 
  $fclose(x_file);

  // Loop over tiles
  for (ic_tile = 0; ic_tile < NUM_IC/ARRAY_SIZE; ic_tile = ic_tile + 1) begin
    for (oc_tile = 0; oc_tile < NUM_OC/ARRAY_SIZE; oc_tile = oc_tile + 1) begin

      // For each kij
      for (kij=0; kij<len_kij; kij=kij+1) begin


        $sformat(w_file_name, "weight_oc%d_ic%d_kij%d.txt", oc_tile, ic_tile, kij);

        w_file = $fopen(w_file_name, "r");
        // skip headers
        w_scan_file = $fscanf(w_file,"%s", captured_data);
        w_scan_file = $fscanf(w_file,"%s", captured_data);
        w_scan_file = $fscanf(w_file,"%s", captured_data);

        // Reset before loading weights for each kij
        #0.5 clk = 0;   reset = 1;
        #0.5 clk = 1; 
        for (i=0; i<10 ; i=i+1) begin
          #0.5 clk = 0;
          #0.5 clk = 1;  
        end
        #0.5 clk = 0;   reset = 0;
        #0.5 clk = 1; 

        // Write kernel tile data to xmem (assume kernel data goes to addr starting from 1024)
        A_xmem = 11'b10000000000; // 1024
        for (t=0; t<col; t=t+1) begin  
          #0.5 clk = 0;  
          w_scan_file = $fscanf(w_file,"%32b", D_xmem); 
          WEN_xmem = 0; CEN_xmem = 0; 
          if (t>0) A_xmem = A_xmem + 1; 
          #0.5 clk = 1;  
        end
        #0.5 clk = 0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
        #0.5 clk = 1; 

        // Load kernel from xmem to L0
        A_xmem = 11'b10000000000; 
        #0.5 clk = 0; CEN_xmem = 0; WEN_xmem = 1; l0_wr = 1;
        #0.5 clk = 1;  
        for (i=0; i<col; i=i+1) begin
          #0.5 clk = 0; if (i>0) A_xmem = A_xmem + 1;
          #0.5 clk = 1;  
        end
        #0.5 clk = 0; l0_wr = 0; CEN_xmem = 1;
        #0.5 clk = 1;   

        // Load kernel to PEs
        #0.5 clk = 0; load = 1; l0_rd = 1;
        #0.5 clk = 1;  
        for (i=0; i<col; i=i+1) begin
          #0.5 clk = 0;
          #0.5 clk = 1;
        end
        #0.5 clk = 0; load = 0; l0_rd = 0;
        #0.5 clk = 1; 

        // Small gap
        for (i=0; i<10 ; i=i+1) begin
          #0.5 clk = 0;
          #0.5 clk = 1;  
        end
        A_xmem = 0;
        for (t=0; t<len_nij; t=t+1) begin  
          #0.5 clk = 0; CEN_xmem = 0; WEN_xmem = 1; l0_wr = 1; 
          if (t>0) A_xmem = A_xmem + 1;
          #0.5 clk = 1;  
        end
        #0.5 clk = 0; l0_wr = 0; CEN_xmem = 1;
        #0.5 clk = 1;   

        if ((ic_tile > 0) || (oc_tile > 0) || (kij > 0))
          acc = 1;  // accumulate with previous partial sums

        #0.5 clk = 0; execute = 1; l0_rd = 1;
        #0.5 clk = 1;  
        for (i=0; i<len_nij+col; i=i+1) begin
          #0.5 clk = 0;
          #0.5 clk = 1;
        end
        #0.5 clk = 0; execute = 0; l0_rd = 0;
        #0.5 clk = 1;  


        $fclose(w_file);

      end // end kij loop
    end // end oc_tile loop
  end // end ic_tile loop


  if (error == 0) begin
    $display("############ No error detected ##############"); 
    $display("########### Project Completed !! ############"); 
  end else begin
    $display("########### Errors detected during execution ###########");
  end

  for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 0;  
    #0.5 clk = 1;  
  end

  #10 $finish;

end

always @ (posedge clk) begin
   inst_w_q   <= inst_w; 
   D_xmem_q   <= D_xmem;
   CEN_xmem_q <= CEN_xmem;
   WEN_xmem_q <= WEN_xmem;
   A_xmem_q   <= A_xmem;
   ofifo_rd_q <= ofifo_rd;
   acc_q      <= acc;
   ififo_wr_q <= ififo_wr;
   ififo_rd_q <= ififo_rd;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
end

endmodule

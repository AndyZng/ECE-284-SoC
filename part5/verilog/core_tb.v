`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_onij = 16;
parameter col = 8;
parameter row = 8;
parameter len_nij = 36;

reg clk = 0;
reg reset = 1;

wire [34:0] inst_q; 

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
reg mode_bit = 1; // 0=WS, 1=OS

reg [1:0]  inst_w; 
reg signed [bw*row-1:0] D_xmem;
reg signed [psum_bw*col-1:0] answer;

reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
wire ofifo_valid;
wire signed [col*psum_bw-1:0] sfp_out;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij;
integer error;

assign inst_q[34] = mode_bit;
assign inst_q[33] = acc_q;
assign inst_q[32] = 1'b1; // CEN_pmem assumed unused
assign inst_q[31] = 1'b1; // WEN_pmem assumed unused
assign inst_q[30:20] = 11'b0; 
assign inst_q[19]   = CEN_xmem_q;
assign inst_q[18]   = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6]   = ofifo_rd_q;
assign inst_q[5]   = ififo_wr_q;
assign inst_q[4]   = ififo_rd_q;
assign inst_q[3]   = l0_rd_q;
assign inst_q[2]   = l0_wr_q;
assign inst_q[1]   = execute_q; 
assign inst_q[0]   = load_q; 

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
  mode_bit = 0; // Set to 0 for WS test, 1 for OS test (adjust as needed)

  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

  x_file = $fopen("activation.txt", "r");
  // Skip header lines
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);

  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;   
  /////////////////////////

  /////// Activation data writing to memory ///////
  for (t=0; t<len_nij; t=t+1) begin  
    #0.5 clk = 1'b0; 
    x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
    WEN_xmem = 0; 
    CEN_xmem = 0; 
    if (t>0) A_xmem = A_xmem + 1;
    #0.5 clk = 1'b1;   
  end

  #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
  #0.5 clk = 1'b1; 

  $fclose(x_file);
  /////////////////////////////////////////////////

  for (kij=0; kij<9; kij=kij+1) begin  // kij loop

    case(kij)
     0: w_file_name = "weight_kij0.txt";
     1: w_file_name = "weight_kij1.txt";
     2: w_file_name = "weight_kij2.txt";
     3: w_file_name = "weight_kij3.txt";
     4: w_file_name = "weight_kij4.txt";
     5: w_file_name = "weight_kij5.txt";
     6: w_file_name = "weight_kij6.txt";
     7: w_file_name = "weight_kij7.txt";
     8: w_file_name = "weight_kij8.txt";
    endcase
    

    w_file = $fopen(w_file_name, "r");
    // Skip header lines
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);

    #0.5 clk = 1'b0;   reset = 1;
    #0.5 clk = 1'b1; 

    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   reset = 0;
    #0.5 clk = 1'b1; 

    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   

    /////// Kernel data writing to memory ///////
    A_xmem = 11'b10000000000; // Starting address 1024 for kernel data

    for (t=0; t<col; t=t+1) begin  
      #0.5 clk = 1'b0;  
      w_scan_file = $fscanf(w_file,"%32b", D_xmem); 
      WEN_xmem = 0; 
      CEN_xmem = 0; 
      if (t>0) A_xmem = A_xmem + 1; 
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////

    if (mode_bit == 0) begin
      A_xmem = 11'b10000000000;
      #0.5 clk = 1'b0; CEN_xmem = 0; WEN_xmem = 1; l0_wr = 1;
      #0.5 clk = 1'b1;  
      for (i=0; i<col; i=i+1) begin
        #0.5 clk = 1'b0; 
        if (i>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;  
      end
      #0.5 clk = 1'b0; l0_wr = 0; CEN_xmem = 1;
      #0.5 clk = 1'b1;   
    end else begin
      A_xmem = 11'b10000000000;
      #0.5 clk = 1'b0; CEN_xmem = 0; WEN_xmem = 1; ififo_wr = 1;
      #0.5 clk = 1'b1;
      for (i=0; i<col; i=i+1) begin
        #0.5 clk = 1'b0;
        if (i>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;
      end
      #0.5 clk = 1'b0; ififo_wr = 0; CEN_xmem = 1;
      #0.5 clk = 1'b1;
    end

    /////// Kernel loading to PEs ///////
    #0.5 clk = 1'b0; load = 1; l0_rd = (mode_bit==0); ififo_rd = (mode_bit==1);
    #0.5 clk = 1'b1;  
    for (i=0; i<col; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;
    end
    #0.5 clk = 1'b0; load = 0; l0_rd = 0; ififo_rd = 0;
    #0.5 clk = 1'b1;  

    ////// intermission
    #0.5 clk = 1'b0; load = 0; l0_rd = 0; ififo_rd = 0;
    #0.5 clk = 1'b1;  
    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

    /////// Activation data writing to L0 ///////
    A_xmem = 0; // Starting address of activation data
    for (t=0; t<len_nij; t=t+1) begin  
      #0.5 clk = 1'b0; 
      CEN_xmem = 0; 
      WEN_xmem = 1; 
      l0_wr = 1; 
      if (t>0) A_xmem = A_xmem + 1;
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0; l0_wr = 0; CEN_xmem = 1;
    #0.5 clk = 1'b1;   

    /////// Execution ///////
    #0.5 clk = 1'b0; execute = 1; l0_rd = (mode_bit==0); ififo_rd = (mode_bit==1);
    #0.5 clk = 1'b1;  
    for (i=0; i<len_nij+col; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;
    end
    #0.5 clk = 1'b0; execute = 0; l0_rd = 0; ififo_rd = 0;
    #0.5 clk = 1'b1;  

    //////// OFIFO READ ////////
    out_file = $fopen("out.txt", "r");  
    // Skip header lines
    out_scan_file = $fscanf(out_file,"%s", captured_data);
    out_scan_file = $fscanf(out_file,"%s", captured_data);
    out_scan_file = $fscanf(out_file,"%s", captured_data);

    for (i=0; i<len_onij; i=i+1) begin  
      #0.5 clk = 1'b0; ofifo_rd = 1;
      #0.5 clk = 1'b1;  
      if (ofifo_valid) begin
        out_scan_file = $fscanf(out_file,"%128b", answer); 
        if (sfp_out == answer)
          $display("%2d-th output Data matched!", i);
        else begin
          $display("%2d-th output Data ERROR!", i);
          $display("sfp_out: %128b", sfp_out);
          $display("answer : %128b", answer);
          error = 1;
        end
      end
    end

    #0.5 clk = 1'b0; ofifo_rd = 0;
    #0.5 clk = 1'b1;  

    $fclose(w_file);
    $fclose(out_file);

  end  // end of kij loop

  if (error == 0) begin
    $display("############ No error detected ##############"); 
    $display("########### Project Completed !! ############"); 
  end else begin
    $display("########### Errors detected during execution ###########");
  end

  for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;  
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

always #5 clk = ~clk;

endmodule

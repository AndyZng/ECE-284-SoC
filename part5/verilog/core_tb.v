`timescale 1ns / 1ps

module core_tb;
    reg clk;
    reg reset;
    reg [15:0] data_in;
    reg data_in_valid;
    wire [15:0] data_out;
    wire data_out_valid;
    
    core uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_in_valid(data_in_valid),
        .data_out(data_out),
        .data_out_valid(data_out_valid)
    );

    // Clock generation
    always begin
        #5 clk = ~clk;  // Toggle clock every 5 ns (100 MHz)
    end

    initial begin
        clk = 0;
        reset = 1;
        data_in = 16'b0;
        data_in_valid = 0;

        #10 reset = 0;
        
        #10;

        data_in = 16'hA5A5;
        data_in_valid = 1;
        #10;
        data_in_valid = 0;
        
        #10;
        data_in = 16'h5A5A;
        data_in_valid = 1;
        #10;
        data_in_valid = 0;
        
        #10;
        data_in = 16'h1234;
        data_in_valid = 1;
        #10;
        data_in_valid = 0;

        #10;
        data_in = 16'h4321;
        data_in_valid = 1;
        #10;
        data_in_valid = 0;

        #50;
        $finish;
    end

    initial begin
        $monitor("At time %t: data_in = %h, data_in_valid = %b, data_out = %h, data_out_valid = %b", 
                 $time, data_in, data_in_valid, data_out, data_out_valid);
    end
endmodule

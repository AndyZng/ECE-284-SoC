`timescale 1ns / 1ps

module core_tb;
    // Declare the testbench signals
    reg clk;
    reg reset;
    reg [15:0] data_in;
    reg data_in_valid;
    wire [15:0] data_out;
    wire data_out_valid;
    
    // Instantiate the core module (the DUT - Design Under Test)
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

    // Stimulus process
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        data_in = 16'b0;
        data_in_valid = 0;

        // Apply reset
        #10 reset = 0;
        
        // Wait for a few clock cycles
        #10;

        // Stimulus #1: Provide some data to PE
        data_in = 16'hA5A5;
        data_in_valid = 1;
        #10;  // Wait for a clock cycle
        data_in_valid = 0;
        
        // Stimulus #2: Provide more data
        #10;
        data_in = 16'h5A5A;
        data_in_valid = 1;
        #10;
        data_in_valid = 0;
        
        // Stimulus #3: Provide some data and wait for data_out to be valid
        #10;
        data_in = 16'h1234;
        data_in_valid = 1;
        #10;
        data_in_valid = 0;

        // Stimulus #4: Provide another set of data
        #10;
        data_in = 16'h4321;
        data_in_valid = 1;
        #10;
        data_in_valid = 0;

        // Finish the simulation after a few more cycles
        #50;
        $finish;
    end

    // Monitoring outputs
    initial begin
        // Monitor changes on signals
        $monitor("At time %t: data_in = %h, data_in_valid = %b, data_out = %h, data_out_valid = %b", 
                 $time, data_in, data_in_valid, data_out, data_out_valid);
    end
endmodule

module pe (
    input clk,
    input reset,
    input [bw-1:0] input_data,       // Input data from IFIFO
    input [bw-1:0] weight_data,      // Weight data
    input [1:0] mode_control,        // Control signal for mode: 00 -> Weight-Stationary, 01 -> Output-Stationary
    input write_enable,              // Write enable for PE
    input read_enable,               // Read enable for PE
    output reg [psum_bw-1:0] output_data,  // Output of PE
    output reg valid                 // Output valid flag
);

parameter bw = 4;           // Data bit width
parameter psum_bw = 16;     // Partial sum bit width

// Internal registers for input, weight, and output
reg [bw-1:0] input_reg;
reg [bw-1:0] weight_reg;
reg [psum_bw-1:0] output_reg;
reg [psum_bw-1:0] partial_sum;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        input_reg <= 0;
        weight_reg <= 0;
        output_reg <= 0;
        partial_sum <= 0;
        valid <= 0;
    end else if (write_enable) begin
        // Write the data based on mode control
        case (mode_control)
            2'b00: begin // Weight-Stationary Mode
                weight_reg <= weight_data;
                input_reg <= input_data;
            end
            2'b01: begin // Output-Stationary Mode
                input_reg <= input_data;
                weight_reg <= weight_data;
            end
            default: begin
                input_reg <= input_data;
                weight_reg <= weight_data;
            end
        endcase
    end

    if (read_enable) begin
        // Compute the partial sum
        partial_sum <= input_reg * weight_reg;

        // Accumulate to output register
        output_reg <= partial_sum;

        // Output valid flag
        valid <= 1;
    end else begin
        valid <= 0;
    end
end

assign output_data = output_reg;

endmodule

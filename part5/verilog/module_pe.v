module pe (
    input clk,
    input reset,
    input [bw-1:0] input_data,
    input [bw-1:0] weight_data, 
    input [1:0] mode_control,
    input write_enable,
    input read_enable, 
    output reg [psum_bw-1:0] output_data,
    output reg valid
);

parameter bw = 4; 
parameter psum_bw = 16; 

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
        partial_sum <= input_reg * weight_reg;
        output_reg <= partial_sum;
        valid <= 1;
    end else begin
        valid <= 0;
    end
end

assign output_data = output_reg;

endmodule

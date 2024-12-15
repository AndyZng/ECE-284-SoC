module ififo (
    input clk,
    input reset,
    input [bw-1:0] data_in,
    input write_enable,
    input read_enable,
    output reg [bw-1:0] data_out,
    output reg full,
    output reg empty
);

parameter bw = 4;   // Data bit width

// FIFO implementation (simplified for demonstration)
reg [bw-1:0] fifo_mem [0:15];  // FIFO memory with 16 entries
integer write_pointer, read_pointer;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        write_pointer <= 0;
        read_pointer <= 0;
        empty <= 1;
        full <= 0;
    end else if (write_enable && !full) begin
        fifo_mem[write_pointer] <= data_in;
        write_pointer <= write_pointer + 1;
        empty <= 0;
        if (write_pointer == 15) full <= 1;
    end else if (read_enable && !empty) begin
        data_out <= fifo_mem[read_pointer];
        read_pointer <= read_pointer + 1;
        full <= 0;
        if (read_pointer == 15) empty <= 1;
    end
end

endmodule

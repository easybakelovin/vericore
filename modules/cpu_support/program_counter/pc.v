module program_counter(
    input clk,
    input rst,
    input [7:0] pc_in,
    output reg [7:0] pc_out,
    input pc_inc_en
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 8'h00; // Reset to the beginning of memory
        end else if (pc_inc_en) begin
            pc_out <= pc_out + 1'b1;
        end else begin
            pc_out <= pc_in; // For jumps/branches
        end
    end

endmodule
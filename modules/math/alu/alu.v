module alu(
    input [7:0] operand1,
    input [7:0] operand2,
    input [2:0] alu_op, // Operation select: e.g., 000: ADD, 001: SUB, 010: AND, 011: OR, etc.
    output reg [7:0] result,
    output reg zero
);

    always @(*) begin
        case (alu_op)
            3'b000: result = operand1 + operand2;
            3'b001: result = operand1 - operand2;
            3'b010: result = operand1 & operand2;
            3'b011: result = operand1 | operand2;
            // Add more operations as needed (e.g., XOR, NOT, shifts, comparisons)
            default: result = 8'bx;
        endcase
        zero = (result == 8'h00);
    end

endmodule
module control_unit(
    input [2:0] opcode,
    input zero_flag,
    output reg [2:0] alu_op,
    output reg reg_write_en,
    output reg [2:0] write_reg_addr,
    output reg [7:0] mem_address,
    output reg mem_write_en,
    output reg [7:0] mem_write_data
);

    always @(*) begin
        // Default values
        alu_op = 3'b000;
        reg_write_en = 1'b0;
        write_reg_addr = 3'b000;
        mem_address = 8'h00;
        mem_write_en = 1'b0;
        mem_write_data = 8'h00;

        case (opcode)
            3'b000: // ADD Rd, Rs, Rt (Rd = Rs + Rt)
                begin
                    alu_op = 3'b000; // Addition
                    reg_write_en = 1'b1;
                    write_reg_addr = operand1_addr; // Destination register
                end
            3'b001: // SUB Rd, Rs, Rt (Rd = Rs - Rt)
                begin
                    alu_op = 3'b001; // Subtraction
                    reg_write_en = 1'b1;
                    write_reg_addr = operand1_addr;
                end
            // Add more instructions and their control signal generation
            default: ;
        endcase
    end

endmodule
module cpu(
    input clk,
    input rst,
    // Interface to external memory (can be refined later)
    output [7:0] mem_address,
    output mem_write_en,
    output [7:0] mem_write_data,
    input [7:0] mem_read_data
);

    wire [7:0] pc_out;
    wire [7:0] instruction;
    wire [2:0] opcode;
    wire [2:0] operand1_addr;
    wire [2:0] operand2_addr;
    wire [7:0] reg1_out, reg2_out, alu_result;
    wire zero_flag;
    wire [2:0] alu_op;
    wire reg_write_en;
    wire [2:0] write_reg_addr;

    // Instantiate Program Counter
    program_counter pc(
        .clk(clk),
        .rst(rst),
        .pc_in(alu_result), // For jumps/branches (simplified for now)
        .pc_out(pc_out),
        .pc_inc_en(1'b1) // Always increment for sequential execution (for now)
    );

    // Instantiate Memory (Instruction and Data - Harvard Architecture for simplicity)
    memory instruction_memory(
        .address(pc_out),
        .clk(clk),
        .write_en(1'b0), // Only reading instructions
        .write_data(8'b0),
        .read_data(instruction)
    );

    memory data_memory(
        .address(mem_address),
        .clk(clk),
        .write_en(mem_write_en),
        .write_data(mem_write_data),
        .read_data(mem_read_data)
    );

    // Instruction Decoding (Simple example format: [7:5] opcode, [4:2] operand1, [1:0] operand2)
    assign opcode = instruction[7:5];
    assign operand1_addr = instruction[4:2];
    assign operand2_addr = instruction[1:0];

    // Instantiate Register File
    registers reg_file(
        .clk(clk),
        .rst(rst),
        .read_addr1(operand1_addr),
        .read_addr2(operand2_addr),
        .write_en(reg_write_en),
        .write_addr(write_reg_addr),
        .write_data(alu_result),
        .read_data1(reg1_out),
        .read_data2(reg2_out)
    );

    // Instantiate ALU
    alu alu_unit(
        .operand1(reg1_out),
        .operand2(reg2_out),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero_flag)
    );

    // Instantiate Control Unit
    control_unit ctrl_unit(
        .opcode(opcode),
        .zero_flag(zero_flag),
        .alu_op(alu_op),
        .reg_write_en(reg_write_en),
        .write_reg_addr(write_reg_addr),
        .mem_address(mem_address),
        .mem_write_en(mem_write_en),
        .mem_write_data(mem_write_data)
        // ... other control signals will be added here
    );

endmodule
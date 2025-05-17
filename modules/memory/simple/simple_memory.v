module memory(
    input [7:0] address,
    input clk,
    input write_en,
    input [7:0] write_data,
    output reg [7:0] read_data
);

    reg [7:0] mem [255:0]; // 256 bytes of memory

    always @(posedge clk) begin
        if (write_en) begin
            mem[address] <= write_data;
        end
        read_data <= mem[address];
    end

    // Optional: Initialize memory content (for testing)
    initial begin
        // Example: Store some instructions
        mem[0] = 8'b000_000_01; // ADD R0, R1 (assuming opcode 000)
        mem[1] = 8'b001_010_00; // SUB R2, R0 (assuming opcode 001)
        // ... more instructions
    end

endmodule
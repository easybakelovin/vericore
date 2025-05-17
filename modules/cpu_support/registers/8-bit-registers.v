module registers(
    input clk,
    input rst,
    input [2:0] read_addr1,
    input [2:0] read_addr2,
    input write_en,
    input [2:0] write_addr,
    input [7:0] write_data,
    output reg [7:0] read_data1,
    output reg [7:0] read_data2
);

    reg [7:0] register_file [7:0]; // Array of 8 registers

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (integer i = 0; i < 8; i = i + 1) begin
                register_file[i] <= 8'h00;
            end
        end else if (write_en) begin
            register_file[write_addr] <= write_data;
        end
    end

    always @(*) begin
        read_data1 = register_file[read_addr1];
        read_data2 = register_file[read_addr2];
    end

endmodule
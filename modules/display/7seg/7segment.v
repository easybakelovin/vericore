module sevenseg_display(
    input wire [3:0] number,
    output reg [6:0] segments
);

// ====== 7-Segment Display Decoder ====== //
always @(*) begin
    case (number)
    4'd0: segments = 7'b1111110;
    4'd1: segments = 7'b0110000;
    4'd2: segments = 7'b1101101;
    4'd3: segments = 7'b1111001;
    4'd4: segments = 7'b0110011;
    4'd5: segments = 7'b1011011;
    4'd6: segments = 7'b1011111;
    4'd7: segments = 7'b1110000;
    4'd8: segments = 7'b1111111;
    4'd9: segments = 7'b1110011;
    default: segments = 7'b1111110;
    endcase
end
endmodule


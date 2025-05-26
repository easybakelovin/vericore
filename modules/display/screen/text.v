// ===================================================
// Module:       text.v
// Version:      0.2.0
// Author:       Oscar Mendez
// Date:         2025-05-26
// General Desc: Text engine module for displaying characters on a screen using an 8x16 font.
// Version Desc: This version allows the module to display characters based on pixel addresses and character codes.
// Notes:        Updated to support a simple text engine that can display characters based on pixel addresses.
//
// References: This code is based on Lushay Labs tutorial at https://learn.lushaylabs.com/tang-nano-9k-graphics/
// ===================================================

module textEngine(
    input clk,
    input [9:0] pixelAddress,
    input [7:0] charOutput, // Input character code to be displayed
    output [7:0] pixelData,
    output [5:0] charAddress // Output character address for debugging or further processing
);
    reg [7:0] fontBuffer [1519:0]; // 8x16 font, 16 rows of 8 pixels each
    initial $readmemh("./font.hex", fontBuffer); // Load font data from a hex file

    wire [2:0] columnAddress; // Track column address
    wire topRow;              // Track if we are in the top row of the character

    reg [7:0] outputBuffer;   // Buffer to hold the output pixel data
    wire [7:0] chosenChar;    // Character code chosen for display

    // ===== Test =====
    // wire [7:0] charOutput1; 
    // wire [7:0] charOutput2; 
    // wire [7:0] charOutput3; 
    // wire [7:0] charOutput4;

    // textRow #(6'd0) t1(
    //     clk,
    //     charAddress,
    //     charOutput1
    // );
    // textRow #(6'd16) t2(
    //     clk,
    //     charAddress,
    //     charOutput2
    // );
    // textRow #(6'd32) t3(
    //     clk,
    //     charAddress,
    //     charOutput3
    // );
    // textRow #(6'd48) t4(
    //     clk,
    //     charAddress,
    //     charOutput4
    // );
    // assign charOutput = (charAddress[5] && charAddress[4]) ? charOutput4 : ((charAddress[5]) ? charOutput3 : ((charAddress[4]) ? charOutput2 : charOutput1));
    // ===== End Test =====

    assign charAddress = {pixelAddress[9:8], pixelAddress[6:3]}; //
    assign columnAddress = pixelAddress[2:0];
    assign topRow = !pixelAddress[7];

    // ===== Example Character Code =====
    // In a real implementation, this would be set by the CPU or another module.
    // assign charOutput = "B"; // 8 bit character code for 'A' or | binary 01000001| decimal 65


    /*
    Font memory only has values for character codes 32-126.
    If output is outside this range, default to space (ASCII 32).
    This is a simple way to handle out-of-bounds character codes.
    */
    assign chosenChar = (charOutput >= 32 && charOutput <= 126) ? charOutput : 32;

    // Output pixel data based on character and column
    assign pixelData = outputBuffer;

    // Read the font data for the chosen character and column
    always @(posedge clk) begin
        // The value of chosenChar is used to index into the font buffer. Its value is offset by 32 to account for the ASCII range.
        // The columnAddress is used to select the specific column of the character. It is multiplied by 2 to account for the 2 bytes per column (8 pixels).
        // The topRow signal is used to select the correct row of the font data (top or bottom). It is used to select between the first and second byte of the column data.
        outputBuffer <= fontBuffer[((chosenChar-8'd32)<< 4) + (columnAddress << 1) + (topRow ? 0 : 1)];
    end

endmodule

module textRow #(
    parameter ADDRESS_OFFSET = 8'd0
) (
    input clk,
    input [7:0] readAddress,
    output [7:0] outByte
);
    reg [7:0] textBuffer [15:0];

    assign outByte = textBuffer[(readAddress-ADDRESS_OFFSET)];

    integer i;
    initial begin
        for (i=0; i<15; i=i+1) begin
            textBuffer[i] = 48 + ADDRESS_OFFSET + i;
        end
    end
endmodule
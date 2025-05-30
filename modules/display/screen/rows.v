// ===================================================
// Module:       rows.v
// Version:      0.2.0
// Author:       Oscar Mendez
// Date:         2025-05-26
// General Desc: 
// Version Desc: This version allows the module to receive pixel data from an external source and display it on the screen.
// Notes:        Updated support for receivable data.
//
// References: This code is based on Lushay Labs tutorial at https://learn.lushaylabs.com/tang-nano-9k-graphics/
// ===================================================

module uartTextRow #(
    parameters
) (
    input clk,
    input byteReady, // Signal indicating a byte has been received
    input [7:0] data,
    input [3:0] outputCharIndex,
    output [7:0] outByte
);

    localparam bufferWidth = 128;           // Width of the buffer for the row
    reg [(bufferWidth-1):0] textBuffer = 0; // Buffer to hold the row data
    reg [3:0] inputCharIndex = 0;           // Index for the current character in the buffer
    reg [1:0] state = 0;

    localparam STATE_WAIT_FOR_NEXT_CHAR = 0;       // State waiting for the next character
    localparam STATE_WAIT_FOR_TRANSFER_FINISH = 1; // State waiting for the transfer to finish
    localparam STATE_SAVING_CHARACTER_STATE = 2;   // State saving the character to the buffer

    always @(posedge clk) begin
        case (state)
            STATE_WAIT_FOR_NEXT_CHAR:
                if (byteReady == 0) begin
                    state <= STATE_WAIT_FOR_TRANSFER_FINISH;
                end
            STATE_WAIT_FOR_TRANSFER_FINISH: begin
                if (byteReady == 1)
                state <= STATE_SAVING_CHARACTER_STATE;
            end
            STATE_SAVING_CHARACTER_STATE: begin
                if (data == 8'd8 || data == 8'd127) begin
                    // Handle backspace or delete (8 or 127)
                    inputCharIndex <= inputCharIndex - 1; // Decrement index
                    textBuffer[({4'd0, inputCharIndex-4'd1}<<3)+:8] <= 8'd32; // Replace with space
                end 
                else begin
                    inputCharIndex <= inputCharIndex + 1; // Increment index
                    textBuffer[({4'd0, inputCharIndex}<<3)+:8] <= data; // Store the character
                end
                state <= STATE_WAIT_FOR_NEXT_CHAR; // Go back to waiting for the next character
            end
            default: 
        endcase
        
    end 
    
endmodule


// ========= Binary Row Module ========= //
// Module to display a binary representation of a value in a row
module binaryRow (
    input clk,
    input [7:0] value,
    input [3:0] outputCharIndex,
    output [7:0] outByte
);
    reg [7:0] outByteReg = 0;
    wire [2:0] bitNumber;

    assign bitNumber = outputCharIndex - 5; // Adjust index for binary representation

    always @(posedge clk) begin
        case (outputCharIndex)
            0: outByteReg <= "B"; // Row label
            1: outByteReg <= "i"; // Row label
            2: outByteReg <= "n"; // Row label
            3: outByteReg <= ":"; // Row label
            4: outByteReg <= " "; // Row label
            13, 14, 15: outByteReg <= " "; // Padding spaces
            default: outByteReg <= (value[7-bitNumber]) ? "1" : "0"; // Binary digit
        endcase
    end
    assign outByte = outByteReg;
endmodule

// ========== Hexadecimal Row Module ========== //
module hexDecRow (
    input clk,
    input [7:0] value,
    input [3:0] outputCharIndex,
    output [7:0] outByte
);
    // Wire and register declarations
    reg [7:0] outByteReg = 0;

    wire [3:0] hexLower;
    wire [3:0] hexHigher;

    wire [7:0] lowerHexChar;
    wire [7:0] higherHexChar;

    // Convert the lower and higher nibbles of the value to hexadecimal characters
    assign hexLower = value[3:0]; // Lower nibble
    assign hexHigher = value[7:4]; // Higher nibble

    toHex hLo (
        .clk(clk),
        .value(hexLower),
        .hexChar(outByteReg[3:0])
    );

    toHex hHi (
        .clk(clk),
        .value(hexHigher),
        .hexChar(outByteReg[7:4])
    );

    toDec dec(
        .clk(clk),
        .value(value),
        .hundreds(decChar1),
        .tens(decChar2),
        .units(decChar3)
    )
    wire [7:0] decChar1;
    wire [7:0] decChar2;
    wire [7:0] decChar3;

    always @(posedge clk) begin
        case (outputCharIndex)
            0: outByteReg <= "H"; // Row label
            1: outByteReg <= "e"; // Row label
            2: outByteReg <= "x"; // Row label
            3: outByteReg <= ":"; // Row label
            5: outByteReg <= higherHexChar; // Row label
            6: outByteReg <= lowerHexChar; // Row label
            8: outByteReg <= "D"; // Row label
            9: outByteReg <= "e"; // Row label
            10: outByteReg <= "c"; // Row label
            11: outByteReg <= ":"; // Row label
            13: outByteReg <= decChar1; // First decimal digit
            14: outByteReg <= decChar2; // Second decimal digit
            15: outByteReg <= decChar3; // Third decimal digit
            default: outByteReg <= " "; // Padding spaces
        endcase
    end
    assign outByte = outByteReg;
endmodule

module toHex (
    input clk,
    input [3:0] value,
    output reg [7:0] hexChar = "0"
);
    always @(posedge clk) begin
        // If the value is less than 10, convert to ASCII '0' to '9'
        // If the value is 10 or more, convert to ASCII 'A' to 'F'
        hexChar <= (value <= 9) ? 8'd48 + value : 8'd55 + value; // Convert to ASCII hex character
    end
endmodule

// ========== Decimal Row Module ========== //
module toDec (
    input clk,
    input [7:0] value,
    output reg [7:0] hundreds = "0",
    output reg [7:0] tens = "0",
    output reg [7:0] units = "0"
);

    // Declare registers for the decimal digits
    reg [11:0] digits = 0;     // 12-bit register to hold the decimal digits
    reg [7:0] cachedValue = 0; // Cached value for the current conversion. Prevents displaying incorrect values during conversion
    reg [3:0] stepCounter = 0; // Step counter for the conversion process
    reg [3:0] state = 0;       // State machine variable

    // State machine states
    localparam STATE_START = 0;  // Initial state
    localparam STATE_ADD3 = 1;   // Add 3 to the value
    localparam STATE_SHIFT = 2;  // Shift the value
    localparam STATE_DONE = 3;   // Final state

    always @(posedge clk ) begin
        STATE_START: begin
            cachedValue <= value;  // Cache the value for conversion
            stepCounter <= 0;      // Reset step counter
            digits <= 0;           // Reset digits
            state <= STATE_ADD3;   // Move to the next state
        end
        STATE_ADD3: begin
            digits <= digits +
                ((digits[3:0] >=5) ? 12'd3 : 12'd0) +   // Add 3 if the last digit is greater than or equal to 5
                ((digits[7:4] >=5) ? 12'd48 : 12'd0) +  // Add 48 if the second digit is greater than or equal to 5
                ((digits[11:8] >=5) ? 12'd768 : 12'd0); // Add 768 if the third digit is greater than or equal to 5
            state <= STATE_SHIFT; // Move to the next state
        end
        STATE_SHIFT: begin
            digits <= {digits[10:0], cachedValue[7]}; // Shift the digits left by one position
            cachedValue <= {cachedValue[6:0], 1'b0};  // Shift the cached value left by one position
            if (stepCounter == 7)
                state <= STATE_DONE; // If 8 steps are done, move to the done state
            else
                stepCounter <= stepCounter + 1; // Increment the step counter
                state <= STATE_ADD3;            // Go back to the add 3 state 
        end
        STATE_DONE: begin
            hundreds <= (digits[11:8] + 8'd48); // Convert the hundreds digit to ASCII
            tens <= (digits[7:4] + 8'd48);      // Convert the tens digit to ASCII
            units <= (digits[3:0] + 8'd48);     // Convert the units digit to ASCII
            state <= STATE_START;               // Reset the state machine
        end
    end
    
endmodule

// ========== Progress Bar Row Module ========== //
module progressRow (
    clk,
    input [7:0] value,        // Value to display in the progress bar
    input [9:0] pixelAddress, // Pixel address for the row
    output [7:0] outByte      // Output byte for the row
);
    reg [7:0] outByteReg = 0; // Register to hold the output byte
    reg [7:0] bar; // Register to hold the progress bar value
    reg [7:0] border;
    wire [6:0] column;
    wire topRow;

    assign column = pixelAddress[6:0]; // Extract the column from the pixel address
    assign !pixelAddress[7];

    always @(posedge clk) begin
        if (topRow) begin
            case (column)
                0, 127: begin
                    bar = 8'b11000000; // Left border
                    border = 8'b11000000; // Right border
                end
                1, 126: begin
                    bar = 8'b11100000; // Left border
                    border = 8'b01100000; // Right border
                end
                2, 125: begin
                    bar = 8'b11100000; // Left border
                    border = 8'b00110000; // Right border
                end
                default: begin
                    bar = 8'b11110000;
                    border = 8'b00010000;
                end
            endcase
        end
        else begin
            case (column)
                0, 127: begin
                    bar = 8'b00000011;
                    border = 8'b00000011; // Left border
                end
                1, 126: begin
                    bar = 8'b00000111; // Left border
                    border = 8'b00000110; // Right border
                end: 
                2, 125: begin
                    bar = 8'b00001111; // Left border
                    border = 8'b00001100; // Right border
                end
                default: begin
                    bar = 8'b00001111; // Fill the progress bar
                    border = 8'b00001000; // Right border
                end
            endcase
        end

        if (column < value[7:1]) 
            outByte <= border;
        else
            outByte <= bar; // Fill the progress bar based on the value
    end
endmodule
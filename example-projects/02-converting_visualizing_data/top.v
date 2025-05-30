// ===================================================
// Module:       top.v
// Version:      0.2.0
// Author:       Oscar Mendez
// Date:         2025-05-26
// General Desc: This example project demonstrates how to convert and visualize data on a screen using a UART interface.
//                The project includes a text engine, a counter, and a progress bar.
//                It receives data from a UART source and displays it on the screen.
// Version Desc: This version allows the module to receive pixel data from an external source and display it on the screen.
// Notes:        Updated support for receivable data.
// Modules:      screen, textEngine, uart_rx, uartTextRow, binaryRow, hexDecRow, progressRow
//
// References: This code is based on Lushay Labs tutorial at https://learn.lushaylabs.com/tang-nano-9k-graphics/
// ===================================================

module top
#(
  parameter STARTUP_WAIT = 32'd10000000
)
(
    input clk,     // System clock
    input uart_rx,   // UART receive line for receiving data
    output ioSclk, // sLAVE clock for the screen
    output ioSdin, // sLAVE data in for the screen
    output ioCs,   // Chip select for the screen
    output ioDc,   // Data/Command select for the screen
    output ioReset// Reset signal for the screen
);
    localparam DELAY_FRAMES = 434; // Default value for 115200 baud on a 50 MHz clock
    wire [9:0] pixelAddress;
    wire [7:0] textPixelData; 
    wire [7:0] chosenPixelData;
    wire [5:0] charAddress;
    reg [7:0] charOutput;

    wire uartByteReady;
    wire [7:0] uartDataIn;
    wire [1:0] rowNumber;

    screen #(STARTUP_WAIT) scr(
        // Inputs
        .clk(clk),
        .pixelData(chosenPixelData), // Pixel data from the text engine
        // Outputs
        .io_sclk(ioSclk),
        .io_sdin(ioSdin),
        .io_cs(ioCs),
        .io_dc(ioDc),
        .io_reset(ioReset),
        .pixelAddress(pixelAddress)
    );

    textEngine te(
        clk,
        pixelAddress,
        charOutput,
        textPixelData,
        charAddress
    );

    assign rowNumber = charAddress[5:4];

    uart_rx #(DELAY_FRAMES) u (
        clk,
        uart_rx,
        uartByteReady, // Register output
        uartDataIn
    );

    // ============= Text Row for UART Data =============
    // This row displays the received UART data on the screen.
    uartTextRow row1(
        .clk(clk),
        .byteReady(uartByteReady),
        .data(uartDataIn),
        .outputCharIndex(charAddress[3:0]),
        .outByte(charOut1)
    );
    wire [7:0] charOut1;


    // ============= Counter and Data Conversion Rows =============
    counterM counter(
        .clk(clk),
        .counterValue(counterValue) // Output counter value to be used in other rows
    );
    wire [7:0] counterValue;

    // Binary Conversion Row
    binaryRow row2(
        .clk(clk),
        .value(counterValue),
        .outputCharIndex(charAddress[3:0]),
        .outByte(charOut2) // Output binary representation of the counter value
    );
    wire [7:0] charOut2;

    // Hexadecimal and Decimal Conversion Rows
    hexDecRow row3(
        .clk(clk),
        .value(counterValue),
        .outputCharIndex(charAddress[3:0]),
        .outByte(charOut3)
    );
    wire [7:0] charOut3;

    // ============= Progress Bar Row =============
    progressRow row4(
        .clk(clk),
        .value(counterValue),
        .pixelAddress(pixelAddress),
        .outByte(progressPixelData)
    );
    wire [7:0] progressPixelData;

    //============= Output Data Selection =============
    always @(posedge clk) begin
        case (rowNumber)
            0: charOutput <= charOut1;
            1: charOutput <= charOut2;
            2: charOutput <= charOut3;
            // 3: charOutput <= progressPixelData;
            default: charOutput <= 8'b0000_0000; // Progress bar data
        endcase
    end
    assign chosenPixelData = (rowNumber == 3) ? progressPixelData : textPixelData;
endmodule

// ============= Counter Module =============
// This module counts clock cycles and increments a counter value every 27 million cycles (approximately 1 second at 27 MHz).
module counterM(
    input clk,
    output reg [7:0] counterValue = 0
);
    reg [32:0] clockCounter = 0;

    localparam WAIT_TIME = 50000000;

    always @(posedge clk) begin
        if (clockCounter == WAIT_TIME) begin
            clockCounter <= 0;
            counterValue <= counterValue + 1;
        end
        else
            clockCounter <= clockCounter + 1;
    end
endmodule
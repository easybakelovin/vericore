// ===================================================
// Module:       flash_nav-W25Q64.v
// Version:      0.2.0
// Author:       Oscar Mendez
// Date:         2025-05-29
// General Desc: 
// This module implements a state machine to interface with a W25Q64 SPI flash memory chip,
// allowing navigation through memory contents using two buttons and displaying the data
// as ASCII characters for use with a text engine or display interface. It handles SPI
// communication, address management, and data formatting for display.
//
// Version Desc: This version allows the module to receive pixel data from an external source and display it on the screen.
// Notes:        Updated support for receivable data.
//
// References: This code is based on Lushay Labs tutorial at https://learn.lushaylabs.com/tang-nano-9k-graphics/
// ===================================================


module flashNavigator_W25Q64 
#(
    parameter STARTUP_WAIT = 32'd10000000
)
(
    // clk         : the main clock signal.
    // btn1        : button 1 input from the Tang Nano board.
    // btn2        : button 2 input from the Tang Nano board.
    // flashMiso   : SPI data input from the flash IC to the Tang Nano.
    // charAddress : current character address to display on the screen (used to interface with the text engine).
    // flashMosi   : SPI data output from the Tang Nano to the flash IC.
    // flashCs     : SPI chip select for the flash IC, active low.
    // flashClk    : SPI clock signal for the flash IC.
    // charOutput  : ASCII character to be displayed at charAddress.

    input clk,  // System clock
    input btn1, // Button 1 for navigation
    input btn2  // Button 2 for navigation
    // Flash memory interface signals
    input flashMiso,
    input [5:0] charAddress,  
    output reg flashMosi = 0, 
    output reg flashCs = 1,   
    output reg flashClk = 0,

    // ====== Display Interface =======
    output reg [7:0] charOutput = 0
) (
    // ======= Internal signals =======
    reg [23:0] readAddress = 0;   // Address to read from flash memory (24 bits for W25Q64)
    reg [7:0] command = 8'h03;    // Read command for W25Q64
    reg [7:0] currentByteOut = 0; // Current byte being read from flash memory
    reg [7:0] currentByteNum = 0; // Current byte number being processed - a counter
    reg [255:0] dataIn = 0;       // Incoming data from flash memory (32 bytes) Used during reading.
    reg [255:0] dataInBuffer = 0; // Buffer for incoming data from flash memory (32 bytes) Used when data has been completely read.

    // ======= State machine states =======
    localparam STATE_INIT_POWER = 8'd0;       // Initialize power and reset state
    localparam STATE_LOAD_CMD_TO_SEND = 8'd1; // Load command to send state
    localparam STATE_SEND_CMD = 8'd2;         // Send command state
    localparam STATE_LOAD_ADDR_TO_SEND = 8'd3;// Load address to send state
    localparam STATE_READ_DATA = 8'd4;        // Read data state
    localparam STATE_DONE = 8'd5;             // Done state

    reg [23:0] dataToSend = 0; // Data to send to flash memory (24 bits for W25Q64) 
    reg [8:0] bitsToSend = 0;  // Number of bits to send
    
    reg [32:0] counter = 0;    // Counter for timing operations
    reg [2:0] state = 0;       // Current state of the state machine
    reg [2:0] returnState = 0; // State to return to after processing

    reg dataReady = 0; // Flag to indicate data is ready to be processed

    // ======= State machine logic =======
    always @(posedge clk ) begin
        case (state)
            STATE_INIT_POWER: begin
                if (counter > STARTUP_WAIT && btn == 1 && btn2 == 1) begin
                    state <= STATE_LOAD_CMD_TO_SEND; // Move to load command state
                    counter <= 32'b0; // Reset counter
                    currentByteNum <= 0; // Reset current byte number
                    currentByteOut <= 0; // Reset current byte output
                end else begin
                    counter <= counter + 1; // Increment counter
                end
            end
            STATE_LOAD_CMD_TO_SEND: begin
                flashCs <= 0; // Activate chip select
                dataToSend[23-:8] <= Command; // Load command and address to send
                bitsToSend <= 8; // Set number of bits to send (8 bits for command + 24 bits for address)
                state <= STATE_SEND; // Move to send command state
                returnState <= STATE_LOAD_ADDR_TO_SEND; // Set return state
            end
            STATE_SEND: begin
                if (counter == 32'd0) begin
                    flashClk <= 0;                          // Set clock low
                    flashMosi <= dataToSend[23];            // Set MOSI to the most significant bit of data to send
                    dataToSend <= {dataToSend[22:0], 1'b0}; // Shift data to send
                    bitsToSend <= bitsToSend - 1;           // Decrement bits to send
                    counter <= 1;                           // Reset counter for next clock cycle
                end else begin
                    counter <= 32'd0; // Reset counter
                    flashClk <= 1; // Set clock high to signal data is ready
                    if (bitsToSend == 0) begin
                        state <= returnState; // Return to the previous state
                    end
                end 
            end
            STATE_LOAD_ADDR_TO_SEND: begin
                dataToSend <= readAddress;      // Load address to send
                bitsToSend <= 24;               // Set number of bits to send (24 bits for address)
                state <= STATE_SEND;            // Move to send address state
                returnState <= STATE_READ_DATA; // Set return state
                currentByteNum <= 0;            // Reset current byte number
            end
            STATE_READ_DATA: begin
                if (counter[0]== 1'b0) begin
                    flashClk <= 0;          // Set clock low
                    counter <= counter + 1; // Increment counter
                    if (counter[3:0] == 0 && counter > 0) begin // Every 16 clock cycles, read a byte
                        dataIn[(currentByteNum << 3)+:8] <= currentByteOut; // Store current byte output in dataIn
                        currentByteNum <= currentByteNum + 1;               // Increment current byte number
                        if (currentByteNum == 31) begin
                            state <= STATE_DONE; // If all bytes are read, move to done state
                        end
                    end
                end
                else begin
                    flashClk <= 1; // Set clock high to signal data is ready
                    currentByteOut <= {currentByteOut[6:0], flashMiso}; // Shift in the next bit from MISO
                    counter <= counter + 1; // Increment counter
                end
            end
            STATE_DONE: begin
                dataReady <= 1; // Set data ready flag
                flashCs <= 1; // Deactivate chip select
                dataInBuffer <= dataIn; // Store data in buffer
                counter <= STARTUP_WAIT;
                if (btn1 == 0)begin
                    readAddress <= readAddress + 24'd32; // Increment address by 32 bytes
                    state <= STATE_INIT_POWER; // Reset state machine to initial state
                end
                else if (btn2 == 0) begin
                    readAddress <= readAddress - 24'd32;
                    state <= STATE_INIT_POWER; // Reset state machine to initial state
                end
            end
        endcase
    end

    // ============================================
    // Display Interface
    // ============================================
    reg [7:0] chosenByte = 0;

    wire [7:0] lowerBit;
    wire [7:0] hexCharOutput;
    wire [3:0] currentHexVal;

    assign byteDisplayNumber = charAddress[5:1];
    assign lowerBit = charAddress[0];
    assign currentHexVal = lowerBit ? chosenByte[3:0] : chosenByte[7:4];

    genvar i;
    generate
        for (i = 0; i < 6; i = i +1) begin: address
            wire [7:0] hexChar;
            toHex hexConv(
                .clk(clk),
                .value(readAddress[{i, 2'b0}+:4]),
                .hexChar(hexChar)
            );
        end
    endgenerate

    always @(posedge clk ) begin
        chosenByte <= dataInBuffer[(byteDisplayNumber << 3)+:8];
        if (charAddress[5:4] == 2'b11) begin
            case (charAddress[3:0])
                0: charOutput <= "A";
                1: charOutput <= "d";
                2: charOutput <= "d";
                3: charOutput <= "r";
                4: charOutput <= ":";
                6: charOutput <= "0";
                7: charOutput <= "x";
                8: charOutput <= addr[5].hexChar;
                9: charOutput <= addr[4].hexChar;
                10: charOutput <= addr[3].hexChar;
                11: charOutput <= addr[2].hexChar;
                12: charOutput <= addr[1].hexChar;
                13: charOutput <= addr[0].hexChar;
                15: charOutput <= dataReady ? " " : "L";
                default: charOutput <= " ";
            endcase
        end
        else begin
            charOutput <= hexCharOutput;
        end
    end
);
    
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
module uart_tx #(
    /* 
    DELAY_FRAMES parameter specifies the number of clock cycles to wait for one UART bit period.
    For 115200 baud with a 100 MHz system clock, DELAY_FRAMES is calculated as:
    DELAY_FRAMES = CLOCK_FREQUENCY / BAUD_RATE = 100_000_000 / 115200 ≈ 868
    Adjust this value according to your system clock and desired baud rate.

    Example:
    For a 50 MHz system clock and 9600 baud:
    DELAY_FRAMES = 50_000_000 / 9600 ≈ 5208

    For a 100 MHz system clock and 9600 baud:
    DELAY_FRAMES = 100_000_000 / 9600 ≈ 10417

    For a 50 MHz system clock and 115200 baud:
    DELAY_FRAMES = 50_000_000 / 115200 ≈ 434
    */
    parameter DELAY_FRAMES = 868 // Default value for 115200 baud on a 100 MHz clock
) 
(
    input clk,
    input reset,
    input btn1,
    output uart_tx 
);
        
    reg [3:0] txState = 0;
    reg [24:0] txCounter = 0;
    reg [7:0] dataOut = 0;
    reg txPinRegister = 1;
    reg [2:0] txBitNumber = 0;
    reg [3:0] txByteCounter = 0;

    assign uart_tx = txPinRegister;

    localparam MEMORY_LENGTH = 12; // Length of the test message
    reg [7:0] testMemory [MEMORY_LENGTH-1:0]; // 8-bit memory array to store the test message. Length is 12 bytes

    // Initialize the test message in the memory array
    always @(posedge clk) begin
        if (reset) begin
            testMemory[0]  <= "O";  // 8'h4F
            testMemory[1]  <= "s";  // 8'h73
            testMemory[2]  <= "c";  // 8'h63
            testMemory[3]  <= "a";  // 8'h61
            testMemory[4]  <= "r";  // 8'h72
            testMemory[5]  <= "M";  // 8'h4D
            testMemory[6]  <= " ";  // 8'h20
            testMemory[7]  <= "i";  // 8'h69
            testMemory[8]  <= "s";  // 8'h73
            testMemory[9]  <= " ";  // 8'h20
            testMemory[10] <= "o";  // 8'h6F
            testMemory[11] <= "k";  // 8'h6B
        end
    end
    // initial begin
    //     testMemory[0] = "O";
    //     testMemory[1] = "s";
    //     testMemory[2] = "c";
    //     testMemory[3] = "a";
    //     testMemory[4] = "r";
    //     testMemory[5] = "M";
    //     testMemory[6] = " ";
    //     testMemory[7] = "i";
    //     testMemory[8] = "s";
    //     testMemory[9] = " ";
    //     testMemory[10] = "o";
    //     testMemory[11] = "k";
    // end

    // ========== TX State Machine ========== //
    // State machine for transmitting UART data
    localparam TX_STATE_IDLE = 0; // State waiting for the start signal
    localparam TX_STATE_START_BIT = 1; // State sending the start bit
    localparam TX_STATE_WRITE = 2; // State sending the data bits
    localparam TX_STATE_STOP_BIT = 3; // State sending the stop bit
    localparam TX_STATE_DEBOUNCE = 4; // State waiting for the button to be released

    always @(posedge clk) begin
        case (txState)
            TX_STATE_IDLE: begin
                if (btn1 == 0) begin
                    txState <= TX_STATE_START_BIT;
                    txCounter <= 0;
                    txByteCounter <= 0;
                end
                else begin
                    txPinRegister <= 1;
                end
            end 
            TX_STATE_START_BIT: begin
                txPinRegister <= 0;
                if ((txCounter + 1) == DELAY_FRAMES) begin
                    txState <= TX_STATE_WRITE;
                    dataOut <= testMemory[txByteCounter];
                    txBitNumber <= 0;
                    txCounter <= 0;
                end else 
                    txCounter <= txCounter + 1;
            end
            TX_STATE_WRITE: begin
                txPinRegister <= dataOut[txBitNumber];
                if ((txCounter + 1) == DELAY_FRAMES) begin
                    if (txBitNumber == 3'b111) begin
                        txState <= TX_STATE_STOP_BIT;
                    end else begin
                        txState <= TX_STATE_WRITE;
                        txBitNumber <= txBitNumber + 1;
                    end
                    txCounter <= 0;
                end else 
                    txCounter <= txCounter + 1;
            end
            TX_STATE_STOP_BIT: begin
                txPinRegister <= 1;
                if ((txCounter + 1) == DELAY_FRAMES) begin
                    if (txByteCounter == MEMORY_LENGTH - 1) begin
                        txState <= TX_STATE_DEBOUNCE;
                    end else begin
                        txByteCounter <= txByteCounter + 1;
                        txState <= TX_STATE_START_BIT;
                    end
                    txCounter <= 0;
                end else 
                    txCounter <= txCounter + 1;
            end
            TX_STATE_DEBOUNCE: begin
                if (txCounter == 23'b111111111111111111) begin
                    if (btn1 == 1) 
                        txState <= TX_STATE_IDLE;
                end else
                    txCounter <= txCounter + 1;
            end
        endcase      
    end
endmodule
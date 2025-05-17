module uart_rx #(
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
    input uart_rx,
    output reg[5:0] led // Output to display the received data
);
    localparam HALF_DELAY_WAIT = (DELAY_FRAMES / 2); // Half of the delay frames for bit sampling/detection

    reg [3:0] rxState = 0;
    reg [12:0] rxCounter = 0;
    reg [2:0] rxBitNumber = 0;
    reg [7:0] dataIn = 0;
    reg byteReady = 0;


    // ========== RX State Machine ========== //
    // State machine for receiving UART data
    localparam RX_STATE_IDLE = 0; // State waiting for the start bit
    localparam RX_STATE_START_BIT = 1; // State waiting for the data bit
    localparam RX_STATE_READ_WAIT = 2; // State waiting for the data bit to be read
    localparam RX_STATE_READ = 3; // State reading the data bit
    localparam RX_STATE_1 = 4; 
    localparam RX_STATE_STOP_BIT = 5; // State waiting for the stop bit
    
    always @(posedge clk ) begin
        case (rxState) 
            RX_STATE_IDLE: begin
                if (uart_rx == 0) begin
                    rxState <= RX_STATE_START_BIT;
                    rxCounter <= 1;
                    rxBitNumber <= 0;
                    byteReady <= 0;
                end
            end
            RX_STATE_START_BIT: begin
                if (rxCounter == HALF_DELAY_WAIT) begin
                    rxState <= RX_STATE_READ_WAIT;
                    rxCounter <= 1;
                end else
                    rxCounter <= rxCounter + 1;
            end 
            RX_STATE_READ_WAIT: begin
                rxCounter <= rxCounter + 1;
                if ((rxCounter + 1) == DELAY_FRAMES) begin
                    rxState <= RX_STATE_READ;
                end
            end
            RX_STATE_READ: begin
                rxCounter <= 1;
                dataIn <= {uart_rx, dataIn[7:1]};
                rxBitNumber <= rxBitNumber + 1;
                if (rxBitNumber == 3'b111)
                    rxState <= RX_STATE_STOP_BIT;
                else
                    rxState <= RX_STATE_READ_WAIT;
            end
            RX_STATE_STOP_BIT: begin
                rxCounter <= rxCounter + 1;
                if ((rxCounter + 1) == DELAY_FRAMES) begin
                    rxState <= RX_STATE_IDLE;
                    rxCounter <= 0;
                    byteReady <= 1;
                end
            end
        endcase
    end


    // ========== LED Output ========== //
    // Display the received data on the LEDs
    always @(posedge clk) begin
        if (byteReady) begin 
            led <= dataIn[5:0];
    end
end


endmodule
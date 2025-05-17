/*
TODO: Description



*/

module screen #(
    parameter STARTUP_WAIT = 32'd10_000_000 // 1/3 of a second for a 27Mhz clock
) (
    input clk,
    output io_sclk,
    output io_sdin,
    output io_cs,
    output io_dc,
    output io_reset
);
    localparam STATE_INIT_POWER = 8'd0;
    localparam STATE_LOAD_INIT_CMD = 8'd1;
    localparam STATE_SEND = 8'd2;
    localparam STATE_CHECK_FINISHED_INIT = 8'd3;
    localparam STATE_LOAD_DATA = 8'd4;

    reg [32:0] counter = 0;
    reg [2:0] state = 0;

    // Register for each of the pins to drive
    reg dc = 1;
    reg sclk = 1;
    reg sdin = 0;
    reg reset = 1;
    reg cs = 0;

    reg [7:0] dataToSend = 0;   // Register for current byte to send
    reg [3:0] bitNumber = 0;    // Register to track which bit of the current byte we are on
    reg [9:0] pixelCounter = 0; // Register to keep track of which pixel on the screen we're on

    // All commands (15 total taking up 23 bytes)
    localparam SETUP_INSTRUCTIONS = 23; // Total bytes taken up by commands

    // register below for 23 bytes should be initialized accordingly
    reg [(SETUP_INSTRUCTIONS*8)-1:0] startupCommands = {
        8'hAE,  // display off

        8'h81,  // contrast value to 0x7F according to datasheet
        8'h7F,  

        8'hA6,  // normal screen mode (not inverted)

        8'h20,  // horizontal addressing mode
        8'h00,  

        8'hC8,  // normal scan direction

        8'h40,  // first line to start scanning from

        8'hA1,  // address 0 is segment 0

        8'hA8,  // mux ratio
        8'h3f,  // 63 (64 -1)

        8'hD3,  // display offset
        8'h00,  // no offset

        8'hD5,  // clock divide ratio
        8'h80,  // set to default ratio/osc frequency

        8'hD9,  // set precharge
        8'h22,  // switch precharge to 0x22 default

        8'hDB,  // vcom deselect level
        8'h20,  // 0x20 

        8'h8D,  // charge pump config
        8'h14,  // enable charge pump

        8'hA4,  // resume RAM content

        8'hAF   // display on
    };
    reg [7:0] commandIndex = SETUP_INSTRUCTIONS * 8; // Tracks current command

    // ===== Connect input/output wires to registers =====
    assign io_sclk = sclk;
    assign io_sdin = sdin;
    assign io_dc = dc;
    assign io_reset = reset;
    assign io_cs = cs;

    // ===== Load an Image =====
    reg [7:0] screenBuffer [1023:0];
    initial $readmemh("image.hex", screenBuffer);

    // ===== STATE MACHINE =====
    always @(posedge clk) begin
      case (state)
        STATE_INIT_POWER: begin
            counter <= counter + 1;
            if (counter < STARTUP_WAIT)
            // Idle state waiting for power to become stable
            reset <= 1; 
            else if (counter < STARTUP_WAIT * 2)
            // After power becomes stable, send reset command by pulling reset pin low
            reset <= 0;
            else if (counter < STARTUP_WAIT * 3)
             // Return pin to high and wait some time to ensure screen is ready to start receiving commands
            reset <= 1;
            else begin 
                // Move to next state & reset the counter
                state <= STATE_LOAD_INIT_CMD;
                counter <= 32'b0;
            end
        end
        STATE_LOAD_INIT_CMD: begin
            dc <= 0; // Set to 0 to signify command send

            /* 
            Load the next command, syntax used here with the minus sign after 
            the MSB tells it that we will not be placing the least significant 
            bit but instead the length
            */  
            dataToSend <= startupCommands[(commandIndex-1)-:8'd8];

            state <= STATE_SEND; // Move to next state

            /*
                set the bit number to the last bit as we saw from the datasheet 
                we are sending most significant bit first in the SPI communication
            */
            bitNumber <= 3'd7;
            cs <= 0; // Chip select set to low to tell screen we want to communicate
            commandIndex <= commandIndex - 8'd8; // Decrement command index as these bits have already been sent
        end
        STATE_SEND: begin
            if (counter == 32'd0) begin
                sclk <= 0;                      // Set SPI clock low
                sdin <= dataToSend[bitNumber];  // Set data on falling edge (per datasheet)
                counter <= 32'd1; 
            end
            else begin
                counter <= 32'd0;   // Reset the counter
                sclk <= 1;          // Pull clock high to tell screen to read the bit that we put put on din in prev. clk cycle
                if (bitNumber == 0)
                    state <= STATE_CHECK_FINISHED_INIT; // Move to next state if on the last bit
                else
                    bitNumber <= bitNumber - 1;         // Decrement bit index
            end
        end
        STATE_CHECK_FINISHED_INIT: begin
            cs <= 1; // Pull chip-select high to tell screen we are not finished.
            if (commandIndex == 0)
                state <= STATE_LOAD_DATA; // All commands sent. Can begin loading pixel data
            else
                state <= STATE_LOAD_INIT_CMD; // Load next command byte.
        end
        STATE_LOAD_DATA: begin
            pixelCounter <= pixelCounter + 1; // Increment pixelCounter to track which screen pixels
            cs <= 0; // Set to zero to re-enable screen communication
            dc <= 1; // Set to 1 to signify sending of data, not command
            bitNumber <= 3'd7; // MSB index for sending our data.
            state <= STATE_SEND; // Move to Send Data State

            // Example image
            if (pixelCounter < 136)
                // dataToSend <= 8'b01010111;
                dataToSend <= screenBuffer[pixelCounter];
            else
                dataToSend <= 0;
        end
      endcase
    end

    
endmodule
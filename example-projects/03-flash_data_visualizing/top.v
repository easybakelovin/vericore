module top #(
    parameter STARTUP_WAIT = 32'd10000000
) (
    input clk,
    input flashMiso,
    input btn1,
    input btn2,

    // ====== Out =======
    output ioSclk,
    output ioCs,
    output ioDc,
    output ioReset,
    output flashClk,
    output flashMosi,
    output flashCs
);

    // ===== Wires =====
    wire [9:0] pixelAddress;
    wire [7:0] textPixelData;
    wire [5:0] charAddress;
    wire [7:0] charOutput;

    // ===== Button Regs =====
    reg btn1Reg = 1'b1;
    reg btn2Reg = 1'b1;
    always @(negedge clk) begin
        btn1Reg <= btn1 ? 1 : 0;
        btn2Reg <= btn2 ? 1 : 0;
    end

    // ===== Screen =====
    screen #(
        .STARTUP_WAIT(STARTUP_WAIT)
    ) 
    scr (
        .clk(clk),
        .io pixelData(textPixelData)
        .io_sclk(ioSclk),
        .io_sdin(ioSdin),
        .io_cs(ioCs),
        .io_dc(ioDc),
        .io_reset(ioReset),
        .pixelAddress(pixelAddress)
    );

    // ===== Text Engine =====

    textEngine te(
        .clk(clk),
        .pixelAddress(pixelAddress),
        .charOutput(charOutput),
        .pixelData(textPixelData),
        .charAddress(charAddress)
    );

    // ===== Flash Nav ======
    flashNavigator_W25Q64 externalFlash(
        .clk(clk),
        .btn1(btn1Reg),
        .btn2(btn2Reg),
        .flashMiso(flashMiso),
        .charAddress(charAddress),
        .flashMosi(flashMosi),
        .flashCs(flashCs),
        .flashClk(flashClk),
        .charOutput(charOutput)
    );
    
endmodule
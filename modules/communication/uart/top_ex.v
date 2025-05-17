// Description: Example top module for UART communication.clk


module top_ex (
    input clk,
    input io_button1,
    input io_button2,
    input uart_rx,
    output io_led[8],
    output uart_tx,
    output led[5:0]
);
    wire [5:0] w_led;
    wire w_uart_tx;
    assign led = w_led;
    assign uart_tx = w_uart_tx;
    assign io_led[8] = io_button1;

    uart_rx RX (.clk(clk), .uart_rx(uart_rx), .led(w_led));
    uart_tx TX (.clk(clk), .reset(io_button2), .btn1(io_button1), .uart_tx(w_uart_tx));
    
endmodule
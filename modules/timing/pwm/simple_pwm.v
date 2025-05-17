`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/24/2025 08:13:39 PM
// Design Name: 
// Module Name: top_pwm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module simple_pwm (
    input wire clk,          // System clock
    input wire rst,          // Reset signal
    input wire [7:0] i_duty,   // Duty cycle (0-255 for 8-bit resolution)
    output reg o_pwm,       // PWM output signal
    output reg [7:0] counter
);


//reg [7:0] counter = 8'd0;   // Counter register
//initial counter = 8'd0;

always @(posedge clk or posedge rst) begin
    if (rst)
        counter <= 8'd0;      // Reset counter
    else if (counter == 8'd255) // Wrap back to 0 after reaching 255
        counter <= 0;
    else 
        counter <= counter + 1;  // Increment counter
    end

always @(posedge clk or posedge rst) begin
    if (rst)
        o_pwm <= 0;      // Reset PWM output
    else
        o_pwm <= (counter < i_duty) ? 1 : 0; // Compare counter with duty cycle
    end

endmodule

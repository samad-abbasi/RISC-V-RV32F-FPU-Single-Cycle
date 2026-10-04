`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.07.2026 04:56:35
// Design Name: 
// Module Name: baud_rate_generator
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

module baud_rate_generator #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 9600
)(
    input  logic clk,
    input  logic rst,
    output logic tick
);

    localparam integer MAX_COUNT = CLK_FREQ / BAUD_RATE;
    logic [31:0] counter;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 32'd0;
            tick    <= 1'b0;
        end else begin
            if (counter == MAX_COUNT - 1) begin
                counter <= 32'd0;
                tick    <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                tick    <= 1'b0;
            end
        end
    end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 02:28:43 PM
// Design Name: 
// Module Name: program_counter
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

module program_counter(
    input logic clk,
    input logic rst,
    input logic [31:0]muxin,
    output logic [31:0] count
);

always_ff @(posedge clk or posedge rst) begin
    if(rst)
        count <= 32'd0;
    else
        count <= muxin;
end

endmodule



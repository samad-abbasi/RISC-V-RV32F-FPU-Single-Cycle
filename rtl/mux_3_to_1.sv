`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/18/2026 07:19:59 PM
// Design Name: 
// Module Name: mux_3_to_1
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


module mux_3_to_1(
input logic [31:0] a,b,c,
input logic [1:0]sel, 
output logic [31:0] out3
    );
    
    always @(*) begin 
    case (sel)
    2'b00: out3 = a;
    2'b01: out3 = b;
    2'b10: out3 = c;
    default: out3 = 32'd0;
    
    endcase 
    end
    
    
    
endmodule

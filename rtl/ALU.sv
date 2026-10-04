`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 06:10:51 PM
// Design Name: 
// Module Name: ALU
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


module ALU(
input logic [31:0] in1, in2,
input logic [2:0] alu_control,
output logic [31:0] result,
output logic zero_flag);

always@(*) begin

result = 32'b0;

case(alu_control)
    3'b000: result = in1 + in2;            // ADD
    3'b001: result = in1 - in2;            // SUB
    3'b010: result = in1 & in2;            // AND
    3'b011: result = in1 | in2;            // OR
    3'b100: result = in1 ^ in2;            // XOR
    3'b101: result = in1 << in2[4:0];      // SLL
    3'b110: result = in1 >> in2[4:0];      // SRL
default: result = 32'b0;    // DEFAULT CASE
endcase
        zero_flag = (result == 32'b0) ? 1'b1 : 1'b0;
end

endmodule
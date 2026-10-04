`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.07.2026 23:32:22
// Design Name: 
// Module Name: fpu_add_sub_testbench
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


module fpu_add_sub_testbench;
logic [31:0] a, b, result;
logic        is_sub;   // 1 for fsub.s, 0 for fadd.s

fpu_add_sub uut (.*);

initial begin 
//26.875 , 67.987 -> 94.862 (HEX 42bdb958)
#10 a = 32'h41d70000; b = 32'h4287f958; is_sub = 1'b0;

//23.125 - 12.6875 -> 10.4375 (HEX: 41270000)
#10 a = 32'h41b90000; b = 32'h414b0000; is_sub = 1'b1;

//23.125 +  (-12.6875) -> 10.4375 (HEX: 41270000)
#10 a = 32'h41b90000; b = 32'hc14b0000; is_sub = 1'b0;

//-67.981244141 - 17.433521 -> -85.414764 (HEX: c2aad45c)
#10 a = 32'hc287f666; b = 32'hc18b77da; is_sub = 1'b0;
#10
$finish;




end 

endmodule

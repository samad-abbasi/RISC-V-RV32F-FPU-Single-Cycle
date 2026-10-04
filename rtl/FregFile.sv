`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.07.2026 18:44:43
// Design Name: 
// Module Name: FregFile
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

module fRegFile(
  input  logic [4:0]  read_reg_num1, read_reg_num2,
  input  logic [4:0]  write_reg,
  input  logic [31:0] write_data,
  output logic [31:0] read_data1, read_data2,
  input  logic        regwrite,
  input  logic        clock, reset
);
  logic [31:0] fp_mem [31:0];
  integer i;
  always @(posedge clock or posedge reset) begin
    if (reset) 
        for (i=0;i<32;i=i+1) 
            fp_mem[i] <= 32'd0;
    else if (regwrite) 
        fp_mem[write_reg] <= write_data;
  end
  
  assign read_data1 = fp_mem[read_reg_num1];
  assign read_data2 = fp_mem[read_reg_num2];
endmodule
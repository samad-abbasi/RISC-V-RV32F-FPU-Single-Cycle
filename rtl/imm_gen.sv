`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2026 02:32:59 PM
// Design Name: 
// Module Name: imm_gen
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

module imm_gen(
input logic [31:0] instruction, 
output logic [31:0] imm_out
    );
    
    parameter [6:0] load_opcode   = 7'b0000011, 
                    store_opcode  = 7'b0100011, 
                    branch_opcode = 7'b1100011,
                    JAL_OPCODE    = 7'b1101111,
                    flw_opcode    = 7'b0000111, 
                    fsw_opcode    = 7'b0100111;

    logic [6:0] opcode;
    assign opcode = instruction [6:0];
    
    logic [11:0] load_imm, store_imm;
    logic [12:0] branch_imm;
    logic [20:0] jal_im;
           
    
    assign load_imm = instruction[31:20];
    assign store_imm = {instruction[31:25], instruction[11:7]};
    assign branch_imm = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    assign jal_im = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
   
    always @(*) begin 
    case (opcode)
    load_opcode:
        imm_out = {{20{load_imm[11]}}, load_imm};
    
    store_opcode: 
        imm_out = {{20{store_imm[11]}}, store_imm};
    
    branch_opcode: 
        imm_out = {{19{branch_imm[12]}}, branch_imm};

    JAL_OPCODE:
        imm_out = {{11{jal_im[20]}}, jal_im};
     
     flw_opcode: 
        imm_out = {{20{load_imm[11]}}, load_imm};
        
     fsw_opcode: 
        imm_out = {{20{store_imm[11]}}, store_imm};
       
     7'b0010011: begin   
         imm_out = {{20{load_imm[11]}}, load_imm};
     end

    default: imm_out = 32'b0; 
    endcase
    end
    
    
    
    
    
    
endmodule
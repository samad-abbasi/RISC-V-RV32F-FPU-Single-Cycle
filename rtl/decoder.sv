`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 03:44:46 PM
// Design Name: 
// Module Name: reg_file
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


module decoder(
    input logic [31:0] instruction, 
    output logic [2:0] func3, 
    output logic [6:0] func7, 
    output logic [4:0] rs1, rs2, rd,
    output logic [11:0] imm
    );
    
    parameter r_type = 7'b0110011, //add, sub , and , or 
              s_type = 7'b0100011, //sw
              i_type = 7'b0000011, //lw
              b_type = 7'b1100011; //beq
              
    logic [6:0] opcode;
    assign opcode = instruction[6:0];
    
    always @(*) begin
        
        case (opcode)
        r_type: begin 
            rd = instruction[11:7];
            func3 = instruction[14:12];
            rs1 = instruction[19:15];
            rs2 = instruction[24:20];
            func7 = instruction[31:25];
        end
        
        s_type: begin 
            imm[4:0] =  instruction[11:7];
            imm[11:5] =  instruction[31:25];
            func3 = instruction[14:12];
            rs1 = instruction[19:15];
            rs2 = instruction[24:20]; 
            rd = 5'bx;
            func7 = 7'bx;
            
        end


        i_type: begin
            rd = instruction[11:7];
            func3 = instruction[14:12];
            rs1 = instruction[19:15];
            imm[11:5] =  instruction[31:25];
            rs2 = 5'bx;
            func7 = 7'bx;
        end
                

        
        b_type: begin 
            imm[3:0] =  instruction[11:8];
            imm[9:4] =  instruction[30:25];
            imm[10] =  instruction[7];
            imm[11] =  instruction[31];

            func3 = instruction[14:12];
            rs1 = instruction[19:15];
            rs2 = instruction[24:20]; 
            rd = 5'bx;
            func7 = 7'bx;           
            
        end

        
        
        endcase
        
    end
    
    
    
    
    
    
    
    
endmodule

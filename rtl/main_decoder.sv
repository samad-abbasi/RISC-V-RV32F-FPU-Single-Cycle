`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2026 03:32:56 PM
// Design Name: 
// Module Name: main_decoder
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


module main_decoder(
    input  logic [6:0] Op,
    input  logic [2:0] func3,
    input  logic       func7_5,
    output logic       RegWrite,
    output logic       ALUSrc,
    output logic       MemWrite,
    output logic       MemRead,
    output logic [1:0] ResultSrc,
    output logic       Branch,
    output logic [2:0] ALUcontrol,
    output logic [1:0] ALUOp,
    output logic       Jump, 
    // New signals for FPU 
    output logic       FPRegWrite, 
    output logic       IsFPLoad, 
    output logic       IsFPStore 
);

    always @(*) begin
        // --- FIX: DEFAULT ASSIGNMENTS ---
        // Setting default states here prevents inferred latches and 'X' propagation.
        // These defaults will be overridden by the specific case statements below.
        RegWrite   = 1'b0;
        ALUSrc     = 1'b0;
        MemWrite   = 1'b0;
        MemRead    = 1'b0;
        ResultSrc  = 2'b00;
        Branch     = 1'b0;
        ALUOp      = 2'b00;
        Jump       = 1'b0;
        FPRegWrite = 1'b0;
        IsFPLoad   = 1'b0;
        IsFPStore  = 1'b0;

        case(Op)
            // lw instruction
            7'b0000011: begin
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1;
                ResultSrc = 2'b01; 
            end

            // sw instruction
            7'b0100011: begin
                ALUSrc    = 1'b1;
                MemWrite  = 1'b1;
            end

            // R-type instruction
            7'b0110011: begin
                RegWrite  = 1'b1;
                ALUOp     = 2'b10;
            end

            // beq instruction
            7'b1100011: begin
                Branch    = 1'b1;
                ALUOp     = 2'b01;
            end

            // jal instruction (J-Type)
            7'b1101111: begin
                RegWrite  = 1'b1;     
                ResultSrc = 2'b10;    
                Jump      = 1'b1;     
            end
            
            // addi, andi, ori, etc.
            7'b0010011: begin   
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1;
            end
            
            // --- FPU Opcodes ---
            
            // flw 
            7'b0000111: begin 
                ALUSrc     = 1'b1;
                FPRegWrite = 1'b1;
                IsFPLoad   = 1'b1;
                ResultSrc  = 2'b01;
            end

            // fsw 
            7'b0100111: begin 
                ALUSrc     = 1'b1; 
                MemWrite   = 1'b1; 
                IsFPStore  = 1'b1;
            end

            // fadd / fsub
            7'b1010011: begin 
                FPRegWrite = 1'b1;
            end

            default: begin
                // Defaults are already handled at the top of the block
            end
        endcase
    end

    parameter   ALU_ADD = 3'b000, 
                ALU_SUB = 3'b001, 
                ALU_AND = 3'b010, 
                ALU_OR  = 3'b011, 
                ALU_XOR = 3'b100, 
                ALU_SLL = 3'b101, 
                ALU_SRL = 3'b110;

    always_comb begin
        case (ALUOp)
            2'b00: ALUcontrol = ALU_ADD; 
            2'b01: ALUcontrol = ALU_SUB; 
            
            2'b10: begin
                case (func3)
                    3'b000:  ALUcontrol = func7_5 ? ALU_SUB : ALU_ADD; 
                    3'b001:  ALUcontrol = ALU_SLL;                      
                    3'b100:  ALUcontrol = ALU_XOR;                      
                    3'b101:  ALUcontrol = ALU_SRL;                      
                    3'b110:  ALUcontrol = ALU_OR;                       
                    3'b111:  ALUcontrol = ALU_AND;                      
                    default: ALUcontrol = ALU_ADD;
                endcase
            end
            default: ALUcontrol = ALU_ADD;
        endcase
    end
    
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2026 04:21:48 PM
// Design Name: 
// Module Name: top
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


module top(
    input logic rst,
    input logic clk,
    output logic [31:0] monitor_data,
    output logic        monitor_valid
);

logic [31:0] count_pc;
logic [31:0] instruction;
logic [31:0] pc_adder;
logic [31:0] branch_adder;
logic [31:0] mux1_out;

logic [31:0] imm_out;

logic [31:0] read_data1;
logic [31:0] read_data2;

logic [31:0] alu_in2;
logic [31:0] alu_result;
logic         zero_flag;

logic [31:0] mem_data;

logic [31:0] write_back;

// wires for main decoder output
logic       RegWrite;
logic       ALUSrc;
logic       MemWrite;
logic       MemRead;
logic [1:0] ResultSrc;
logic       Branch;
logic [2:0] ALUcontrol;
logic [1:0] ALUOp;

logic PCSrc;
logic jump;
logic [31:0] fp_write_back, fp_read_data1, fp_read_data2, fp_result, mem_data_in;


logic FPRegWrite, IsFPLoad, IsFPStore; 


// --- feq.s support (added, no changes to main_decoder needed) ---
    wire is_fp_compare = (instruction[6:0] == 7'b1010011) && instruction[31]; 
    // instruction[31] = funct7[6]; fadd/fsub have funct7[6]=0, the compare family (feq/flt/fle) has funct7[6]=1
    
    wire fp_equal = (fp_read_data1 == fp_read_data2);
    wire [31:0] fcompare_result = {31'b0, fp_equal};
    
    wire int_regwrite_final = RegWrite | is_fp_compare;      // feq.s must write the int regfile
    wire fp_regwrite_final  = FPRegWrite & ~is_fp_compare;    // ...and must NOT write the float regfile
    wire [31:0] int_write_back_final = is_fp_compare ? fcompare_result : write_back;



logic [31:0] pc_plus4;
// Branch target address
adder_32_bit first_adder_out(
    .A(count_pc),
    .B(32'd4),
    .sum(pc_plus4)
);

program_counter uut(
    .clk(clk),
    .rst(rst),
    .muxin(mux1_out),
    .count(count_pc)
);

// Next PC mux
mux_2_to_1 uut10(
    .A(pc_plus4),
    .B(branch_adder),
    .sel(PCSrc),
    .out(mux1_out)
);

// Branch target address
adder_32_bit uut9(
    .A(count_pc),
    .B(imm_out),
    .sum(branch_adder)
);

// Instruction Memory
inst_mem uut1(
    .pc(count_pc),
    .instruction_code(instruction)
);

// Main Decoder


main_decoder uut4(
    .Op(instruction[6:0]),
    .func3(instruction[14:12]),
    .func7_5(instruction[30]),
    .RegWrite(RegWrite),
    .ALUSrc(ALUSrc),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .ResultSrc(ResultSrc),
    .Branch(Branch),
    .ALUcontrol(ALUcontrol),
    .ALUOp(ALUOp),
    .Jump(jump),
    .FPRegWrite(FPRegWrite), 
    .IsFPLoad(IsFPLoad), 
    .IsFPStore(IsFPStore)
    
    
);

// ALU input mux
assign alu_in2 = (ALUSrc) ? imm_out : read_data2; //1 -> imm_out, 0 -> readData2

// ALU
ALU uut7(
    .in1(read_data1),
    .in2(alu_in2),
    .alu_control(ALUcontrol),
    .result(alu_result),
    .zero_flag(zero_flag)
);
 
// Branch decision
assign PCSrc = jump | (Branch & zero_flag);

// Register File
reg_file uut5(
    .read_reg_num1(instruction[19:15]),
    .read_reg_num2(instruction[24:20]),
    .write_reg(instruction[11:7]),
    .write_data(int_write_back_final),   // <-- was write_back
    .read_data1(read_data1),
    .read_data2(read_data2),
    .regwrite(int_regwrite_final),        // <-- was RegWrite
    .clock(clk),
    .reset(rst)
);

// Immediate Generator
imm_gen uut6(
    .instruction(instruction),
    .imm_out(imm_out)
);

// Data Memory
data_mem uut8(
    .clk(clk),
    .mem_write(MemWrite),
    .address(alu_result[9:2]),
    .data_in(mem_data_in),
    .data_out(mem_data)
);

// Write-back mux
mux_3_to_1 uut12 (.a(alu_result), .b(mem_data), .c(pc_plus4), .out3(write_back), .sel(ResultSrc));


fRegFile fp_regs(
  .read_reg_num1(instruction[19:15]),   // rs1 field (only meaningful for fadd/fsub)
  .read_reg_num2(instruction[24:20]),   // rs2 field (fadd/fsub source, or fsw data source)
  .write_reg(instruction[11:7]),
  .write_data(fp_write_back),
  .read_data1(fp_read_data1),
  .read_data2(fp_read_data2),
  .regwrite(fp_regwrite_final),          // <-- was FPRegWrite
  .clock(clk), .reset(rst)
);

logic [31:0] fp_add_sub_result;

fpu_add_sub fpu(
  .a(fp_read_data1), .b(fp_read_data2),
  .is_sub(instruction[27]),   // funct7 bit 2, only valid for OP-FP but harmless otherwise
  .result(fp_add_sub_result)
);

//logic for fmul, fdiv
logic [31:0] fp_mul_result, fp_div_result;

fpu_mul fpu_m(
  .a(fp_read_data1), .b(fp_read_data2),
  .result(fp_mul_result)
);

fpu_div fpu_d(
  .a(fp_read_data1), .b(fp_read_data2),
  .result(fp_div_result)
);

// fp_op selects which FPU operation feeds fp_result, decoded straight from
// funct7[3:2] (instruction[28:27]) the same way is_sub already reads funct7[2]:
//   00 = fadd.s   01 = fsub.s   10 = fmul.s   11 = fdiv.s
logic [1:0] fp_op;

always_comb begin
    case (instruction[28:27])
        2'b10:   fp_result = fp_mul_result;
        2'b11:   fp_result = fp_div_result;
        default: fp_result = fp_add_sub_result; // 00 = add, 01 = sub
    endcase
end


mux_2_to_1 fp_wb_mux(.A(fp_result), .B(mem_data), .sel(IsFPLoad), .out(fp_write_back));
mux_2_to_1 mem_data_in_mux(.A(read_data2), .B(fp_read_data2), .sel(IsFPStore), .out(mem_data_in));


// --- NEW UART MONITORING MUX ---
localparam [6:0] OP_R   = 7'b0110011;
localparam [6:0] OP_I   = 7'b0010011;
localparam [6:0] OP_S   = 7'b0100011;
localparam [6:0] OP_FP  = 7'b1010011; // fadd.s, fsub.s, feq.s
localparam [6:0] OP_FLW = 7'b0000111;
localparam [6:0] OP_FSW = 7'b0100111;
localparam [6:0] OP_LW  = 7'b0000011;
localparam [6:0] OP_B = 7'b1100011; //branch 
localparam [6:0] OP_J = 7'b1101111; //jal 


logic [31:0] monitor_data_reg;
assign monitor_data = monitor_data_reg;

// 2. Register the data on the clock edge
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        monitor_valid <= 1'b0;
        monitor_data_reg <= 32'h0;
    end else begin
        // Use the same MUX logic you already wrote, but capture it on the clock
        monitor_valid <= 1'b1;
        case (instruction[6:0])
            OP_R, OP_I: monitor_data_reg <= write_back;
            OP_S:       monitor_data_reg <= read_data2;
            OP_FP: begin       
                if (instruction[31:25] == 7'b1010000)
                    monitor_data_reg <= {31'b0, write_back[4]};// feq
                else 
                    monitor_data_reg <= fp_write_back; //fadd, fsub
            end
            OP_FLW:     monitor_data_reg <= fp_write_back;
            OP_FSW:     monitor_data_reg <= fp_read_data2;
            OP_LW:      monitor_data_reg <= write_back;
            OP_B:       monitor_data_reg <= {31'b0, zero_flag};   // 1 = branch was taken
            OP_J:       monitor_data_reg <= int_write_back_final; // link address
            default: begin 
                monitor_data_reg <= 32'h0;
                monitor_valid <= 1'b0;

            end       
        endcase
    end
end








endmodule
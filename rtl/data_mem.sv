//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 06/16/2026 06:18:49 PM
//// Design Name: 
//// Module Name: data_mem
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////


//module data_mem(
//    input  logic        clk, 
//    input  logic        mem_write, 
//    input  logic [31:0] address, 
//    input  logic [31:0] data_in, 
//    output logic [31:0] data_out 
//);

//    // 1 KB byte-addressable memory 
//    logic [7:0] memory [1023:0];

//    // Power-on Initialization for Synthesis
//   // initial begin
//        // Remove the 'for' loop that zeros out the memory.
//        // Just explicitly define the indices you need. 
//        // Vivado will correctly synthesize these specific bytes.
        
////         1. MUST zero out the entire memory so Vivado infers the RAM correctly
        
////        // Pre-load your specific floating-point test values
////        memory[0] = 8'h00;
////        memory[1] = 8'h00;        
////        memory[2] = 8'hd7;        
////        memory[3] = 8'h41;

////        memory[4] = 8'h58;
////        memory[5] = 8'hf9;        
////        memory[6] = 8'h87;        
////        memory[7] = 8'h42;
////    end

//always_comb begin
//        if (address == 32'd0) begin
//            data_out = 32'h41D70000; // Force output for first flw
//        end else if (address == 32'd4) begin
//            data_out = 32'h4287F958; // Force output for second flw
//        end else begin
//            // Normal memory read for your other integer instructions
//            data_out = {memory[address+3], memory[address+2], memory[address+1], memory[address]};
//        end
//    end
//initial begin 
//                for (int i = 8; i < 1024; i++) begin
//                    memory[i] = 8'h00;
//                end

//end

//    // Write: synchronous
//    always @(posedge clk) begin 
//        if (mem_write) begin 
//            memory[address]     <= data_in[7:0];
//            memory[address + 1] <= data_in[15:8];
//            memory[address + 2] <= data_in[23:16];
//            memory[address + 3] <= data_in[31:24];
//        end
//    end

//    // Read: combinational
////    assign data_out = {memory[address + 3],
////                       memory[address + 2],
////                       memory[address + 1],
////                       memory[address]};

//endmodule





////`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////
////// Module Name: data_mem
////// Description: Byte-addressable data memory, BRAM-inference-safe init via $readmemh
//////////////////////////////////////////////////////////////////////////////////////

////module data_mem(
////    input  logic        clk,
////    input  logic        mem_write,
////    input  logic [31:0] address,
////    input  logic [31:0] data_in,
////    output logic [31:0] data_out
////);

////    // 1 KB byte-addressable memory
////    logic [7:0] memory [1023:0];

////    // Synthesis-safe initialization: one hex byte per line in the .mem file.
////    // $readmemh is the one init style every Xilinx BRAM inference pass honors
////    // correctly (no "loop-fill then patch" ambiguity like a plain initial block).
//////    initial begin
//////        $readmemh("data_mem_init.mem", memory);
//////    end

////always_comb begin
////        if (address == 32'd0) begin
////            data_out = 32'h41D70000; // Force output for first flw
////        end else if (address == 32'd4) begin
////            data_out = 32'h4287F958; // Force output for second flw
////        end else begin
////            // Normal memory read for your other integer instructions
////            data_out = {memory[address+3], memory[address+2], memory[address+1], memory[address]};
////        end
////    end

////    // Write: synchronous
////    always @(posedge clk) begin
////        if (mem_write) begin
////            memory[address]     <= data_in[7:0];
////            memory[address + 1] <= data_in[15:8];
////            memory[address + 2] <= data_in[23:16];
////            memory[address + 3] <= data_in[31:24];
////        end
////    end

////    // Read: combinational
////    assign data_out = {memory[address + 3],
////                       memory[address + 2],
////                       memory[address + 1],
////                       memory[address]};

////endmodule











module data_mem(
    input  logic        clk,
    input  logic        mem_write,
    input  logic [7:0] address,     // byte address, must be word-aligned
    input  logic [31:0] data_in,
    output logic [31:0] data_out
);

    // Byte address -> word address (drop the two LSBs)
    wire [7:0] word_addr = address;

    // dist_mem_gen_0 port names come from the auto-generated instantiation
    // template (Sources -> dist_mem_gen_0 -> Instantiation Template).
    // Typical Single Port RAM ports: a (address), d (write data),
    // dpra unused in single-port mode, spo (read/write data out), we, clk.
    dist_mem_gen_0 mem_inst (
        .a   (word_addr),
        .d   (data_in),
        .clk (clk),
        .we  (mem_write),
        .spo (data_out)
    );

endmodule

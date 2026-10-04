
`timescale 1ns / 1ps

module inst_mem (
    input  logic [31:0] pc,
    output logic [31:0] instruction_code
);
    logic [7:0] Memory [0:1023];

    initial begin
        for (int i = 0; i < 1024; i = i + 1) begin
            Memory[i] = 8'h00;
        end
        
        $readmemh("inst_mem.mem", Memory);
    end

    assign instruction_code = {Memory[pc+3], Memory[pc+2], Memory[pc+1], Memory[pc]};

endmodule
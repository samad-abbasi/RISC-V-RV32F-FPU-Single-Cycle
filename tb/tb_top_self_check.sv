`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// tb_top_self_check
//
// Self-checking testbench for the `top` module.
// Now updated to include fmul.s and fdiv.s verification.
//////////////////////////////////////////////////////////////////////////////////

module tb_top_self_check;

    // ---- Signals ----
    logic        clk;
    logic        rst;
    logic [31:0] monitor_data;
    logic        monitor_valid;

    // ---- DUT ----
    top dut (
        .clk           (clk),
        .rst           (rst),
        .monitor_data  (monitor_data),
        .monitor_valid (monitor_valid)
    );

    // ---- Clock: 10ns period ----
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---- Expected dynamic execution trace (27 steps) ----
    localparam int NUM_CHECKS = 27;

    logic [31:0] expected         [0:NUM_CHECKS-1];
    string       description      [0:NUM_CHECKS-1];
    logic [31:0] expected_pc      [0:NUM_CHECKS-1];
    logic [31:0] expected_next_pc [0:NUM_CHECKS-1];

    initial begin
        expected[ 0] = 32'd5;          expected_pc[ 0] = 32'd0;    expected_next_pc[ 0] = 32'd4;
        description[ 0] = "addi x1,x0,5            -> x1=5";

        expected[ 1] = 32'd3;          expected_pc[ 1] = 32'd4;    expected_next_pc[ 1] = 32'd8;
        description[ 1] = "addi x2,x0,3            -> x2=3";

        expected[ 2] = 32'd8;          expected_pc[ 2] = 32'd8;    expected_next_pc[ 2] = 32'd12;
        description[ 2] = "add  x3,x1,x2           -> x3=8";

        expected[ 3] = 32'd2;          expected_pc[ 3] = 32'd12;   expected_next_pc[ 3] = 32'd16;
        description[ 3] = "sub  x4,x1,x2           -> x4=2";

        expected[ 4] = 32'd1;          expected_pc[ 4] = 32'd16;   expected_next_pc[ 4] = 32'd20;
        description[ 4] = "and  x5,x1,x2           -> x5=1";

        expected[ 5] = 32'd7;          expected_pc[ 5] = 32'd20;   expected_next_pc[ 5] = 32'd24;
        description[ 5] = "or   x6,x1,x2           -> x6=7";

        expected[ 6] = 32'd6;          expected_pc[ 6] = 32'd24;   expected_next_pc[ 6] = 32'd28;
        description[ 6] = "xor  x14,x1,x2          -> x14=6";

        expected[ 7] = 32'd40;         expected_pc[ 7] = 32'd28;   expected_next_pc[ 7] = 32'd32;
        description[ 7] = "sll  x15,x1,x2          -> x15=5<<3=40";

        expected[ 8] = 32'd0;          expected_pc[ 8] = 32'd32;   expected_next_pc[ 8] = 32'd36;
        description[ 8] = "srl  x16,x1,x2          -> x16=5>>3=0";

        expected[ 9] = 32'd8;          expected_pc[ 9] = 32'd36;   expected_next_pc[ 9] = 32'd40;
        description[ 9] = "sw   x3,40(x0)          -> stores x3=8";

        expected[10] = 32'd8;          expected_pc[10] = 32'd40;   expected_next_pc[10] = 32'd44;
        description[10] = "lw   x7,40(x0)          -> x7=8";

        expected[11] = 32'd0;          expected_pc[11] = 32'd44;   expected_next_pc[11] = 32'd48;
        description[11] = "beq  x1,x2,+8           -> NOT taken, falls through";

        expected[12] = 32'd111;        expected_pc[12] = 32'd48;   expected_next_pc[12] = 32'd52;
        description[12] = "addi x10,x0,111         -> proves branch fell through";

        expected[13] = 32'd1;          expected_pc[13] = 32'd52;   expected_next_pc[13] = 32'd60;
        description[13] = "beq  x3,x7,+8           -> TAKEN, jumps to 60";

        expected[14] = 32'd222;        expected_pc[14] = 32'd60;   expected_next_pc[14] = 32'd64;
        description[14] = "addi x10,x0,222         -> @56 skipped";

        expected[15] = 32'd68;         expected_pc[15] = 32'd64;   expected_next_pc[15] = 32'd72;
        description[15] = "jal  x6,+8              -> link 68, jumps to 72";

        expected[16] = 32'd77;         expected_pc[16] = 32'd72;   expected_next_pc[16] = 32'd76;
        description[16] = "addi x12,x0,77          -> @68 skipped";

        expected[17] = 32'h41d70000;   expected_pc[17] = 32'd76;   expected_next_pc[17] = 32'd80;
        description[17] = "flw  f1,0(x0)           -> f1=26.875";

        expected[18] = 32'h4287f958;   expected_pc[18] = 32'd80;   expected_next_pc[18] = 32'd84;
        description[18] = "flw  f2,4(x0)           -> f2=67.987";

        expected[19] = 32'h42bdb958;   expected_pc[19] = 32'd84;   expected_next_pc[19] = 32'd88;
        description[19] = "fadd.s f3,f1,f2         -> f3=94.862";

        expected[20] = 32'h422472b0;   expected_pc[20] = 32'd88;   expected_next_pc[20] = 32'd92;
        description[20] = "fsub.s f4,f2,f1         -> f4=41.112";

        expected[21] = 32'h42bdb958;   expected_pc[21] = 32'd92;   expected_next_pc[21] = 32'd96;
        description[21] = "fsw  f3,8(x0)           -> stores f3";

        expected[22] = 32'h42bdb958;   expected_pc[22] = 32'd96;   expected_next_pc[22] = 32'd100;
        description[22] = "lw   x13,8(x0)          -> reads f3 bits via INT path";

        expected[23] = 32'd1;          expected_pc[23] = 32'd100;  expected_next_pc[23] = 32'd104;
        description[23] = "feq.s x9,f3,f3          -> equal -> 1";

        expected[24] = 32'd0;          expected_pc[24] = 32'd104;  expected_next_pc[24] = 32'd108;
        description[24] = "feq.s x8,f3,f4          -> not equal -> 0";

        expected[25] = 32'h44e464d2;   expected_pc[25] = 32'd108;  expected_next_pc[25] = 32'd112;
        description[25] = "fmul.s f5,f1,f2         -> f5=1827.15";

        expected[26] = 32'h4021e768;   expected_pc[26] = 32'd112;  expected_next_pc[26] = 32'd116;
        description[26] = "fdiv.s f6,f2,f1         -> f6=2.5297";
    end

    // ---- Bookkeeping ----
    int pass_count = 0;
    int fail_count = 0;
    int i;
    
    logic [31:0] pc_before;
    logic [31:0] pc_after;
    logic        data_ok;
    logic        pc_ok;

    // ---- Watchdog ----
    initial begin
        #5000;
        if (i < NUM_CHECKS) begin
            $display("\n*** WATCHDOG TIMEOUT: only %0d/%0d checks completed. ***", i, NUM_CHECKS);
            $finish;
        end
    end

    // ---- Main check sequence & FORMATTED OUTPUT LOGIC ----
    initial begin
        // Clean table header
        $display("===============================================================================================================");
        $display(" tb_top_self_check : RISC-V Execution Trace Verification");
        $display("===============================================================================================================");
        $display(" STATUS | STEP |  PC JUMP   |   ACTUAL   |  EXPECTED  | INSTRUCTION / OPERATION EXECUTED");
        $display("--------+------+------------+------------+------------+--------------------------------------------------------");

        rst = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        pc_before = 32'd0; 

        for (i = 0; i < NUM_CHECKS; i = i + 1) begin
            @(posedge clk);
            #1; // Settling time

            pc_after = dut.count_pc;

            data_ok = monitor_valid && (monitor_data === expected[i]);
            pc_ok   = (pc_before == expected_pc[i]) && (pc_after == expected_next_pc[i]);

            // Formatted Column Output
            if (data_ok && pc_ok) begin
                $display(" [PASS] |  %02d  | %3d -> %3d | 0x%08h | 0x%08h | %s",
                          i, pc_before, pc_after, monitor_data, expected[i], description[i]);
                pass_count = pass_count + 1;
            end else begin
                $display(" [FAIL] |  %02d  | %3d -> %3d | 0x%08h | 0x%08h | %s",
                          i, pc_before, pc_after, monitor_data, expected[i], description[i]);
                
                // Detailed error breakdown printed directly beneath the failing row
                if (!monitor_valid)
                    $display("        |      |            |  <INVALID> |            | ^ ERROR: monitor_valid was LOW!");
                else if (monitor_data !== expected[i])
                    $display("        |      |            | ^ MISMATCH | ^ EXPECTED | ^ ERROR: Data Mismatch");
                    
                if (!pc_ok)
                    $display("        |      | EXP:%3d->%3d |            |            | ^ ERROR: PC Transition Mismatch", 
                              expected_pc[i], expected_next_pc[i]);
                              
                fail_count = fail_count + 1;
            end

            pc_before = pc_after;
        end

        // Clean summary footer
        $display("===============================================================================================================");
        if (fail_count == 0) begin
            $display(" SIMULATION RESULT: ALL %0d CHECKS PASSED SUCCESSFULLY", pass_count);
        end else begin
            $display(" SIMULATION RESULT: %0d PASSED, %0d FAILED out of %0d", pass_count, fail_count, NUM_CHECKS);
        end
        $display("===============================================================================================================");

        $finish;
    end

endmodule
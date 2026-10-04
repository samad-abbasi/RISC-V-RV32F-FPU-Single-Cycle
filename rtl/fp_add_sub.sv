`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.07.2026 18:48:07
// Design Name: 
// Module Name: fp_add_sub
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

module fpu_add_sub (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic        is_sub,   // 1 for fsub.s, 0 for fadd.s
    output logic [31:0] result
);
    // Unpacked IEEE-754 fields
    logic        sign_a, sign_b, sign_res;
    logic [7:0]  exp_a, exp_b, exp_res;
    logic [22:0] mant_a, mant_b, mant_res;

    assign sign_a = a[31];
    assign exp_a  = a[30:23];
    assign mant_a = a[22:0];

    assign sign_b = b[31] ^ is_sub; // Invert sign if subtraction
    assign exp_b  = b[30:23];
    assign mant_b = b[22:0];

    // Simple zero detection
    logic a_is_zero, b_is_zero;
    assign a_is_zero = (exp_a == 8'h0) && (mant_a == 23'h0);
    assign b_is_zero = (exp_b == 8'h0) && (mant_b == 23'h0);

    // Append implicit bit: 1 for normal numbers, 0 for zero/subnormal
    logic [23:0] mant_a_ext, mant_b_ext;
    assign mant_a_ext = (exp_a == 8'h0) ? {1'b0, mant_a} : {1'b1, mant_a};
    assign mant_b_ext = (exp_b == 8'h0) ? {1'b0, mant_b} : {1'b1, mant_b};

    // Internal intermediate alignment data paths (24-bit mantissa + G, R, S bits = 27 bits)
    logic [7:0]  exp_diff;
    logic [26:0] mant_a_align, mant_b_align; 
    logic [27:0] sum_mant; // Extra bit for addition overflow carry
    logic        sub_op;
    logic g, r, s, round_up;

    assign sub_op = sign_a ^ sign_b;

    always_comb begin
        // --- 1. Exponent Alignment ---
        if (exp_a >= exp_b) begin
            exp_diff = exp_a - exp_b;
            exp_res  = exp_a;
            mant_a_align = {mant_a_ext, 3'b000};
            if (exp_diff >= 8'd26) begin
                mant_b_align = {26'h0, |mant_b_ext}; // Shifted entirely out into sticky bit
            end else begin
                mant_b_align = {mant_b_ext, 3'b000} >> exp_diff;
                if (exp_diff > 0) begin
                    // Recover accurate sticky information from dropped bits
                    mant_b_align[0] = mant_b_align[0] | (|({mant_b_ext, 3'b000} & ~(28'hFFFFFFF << exp_diff)));
                end
            end
        end else begin
            exp_diff = exp_b - exp_a;
            exp_res  = exp_b;
            mant_b_align = {mant_b_ext, 3'b000};
            if (exp_diff >= 8'd26) begin
                mant_a_align = {26'h0, |mant_a_ext};
            end else begin
                mant_a_align = {mant_a_ext, 3'b000} >> exp_diff;
                if (exp_diff > 0) begin
                    mant_a_align[0] = mant_a_align[0] | (|({mant_a_ext, 3'b000} & ~(28'hFFFFFFF << exp_diff)));
                end
            end
        end

        // --- 2. Absolute Magnitude Arithmetic ---
        if (!sub_op) begin
            sum_mant = mant_a_align + mant_b_align;
            sign_res = sign_a;
        end else begin
            if (mant_a_align >= mant_b_align) begin
                sum_mant = mant_a_align - mant_b_align;
                sign_res = sign_a;
            end else begin
                sum_mant = mant_b_align - mant_a_align;
                sign_res = sign_b;
            end
        end

        // --- 3. Normalization ---
        if (sum_mant == 28'h0) begin
            result = 32'h0; // Total cancellation yields positive zero
        end else if (a_is_zero) begin
            result = {sign_b, exp_b, mant_b};
        end else if (b_is_zero) begin
            result = {sign_a, exp_a, mant_a};
        end else begin
            // Handling Carry Out (Bit 27 is populated)
            if (sum_mant[27]) begin
                sum_mant = {1'b0, sum_mant[27:1]} | sum_mant[0]; // Maintain compressed sticky bit
                exp_res  = exp_res + 1'b1;
            end else begin
                // Cancellation correction (Shift left until hidden bit matches 1 at index 26)
                integer shift_amt;
                shift_amt = 0;
                if (sum_mant[26] == 1'b0) begin
                    if      (sum_mant[25]) shift_amt = 1;
                    else if (sum_mant[24]) shift_amt = 2;
                    else if (sum_mant[23]) shift_amt = 3;
                    else if (sum_mant[22]) shift_amt = 4;
                    else if (sum_mant[21]) shift_amt = 5;
                    else if (sum_mant[20]) shift_amt = 6;
                    else if (sum_mant[19]) shift_amt = 7;
                    else if (sum_mant[18]) shift_amt = 8;
                    else if (sum_mant[17]) shift_amt = 9;
                    else if (sum_mant[16]) shift_amt = 10;
                    else if (sum_mant[15]) shift_amt = 11;
                    else if (sum_mant[14]) shift_amt = 12;
                    else if (sum_mant[13]) shift_amt = 13;
                    else if (sum_mant[12]) shift_amt = 14;
                    else if (sum_mant[11]) shift_amt = 15;
                    else if (sum_mant[10]) shift_amt = 16;
                    else if (sum_mant[9])  shift_amt = 17;
                    else if (sum_mant[8])  shift_amt = 18;
                    else if (sum_mant[7])  shift_amt = 19;
                    else if (sum_mant[6])  shift_amt = 20;
                    else if (sum_mant[5])  shift_amt = 21;
                    else if (sum_mant[4])  shift_amt = 22;
                    else if (sum_mant[3])  shift_amt = 23;
                    else if (sum_mant[2])  shift_amt = 24;
                    else if (sum_mant[1])  shift_amt = 25;
                    else if (sum_mant[0])  shift_amt = 26;
                    
                    sum_mant = sum_mant << shift_amt;
                    if (exp_res >= shift_amt) begin
                        exp_res = exp_res - shift_amt;
                    end else begin
                        exp_res = 8'h0; // Flush to zero / Underflow bound
                    end
                end
            end

            // --- 4. Round-to-Nearest-Even (RNE) ---
            // Extract Guard (bit 2), Round (bit 1), Sticky (bit 0)
            g = sum_mant[2];
            r = sum_mant[1];
            s = sum_mant[0];
            
            // Round up condition including tie-to-even tracking
            round_up = g && (r || s || sum_mant[3]);
            
            if (round_up) begin
                sum_mant[26:3] = sum_mant[26:3] + 1'b1;
                if (sum_mant[27]) begin // Post-rounding overflow check
                    sum_mant[26:3] = {1'b1, sum_mant[26:4]};
                    exp_res = exp_res + 1'b1;
                end
            end

            mant_res = sum_mant[25:3];
            
            // Saturation limit verification (Overflowing directly to infinity)
            if (exp_res >= 8'hFF) begin
                result = {sign_res, 8'hFF, 23'h0}; 
            end else begin
                result = {sign_res, exp_res, mant_res};
            end
        end
    end
endmodule
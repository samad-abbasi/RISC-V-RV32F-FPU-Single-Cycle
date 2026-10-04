`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.07.2026 18:10:53
// Design Name: 
// Module Name: fpu_div
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

module fpu_div (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result
);
    logic        sign_a, sign_b, sign_res;
    logic [7:0]  exp_a, exp_b;
    logic [22:0] mant_a, mant_b;
    logic [23:0] mant_a_ext, mant_b_ext;
    logic        a_is_zero, b_is_zero;

    assign sign_a = a[31]; assign exp_a = a[30:23]; assign mant_a = a[22:0];
    assign sign_b = b[31]; assign exp_b = b[30:23]; assign mant_b = b[22:0];
    assign sign_res = sign_a ^ sign_b;

    assign a_is_zero = (exp_a == 8'h0) && (mant_a == 23'h0);
    assign b_is_zero = (exp_b == 8'h0) && (mant_b == 23'h0);

    assign mant_a_ext = (exp_a == 8'h0) ? {1'b0, mant_a} : {1'b1, mant_a};
    assign mant_b_ext = (exp_b == 8'h0) ? {1'b0, mant_b} : {1'b1, mant_b};

    // Shift the dividend left 26 bits before dividing so the integer quotient
    // carries 1 leading bit + 23 mantissa bits + guard + round, with the
    // division remainder standing in for the sticky bit.
    logic [49:0]       dividend_ext;
    logic [26:0]       quotient;   // up to 27 bits: mant_a_ext/mant_b_ext in (0.5,2) scaled by 2^26
    logic [23:0]       remainder;

    logic signed [9:0] exp_base, exp_final;
    logic [23:0]       hidden_mant;   // hidden bit + 23 mantissa bits
    logic               g, r, s, round_up;
    logic [24:0]        mant_sum;      // extra bit catches rounding carry-out
    logic [22:0]        mant_res;

    always_comb begin
        dividend_ext = {mant_a_ext, 26'b0};
        quotient     = dividend_ext / mant_b_ext;   // synthesized as combinational divider
        remainder    = dividend_ext % mant_b_ext;

        exp_base = $signed({2'b00, exp_a}) - $signed({2'b00, exp_b}) + 10'sd127;

        if (quotient[26]) begin
            // ratio in [1,2)
            hidden_mant = quotient[26:3];
            g = quotient[2]; r = quotient[1]; s = quotient[0] || (remainder != 24'h0);
            exp_final = exp_base;
        end else begin
            // ratio in [0.5,1)
            hidden_mant = quotient[25:2];
            g = quotient[1]; r = quotient[0]; s = (remainder != 24'h0);
            exp_final = exp_base - 10'sd1;
        end

        round_up = g && (r || s || hidden_mant[0]);

        if (round_up) begin
            mant_sum = {1'b0, hidden_mant} + 25'h1;
            if (mant_sum[24]) begin           // rounded up to next power of two
                mant_res  = 23'h0;
                exp_final = exp_final + 10'sd1;
            end else begin
                mant_res = mant_sum[22:0];
            end
        end else begin
            mant_res = hidden_mant[22:0];
        end

        // --- Result selection ---
        if (a_is_zero && !b_is_zero) begin
            result = {sign_res, 31'h0};
        end else if (b_is_zero) begin
            result = {sign_res, 8'hFF, 23'h0};      // divide by zero -> +-Infinity
        end else if (exp_final >= 10'sd255) begin
            result = {sign_res, 8'hFF, 23'h0};      // overflow -> +-Infinity
        end else if (exp_final <= 10'sd0) begin
            result = {sign_res, 31'h0};              // underflow -> flush to zero
        end else begin
            result = {sign_res, exp_final[7:0], mant_res};
        end
    end
endmodule
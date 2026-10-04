`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.07.2026 18:09:48
// Design Name: 
// Module Name: fpu_mul
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

module fpu_mul (
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

    logic [47:0]      product;
    logic signed [9:0] exp_base, exp_final;
    logic [22:0]      mant_field;
    logic              g, r, s, round_up;
    logic [23:0]       mant_sum; 
    logic [22:0]       mant_res;

    always_comb begin
        product  = mant_a_ext * mant_b_ext;            
        exp_base = $signed({2'b00, exp_a}) + $signed({2'b00, exp_b}) - 10'sd127;

        if (product[47]) begin
            exp_final  = exp_base + 10'sd1;
            mant_field = product[46:24];
            g = product[23]; r = product[22]; s = |product[21:0];
        end else begin

            exp_final  = exp_base;
            mant_field = product[45:23];
            g = product[22]; r = product[21]; s = |product[20:0];
        end

        round_up = g && (r || s || mant_field[0]);

        if (round_up) begin
            mant_sum = {1'b0, mant_field} + 24'h1;
            if (mant_sum[23]) begin           
                mant_res  = 23'h0;
                exp_final = exp_final + 10'sd1;
            end else begin
                mant_res = mant_sum[22:0];
            end
        end else begin
            mant_res = mant_field;
        end

        if (a_is_zero || b_is_zero) begin
            result = {sign_res, 31'h0};
        end else if (exp_final >= 10'sd255) begin
            result = {sign_res, 8'hFF, 23'h0};     
        end else if (exp_final <= 10'sd0) begin
            result = {sign_res, 31'h0};            
        end else begin
            result = {sign_res, exp_final[7:0], mant_res};
        end
    end
endmodule
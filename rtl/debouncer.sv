`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.07.2026 11:42:58
// Design Name: 
// Module Name: debouncer
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


module debouncer #(
    parameter integer DEBOUNCE_TIME = 1_000_000 // 10ms at 100MHz
)(
    input  logic clk,
    input  logic rst,
    input  logic btn_in,
    output logic step_pulse
);

    logic btn_sync_1, btn_sync_2;
    logic btn_state;
    logic [31:0] counter;

    // 1. Two-stage synchronizer to mitigate metastability
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_sync_1 <= 1'b0;
            btn_sync_2 <= 1'b0;
        end else begin
            btn_sync_1 <= btn_in;
            btn_sync_2 <= btn_sync_1;
        end
    end

    // 2. Debounce counter and edge detection
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter    <= 20'd0;
            btn_state  <= 1'b0;
            step_pulse <= 1'b0;
        end else begin
            step_pulse <= 1'b0; // Default state

            if (btn_sync_2 != btn_state) begin
                counter <= counter + 1'b1;
                if (counter == DEBOUNCE_TIME - 1) begin
                    btn_state <= btn_sync_2;
                    counter   <= 20'd0;
                    // Generate a 1-cycle pulse only on the rising edge
                    if (btn_sync_2 == 1'b1) begin
                        step_pulse <= 1'b1;
                    end
                end
            end else begin
                counter <= 20'd0; // Reset counter if the switch bounces back
            end
        end
    end

endmodule

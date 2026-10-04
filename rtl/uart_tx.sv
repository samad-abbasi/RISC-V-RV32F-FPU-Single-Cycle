`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.07.2026 04:57:17
// Design Name: 
// Module Name: uart_tx
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



module uart_tx (
    input  logic       clk,
    input  logic       rst,
    input  logic       baud_tick,
    input  logic       start,
    input  logic [7:0] data_in,
    output logic       tx,
    output logic       busy,
    output logic       done
);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [2:0] bit_idx;
    logic [7:0] tx_data;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            bit_idx <= 3'd0;
            tx_data <= 8'd0;
            tx      <= 1'b1;
            busy    <= 1'b0;
            done    <= 1'b0;
        end else begin
            done <= 1'b0; // Default state for single-cycle done pulse

            case (state)
                IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (start) begin
                        tx_data <= data_in;
                        state   <= START;
                        busy    <= 1'b1;
                    end
                end

                START: begin
                    busy <= 1'b1;
                    if (baud_tick) begin
                        tx      <= 1'b0; // Start bit is low
                        state   <= DATA;
                        bit_idx <= 3'd0;
                    end
                end

                DATA: begin
                    busy <= 1'b1;
                    if (baud_tick) begin
                        tx <= tx_data[bit_idx];
                        if (bit_idx == 3'd7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end
                end

                STOP: begin
                    busy <= 1'b1;
                    if (baud_tick) begin
                        tx    <= 1'b1; // Stop bit is high
                        done  <= 1'b1;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
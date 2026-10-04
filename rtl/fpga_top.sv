`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.07.2026 04:58:46
// Design Name: 
// Module Name: fpga_top
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


module fpga_top #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE     = 9600
)(
    input  logic        CLK100MHZ,
    input  logic        CPU_RESETN,   
    input  logic        BTNC,         
    output logic        UART_RXD_OUT, 
    output logic [15:0] LED
);

    logic rst;
    assign rst = ~CPU_RESETN;

    logic        cpu_clk;
    logic [31:0] cpu_monitor_data;
    logic        cpu_monitor_valid;
    
    logic tx_tick;
    logic       tx_busy;
    logic       tx_done;
    logic       tx_start;
    logic [6:0] tx_data;

    logic step_trigger; //debouncer output 
    
        // --- Printing Orchestration State Machine ---
        typedef enum logic [2:0] {ST_IDLE, ST_CAPTURE, ST_TRANSMIT, ST_WAIT, ST_PULSE} print_state_t;
        print_state_t state;
    
        logic [31:0] captured_data;
        logic [3:0]  char_index;




    // --- NEW: Clean, Glitch-Free Registered Clock ---
    // This flip-flop guarantees exactly one perfect clock edge reaches the CPU,
    // completely eliminating the random PC skipping and double-clocking.
    logic clean_cpu_clk;
    always_ff @(posedge CLK100MHZ or posedge rst) begin
        if (rst) 
            clean_cpu_clk <= 1'b0;
        else 
            clean_cpu_clk <= (state == ST_PULSE);
    end

    // --- Core Instantiation ---
    top top_instance (
        .clk(clean_cpu_clk), // Driven by the clean registered clock
        .rst(rst),
        .monitor_data(cpu_monitor_data),
        .monitor_valid(cpu_monitor_valid)
    );

    debouncer #(
        .DEBOUNCE_TIME(1000) // Increased to 20ms for extra mechanical safety
    ) btn_debouncer (
        .clk(CLK100MHZ),
        .rst(rst),
        .btn_in(BTNC),
        .step_pulse(step_trigger)
    );


// --- Printing Orchestration State Machine ---
        // Added ST_CAPTURE to the enum
    
        // ... (Keep your clean_cpu_clk, core instantiation, and debouncer exactly as they are) ...
        
        always_ff @(posedge CLK100MHZ or posedge rst) begin
            if (rst) begin
                state         <= ST_IDLE;
                captured_data <= 32'h0;
                char_index    <= 4'd0;
                tx_start      <= 1'b0;
                tx_data       <= 7'h0;
            end else begin
                tx_start <= 1'b0; 
    
                case (state)
                    ST_IDLE: begin
                        if (step_trigger) begin
                            // The button was pressed. Delay 1 cycle to let the FPU combinational logic settle
                            state <= ST_CAPTURE; 
                        end
                    end
    
                    ST_CAPTURE: begin
                        // Lock in the stable data
                        captured_data <= cpu_monitor_data; 
                        char_index    <= 4'd0;
                        state         <= ST_TRANSMIT;
                    end
    
                    ST_TRANSMIT: begin
                        if (!tx_busy) begin
                            if (char_index < 4'd8) begin
                                logic [3:0] nibble;
                                
                                // 1. ALWAYS read the top 4 bits. No complex MUX required!
                                nibble = captured_data[31:28]; 
                                tx_data <= (nibble < 4'd10) ? (8'd48 + nibble) : (8'd55 + nibble);
                                
                                // 2. SHIFT the register left by 4 bits to queue up the next nibble
                                captured_data <= {captured_data[27:0], 4'h0}; 
                                
                            end else if (char_index == 4'd8) begin
                                tx_data <= 7'h0D; // \r
                            end else begin
                                tx_data <= 7'h0A; // \n
                            end
    
                            tx_start <= 1'b1;
                            state    <= ST_WAIT;
                        end
                    end
    
                    ST_WAIT: begin
                        if (tx_done) begin
                            if (char_index == 4'd9) begin
                                state <= ST_PULSE;
                            end else begin
                                char_index <= char_index + 1'b1;
                                state      <= ST_TRANSMIT;
                            end
                        end
                    end
                    
                    ST_PULSE: begin
                        state <= ST_IDLE;
                    end
                    
                    default: state <= ST_IDLE;
                endcase
            end
        end
    // --- Clock Generators & Drivers ---
    baud_rate_generator #(
        .CLK_FREQ(CLOCK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) tx_baud_gen (
        .clk(CLK100MHZ), 
        .rst(rst), 
        .tick(tx_tick)
    );

    uart_tx tx_inst (
        .clk(CLK100MHZ),     
        .rst(rst),
        .baud_tick(tx_tick), 
        .start(tx_start),
        .data_in(tx_data), 
        .tx(UART_RXD_OUT), 
        .busy(tx_busy),        
        .done(tx_done)
    );
  
    assign LED[7:0]   = cpu_monitor_data[7:0]; 
    assign LED[8]     = tx_busy;
    assign LED[9]     = cpu_monitor_valid;
    assign LED[15:10] = 6'b000000;

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 20:44:36
// Design Name: 
// Module Name: apb_uart
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


`timescale 1ns / 1ps

module apb_uart #(
    parameter DATA_WIDTH = 32
)(
    input  wire                  PCLK,
    input  wire                  PRESETn,
    input  wire [31:0]           PADDR,
    input  wire [DATA_WIDTH-1:0] PWDATA,
    input  wire                  PWRITE,
    input  wire                  PSEL,
    input  wire                  PENABLE,
    output reg  [DATA_WIDTH-1:0] PRDATA,
    output wire                  PREADY,
    output wire                  PSLVERR,

    output reg                   uart_tx,
    input  wire                  uart_rx
);

    reg [7:0] tx_buffer;
    reg [7:0] rx_buffer;
    reg       tx_busy;
    reg       rx_done;

    assign PREADY   = 1'b1;
    assign PSLVERR  = 1'b0;
    assign uart_irq = rx_done;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_buffer <= 8'h00;
            rx_buffer <= 8'h55; // Default test byte
            tx_busy   <= 1'b0;
            rx_done   <= 1'b0;
            uart_tx   <= 1'b1;
            PRDATA    <= 32'h0;
        end else begin
            // Transmit simulation
            if (tx_busy) begin
                uart_tx <= tx_buffer[0];
                tx_busy <= 1'b0; // Single cycle tick in sim
            end

            // APB Read/Write
            if (PSEL && PENABLE) begin
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'b00: begin // TX Data Register
                            tx_buffer <= PWDATA[7:0];
                            tx_busy   <= 1'b1;
                        end
                    endcase
                end else begin
                    case (PADDR[3:2])
                        2'b00: PRDATA <= {24'h0, rx_buffer};
                        2'b01: PRDATA <= {30'h0, rx_done, tx_busy};
                        default: PRDATA <= 32'h0;
                    endcase
                end
            end
        end
    end

endmodule

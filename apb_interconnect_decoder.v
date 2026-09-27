`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 21:38:45
// Design Name: 
// Module Name: apb_interconnect_decoder
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


module apb_interconnect_decoder (
    input  wire [31:0] PADDR,
    input  wire        PSEL_in,

    // Select Outputs
    output reg         PSEL_MEM,
    output reg         PSEL_GPIO,
    output reg         PSEL_UART,
    output reg         PSEL_TIMER,
    output reg         PSEL_I2C,
    output reg         PSEL_SPI,
    output reg         PSEL_DEFAULT,

    // Slave Response Inputs
    input  wire [31:0] PRDATA_MEM,   input wire PREADY_MEM,   input wire PSLVERR_MEM,
    input  wire [31:0] PRDATA_GPIO,  input wire PREADY_GPIO,  input wire PSLVERR_GPIO,
    input  wire [31:0] PRDATA_UART,  input wire PREADY_UART,  input wire PSLVERR_UART,
    input  wire [31:0] PRDATA_TIMER, input wire PREADY_TIMER, input wire PSLVERR_TIMER,
    input  wire [31:0] PRDATA_I2C,   input wire PREADY_I2C,   input wire PSLVERR_I2C,
    input  wire [31:0] PRDATA_SPI,   input wire PREADY_SPI,   input wire PSLVERR_SPI,

    // Multiplexed Bus to Bridge / Master
    output reg  [31:0] PRDATA_out,
    output reg         PREADY_out,
    output reg         PSLVERR_out
);

    always @(*) begin
        PSEL_MEM     = 1'b0;
        PSEL_GPIO    = 1'b0;
        PSEL_UART    = 1'b0;
        PSEL_TIMER   = 1'b0;
        PSEL_I2C     = 1'b0;
        PSEL_DEFAULT = 1'b0;

        if (PSEL_in && (PADDR[31:16] == 16'h4000)) begin
            case (PADDR[15:12])
                4'h0:    PSEL_MEM     = 1'b1;
                4'h1:    PSEL_GPIO    = 1'b1;
                4'h2:    PSEL_UART    = 1'b1;
                4'h3:    PSEL_TIMER   = 1'b1;
                4'h4:    PSEL_I2C     = 1'b1;
                default: PSEL_DEFAULT = 1'b1;
            endcase
        end
    end

    always @(*) begin
        if (PSEL_MEM) begin
            PRDATA_out  = PRDATA_MEM;
            PREADY_out  = PREADY_MEM;
            PSLVERR_out = PSLVERR_MEM;
        end else if (PSEL_GPIO) begin
            PRDATA_out  = PRDATA_GPIO;
            PREADY_out  = PREADY_GPIO;
            PSLVERR_out = PSLVERR_GPIO;
        end else if (PSEL_UART) begin
            PRDATA_out  = PRDATA_UART;
            PREADY_out  = PREADY_UART;
            PSLVERR_out = PSLVERR_UART;
        end else if (PSEL_TIMER) begin
            PRDATA_out  = PRDATA_TIMER;
            PREADY_out  = PREADY_TIMER;
            PSLVERR_out = PSLVERR_TIMER;
        end else if (PSEL_I2C) begin
            PRDATA_out  = PRDATA_I2C;
            PREADY_out  = PREADY_I2C;
            PSLVERR_out = PSLVERR_I2C;
        end else if (PSEL_DEFAULT) begin
            PRDATA_out  = 32'hDEAD_BEEF;
            PREADY_out  = 1'b1;
            PSLVERR_out = 1'b1; // Error trap response
        end else begin
            PRDATA_out  = 32'h0;
            PREADY_out  = 1'b1;
            PSLVERR_out = 1'b0;
        end
    end

endmodule
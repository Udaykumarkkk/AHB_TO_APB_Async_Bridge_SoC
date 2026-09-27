`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 20:46:29
// Design Name: 
// Module Name: apb_spi
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

module apb_spi (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire [31:0] PADDR,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    // SPI Bus Lines
    output reg         spi_clk,
    output reg         spi_cs_n,
    output reg         spi_mosi,
    input  wire        spi_miso
);

    reg [7:0] tx_reg;
    reg [7:0] rx_reg;
    reg       spi_busy;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            spi_clk   <= 1'b0;
            spi_cs_n  <= 1'b1;
            spi_mosi  <= 1'b0;
            tx_reg    <= 8'h00;
            rx_reg    <= 8'hAA;
            spi_busy  <= 1'b0;
            PRDATA    <= 32'h0;
        end else begin
            if (spi_busy) begin
                spi_cs_n <= 1'b0;
                spi_mosi <= tx_reg[7];
                spi_busy <= 1'b0;
            end else begin
                spi_cs_n <= 1'b1;
            end

            if (PSEL && PENABLE) begin
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'b00: begin
                            tx_reg   <= PWDATA[7:0];
                            spi_busy <= 1'b1;
                        end
                    endcase
                end else begin
                    case (PADDR[3:2])
                        2'b00: PRDATA <= {24'h0, rx_reg};
                        2'b01: PRDATA <= {31'h0, spi_busy};
                        default: PRDATA <= 32'h0;
                    endcase
                end
            end
        end
    end

endmodule

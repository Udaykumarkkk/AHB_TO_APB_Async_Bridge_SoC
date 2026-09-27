`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 20:37:02
// Design Name: 
// Module Name: apb_gpio
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

module apb_gpio #(
    parameter DATA_WIDTH = 32,
    parameter IO_WIDTH   = 16
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

    // Discrete Physical I/O Interface
    input  wire [IO_WIDTH-1:0]   gpio_in,
    output wire [IO_WIDTH-1:0]   gpio_out,
    output wire [IO_WIDTH-1:0]   gpio_oe
);

    reg [IO_WIDTH-1:0] out_reg;
    reg [IO_WIDTH-1:0] dir_reg;
    reg [IO_WIDTH-1:0] in_sync1, in_sync2;

    assign gpio_out = out_reg;
    assign gpio_oe  = dir_reg;
    assign PREADY   = 1'b1;
    assign PSLVERR  = (PADDR[7:0] > 8'h0C);

    // 2-Stage DFF Synchronizer for external input pins
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            in_sync1 <= {IO_WIDTH{1'b0}};
            in_sync2 <= {IO_WIDTH{1'b0}};
        end else begin
            in_sync1 <= gpio_in;
            in_sync2 <= in_sync1;
        end
    end

    // APB Register Writes
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            out_reg <= {IO_WIDTH{1'b0}};
            dir_reg <= {IO_WIDTH{1'b0}};
        end else if (PSEL && PENABLE && PWRITE) begin
            case (PADDR[7:0])
                8'h00: out_reg <= PWDATA[IO_WIDTH-1:0];             // 0x00: Data Write
                8'h04: dir_reg <= PWDATA[IO_WIDTH-1:0];             // 0x04: Direction Register
                8'h08: out_reg <= out_reg | PWDATA[IO_WIDTH-1:0];  // 0x08: Atomic Bit-Set
                8'h0C: out_reg <= out_reg & ~PWDATA[IO_WIDTH-1:0]; // 0x0C: Atomic Bit-Clear
                default: ;
            endcase
        end
    end

    // APB Register Reads
    always @(*) begin
        PRDATA = 32'h0;
        if (PSEL && !PWRITE) begin
            case (PADDR[7:0])
                8'h00:   PRDATA = { {(32-IO_WIDTH){1'b0}}, (in_sync2 & ~dir_reg) | (out_reg & dir_reg) };
                8'h04:   PRDATA = { {(32-IO_WIDTH){1'b0}}, dir_reg };
                default: PRDATA = 32'h0;
            endcase
        end
    end

endmodule

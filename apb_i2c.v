`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 20:45:32
// Design Name: 
// Module Name: apb_i2c
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

module apb_i2c #(
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


    output reg                   scl_out,
    output reg                   sda_out,
    input  wire                  sda_in
);

    reg [7:0] i2c_addr;
    reg [7:0] i2c_data;
    reg       i2c_ctrl_start;
    reg       scl_out, sda_out;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    assign scl = (scl_out) ? 1'bz : 1'b0;
    assign sda = (sda_out) ? 1'bz : 1'b0;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            i2c_addr       <= 8'h00;
            i2c_data       <= 8'h00;
            i2c_ctrl_start <= 1'b0;
            scl_out        <= 1'b1;
            sda_out        <= 1'b1;
            PRDATA         <= 32'h0;
        end else if (PSEL && PENABLE) begin
            if (PWRITE) begin
                case (PADDR[3:2])
                    2'b00: i2c_addr       <= PWDATA[7:0];
                    2'b01: i2c_data       <= PWDATA[7:0];
                    2'b10: i2c_ctrl_start <= PWDATA[0];
                endcase
            end else begin
                case (PADDR[3:2])
                    2'b00: PRDATA <= {24'h0, i2c_addr};
                    2'b01: PRDATA <= {24'h0, i2c_data};
                    2'b10: PRDATA <= {31'h0, i2c_ctrl_start};
                    default: PRDATA <= 32'h0;
                endcase
            end
        end
    end

endmodule

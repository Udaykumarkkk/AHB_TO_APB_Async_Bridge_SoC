`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.09.2026 18:05:30
// Design Name: 
// Module Name: apb_memory
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

module apb_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 1024 // 1K x 32-bit = 4 KB
)(
    input  wire                  PCLK,
    input  wire                  PRESETn,
    input  wire [ADDR_WIDTH-1:0] PADDR,
    input  wire [DATA_WIDTH-1:0] PWDATA,
    input  wire                  PWRITE,
    input  wire                  PSEL,
    input  wire                  PENABLE,
    output reg  [DATA_WIDTH-1:0] PRDATA,
    output wire                  PREADY,
    output wire                  PSLVERR
);

    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    assign PREADY  = 1'b1;
    assign PSLVERR = (PADDR[15:2] >= MEM_DEPTH) ? 1'b1 : 1'b0;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA <= {DATA_WIDTH{1'b0}};
        end else if (PSEL && PENABLE) begin
            if (PWRITE) begin
                if (PADDR[15:2] < MEM_DEPTH)
                    mem[PADDR[15:2]] <= PWDATA;
            end else begin
                if (PADDR[15:2] < MEM_DEPTH)
                    PRDATA <= mem[PADDR[15:2]];
                else
                    PRDATA <= 32'hDEAD_BEEF;
            end
        end
    end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.08.2026 20:52:19
// Design Name: 
// Module Name: apb_slave_mock
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

`timescale 1ns / 1ps

module apb_slave_mock #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                    PCLK,
    input  wire                    PRESETn,
    input  wire [ADDR_WIDTH-1:0]   PADDR,
    input  wire                    PSEL,
    input  wire                    PENABLE,
    input  wire                    PWRITE,
    input  wire [DATA_WIDTH-1:0]   PWDATA,
    output reg  [DATA_WIDTH-1:0]   PRDATA,
    output reg                     PREADY,
    output wire                    PSLVERR
);

    reg [DATA_WIDTH-1:0] memory [0:255];
    reg [1:0] wait_counter;
    integer i;

    assign PSLVERR = 1'b0;

    // Memory Initialization
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 32'h0000_0000;
        end
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA       <= {DATA_WIDTH{1'b0}};
            PREADY       <= 1'b1;
            wait_counter <= 2'b00;
        end else begin
            if (PSEL && !PENABLE) begin
                // Injected wait-state for odd word addresses (PADDR[2] == 1)
                if (PADDR[2] == 1'b1) begin
                    PREADY       <= 1'b0;
                    wait_counter <= 2'b01;
                end else begin
                    PREADY <= 1'b1;
                end
            end else if (PSEL && PENABLE) begin
                if (wait_counter > 0) begin
                    wait_counter <= wait_counter - 1'b1;
                    if (wait_counter == 2'b01)
                        PREADY <= 1'b1;
                end else begin
                    PREADY <= 1'b1;
                    if (PWRITE)
                        memory[PADDR[9:2]] <= PWDATA;
                    else
                        PRDATA <= memory[PADDR[9:2]];
                end
            end else begin
                PREADY <= 1'b1;
            end
        end
    end

endmodule

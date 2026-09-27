`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.09.2026 18:02:04
// Design Name: 
// Module Name: ahb_slave_front_end
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

module ahb_slave_front_end #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter CMD_DWIDTH = 68
)(
    input  wire                  HCLK,
    input  wire                  HRESETn,
    input  wire                  HSEL,
    input  wire [ADDR_WIDTH-1:0] HADDR,
    input  wire [1:0]            HTRANS,
    input  wire                  HWRITE,
    input  wire [2:0]            HSIZE,
    input  wire [DATA_WIDTH-1:0] HWDATA,
    input  wire                  HREADY,
    input  wire                  cmd_wfull,
    output reg  [CMD_DWIDTH-1:0] cmd_wdata,
    output reg                   cmd_winc,
    output reg                   pkg_done
);
    localparam S_IDLE = 1'b0,
               S_DATA = 1'b1;

    reg                  state;
    reg [ADDR_WIDTH-1:0] addr_latched;
    reg                  write_latched;
    reg [2:0]            size_latched;

    wire transfer_req = HSEL && HREADY && (HTRANS == 2'b10 || HTRANS == 2'b11);

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state         <= S_IDLE;
            addr_latched  <= {ADDR_WIDTH{1'b0}};
            write_latched <= 1'b0;
            size_latched  <= 3'b010;
            cmd_winc      <= 1'b0;
            cmd_wdata     <= {CMD_DWIDTH{1'b0}};
            pkg_done      <= 1'b0;
        end else begin
            cmd_winc <= 1'b0;
            pkg_done <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (transfer_req) begin
                        addr_latched  <= HADDR;
                        write_latched <= HWRITE;
                        size_latched  <= HSIZE;
                        pkg_done      <= 1'b1; // Trigger Response Front-End to deassert HREADYOUT
                        state         <= S_DATA;
                    end
                end

                S_DATA: begin
                    if (!cmd_wfull) begin
                        cmd_wdata <= {write_latched, size_latched, addr_latched, HWDATA};
                        cmd_winc  <= 1'b1;
                        state     <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule

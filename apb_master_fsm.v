`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.09.2026 18:03:36
// Design Name: 
// Module Name: apb_master_fsm
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

module apb_master_fsm #(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 32,
    parameter CMD_DWIDTH  = 68,
    parameter RESP_DWIDTH = 33
)(
    input  wire                   PCLK,
    input  wire                   PRESETn,
    // Command FIFO Interface
    input  wire [CMD_DWIDTH-1:0]  cmd_rdata,
    input  wire                   cmd_rempty,
    output reg                    cmd_rinc,
    // Response FIFO Interface
    input  wire                   resp_wfull,
    output reg  [RESP_DWIDTH-1:0] resp_wdata,
    output reg                    resp_winc,
    // APB Domain Interface
    output reg  [ADDR_WIDTH-1:0]  PADDR,
    output reg  [DATA_WIDTH-1:0]  PWDATA,
    output reg                    PWRITE,
    output reg                    PSEL,
    output reg                    PENABLE,
    input  wire [DATA_WIDTH-1:0]  PRDATA,
    input  wire                   PREADY,
    input  wire                   PSLVERR
);

    localparam IDLE   = 2'd0,
               SETUP  = 2'd1,
               ACCESS = 2'd2;

    reg [1:0] state;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state      <= IDLE;
            PADDR      <= {ADDR_WIDTH{1'b0}};
            PWDATA     <= {DATA_WIDTH{1'b0}};
            PWRITE     <= 1'b0;
            PSEL       <= 1'b0;
            PENABLE    <= 1'b0;
            cmd_rinc   <= 1'b0;
            resp_winc  <= 1'b0;
            resp_wdata <= {RESP_DWIDTH{1'b0}};
        end else begin
            cmd_rinc  <= 1'b0;
            resp_winc <= 1'b0;

            case (state)
                IDLE: begin
                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;
                    if (!cmd_rempty) begin
                        cmd_rinc <= 1'b1;
                        PWRITE   <= cmd_rdata[67];
                        PADDR    <= cmd_rdata[63:32];
                        PWDATA   <= cmd_rdata[31:0];
                        state    <= SETUP;
                    end
                end

                SETUP: begin
                    PSEL    <= 1'b1;
                    PENABLE <= 1'b0;
                    state   <= ACCESS;
                end

                ACCESS: begin
                    PENABLE <= 1'b1;
                    if (PREADY) begin
                        if (!resp_wfull) begin
                            resp_wdata <= {PSLVERR, PRDATA};
                            resp_winc  <= 1'b1;
                            PSEL       <= 1'b0;
                            PENABLE    <= 1'b0;
                            state      <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

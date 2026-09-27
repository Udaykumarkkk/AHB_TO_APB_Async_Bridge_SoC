`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.09.2026 18:02:51
// Design Name: 
// Module Name: ahb_response_front_end
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

module ahb_response_front_end #(
    parameter DATA_WIDTH  = 32,
    parameter RESP_DWIDTH = 33 // {PSLVERR(1), PRDATA(32)}
)(
    input  wire                   HCLK,
    input  wire                   HRESETn,
    input  wire                   pkg_done,
    input  wire                   resp_rempty,
    input  wire [RESP_DWIDTH-1:0] resp_rdata,
    output reg                    resp_rinc,
    output reg                    HREADYOUT,
    output reg  [1:0]             HRESP,
    output reg  [DATA_WIDTH-1:0]  HRDATA
);

    localparam IDLE = 1'b0,
               WAIT = 1'b1;

    reg state;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state     <= IDLE;
            resp_rinc <= 1'b0;
            HREADYOUT <= 1'b1;
            HRESP     <= 2'b00;
            HRDATA    <= {DATA_WIDTH{1'b0}};
        end else begin
            resp_rinc <= 1'b0;

            case (state)
                IDLE: begin
                    HREADYOUT <= 1'b1;
                    HRESP     <= 2'b00;
                    if (pkg_done) begin
                        HREADYOUT <= 1'b0; // Pull HREADYOUT low to stall processor
                        state     <= WAIT;
                    end
                end

                WAIT: begin
                    if (!resp_rempty) begin
                        resp_rinc <= 1'b1;
                        HRDATA    <= resp_rdata[DATA_WIDTH-1:0];
                        HRESP     <= resp_rdata[DATA_WIDTH] ? 2'b01 : 2'b00; // Propagate error
                        HREADYOUT <= 1'b1; // Release stall
                        state     <= IDLE;
                    end else begin
                        HREADYOUT <= 1'b0; // Maintain stall during APB execution
                    end
                end
            endcase
        end
    end

endmodule

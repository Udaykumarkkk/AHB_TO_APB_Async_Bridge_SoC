`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 20:38:06
// Design Name: 
// Module Name: apb_timer
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

module apb_timer (
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
    output reg         timer_irq
);

    reg [31:0] counter;
    reg [31:0] reload;
    reg        ctrl_en;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            counter   <= 32'h0;
            reload    <= 32'h0;
            ctrl_en   <= 1'b0;
            timer_irq <= 1'b0;
            PRDATA    <= 32'h0;
        end else begin
            // Down counter logic
            if (ctrl_en) begin
                if (counter == 32'h0) begin
                    counter   <= reload;
                    timer_irq <= 1'b1;
                end else begin
                    counter   <= counter - 1'b1;
                    timer_irq <= 1'b0;
                end
            end

            // APB Register access
            if (PSEL && PENABLE) begin
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'b00: ctrl_en <= PWDATA[0];
                        2'b01: reload  <= PWDATA;
                        2'b10: counter <= PWDATA;
                    endcase
                end else begin
                    case (PADDR[3:2])
                        2'b00: PRDATA <= {31'h0, ctrl_en};
                        2'b01: PRDATA <= reload;
                        2'b10: PRDATA <= counter;
                        default: PRDATA <= 32'h0;
                    endcase
                end
            end
        end
    end

endmodule

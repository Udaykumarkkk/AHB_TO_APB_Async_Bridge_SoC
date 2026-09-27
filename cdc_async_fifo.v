`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.09.2026 18:01:11
// Design Name: 
// Module Name: cdc_async_fifo
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

module cdc_async_fifo #(
    parameter DWIDTH = 68,
    parameter AWIDTH = 4   // Depth = 2^4 = 16 words
)(
    // Write Domain Ports
    input  wire              wclk,
    input  wire              wrst_n,
    input  wire              winc,
    input  wire [DWIDTH-1:0] wdata,
    output wire              wfull,

    // Read Domain Ports
    input  wire              rclk,
    input  wire              rrst_n,
    input  wire              rinc,
    output wire [DWIDTH-1:0] rdata,
    output wire              rempty
);

    reg [AWIDTH:0] wptr, wrptr1, wrptr2;
    reg [AWIDTH:0] rptr, rwptr1, rwptr2;
    reg [AWIDTH:0] wbin, rbin;

    wire [AWIDTH:0] wbin_next  = wbin + (winc & ~wfull);
    wire [AWIDTH:0] wgray_next = (wbin_next >> 1) ^ wbin_next;

    wire [AWIDTH:0] rbin_next  = rbin + (rinc & ~rempty);
    wire [AWIDTH:0] rgray_next = (rbin_next >> 1) ^ rbin_next;

    // Dual-Port RAM Array
    reg [DWIDTH-1:0] mem [0:(1<<AWIDTH)-1];

    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[wbin[AWIDTH-1:0]] <= wdata;
    end

    assign rdata = mem[rbin[AWIDTH-1:0]];

    // Write Pointer Logic (wclk domain)
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin <= { (AWIDTH+1){1'b0} };
            wptr <= { (AWIDTH+1){1'b0} };
        end else begin
            wbin <= wbin_next;
            wptr <= wgray_next;
        end
    end

    // Read Pointer Logic (rclk domain)
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin <= { (AWIDTH+1){1'b0} };
            rptr <= { (AWIDTH+1){1'b0} };
        end else begin
            rbin <= rbin_next;
            rptr <= rgray_next;
        end
    end

    // 2-DFF Synchronizer: Write Pointer into Read Domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rwptr1 <= { (AWIDTH+1){1'b0} };
            rwptr2 <= { (AWIDTH+1){1'b0} };
        end else begin
            rwptr1 <= wptr;
            rwptr2 <= rwptr1;
        end
    end

    // 2-DFF Synchronizer: Read Pointer into Write Domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wrptr1 <= { (AWIDTH+1){1'b0} };
            wrptr2 <= { (AWIDTH+1){1'b0} };
        end else begin
            wrptr1 <= rptr;
            wrptr2 <= wrptr1;
        end
    end

    // Empty and Full Flag Generation
    assign rempty = (rptr == rwptr2);
    assign wfull  = (wgray_next == {~wrptr2[AWIDTH:AWIDTH-1], wrptr2[AWIDTH-2:0]});

endmodule

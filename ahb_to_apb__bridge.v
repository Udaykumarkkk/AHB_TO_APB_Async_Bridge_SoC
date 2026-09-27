`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 21:37:51
// Design Name: 
// Module Name: ahb_to_apb__bridge
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


`timescale 1ns / 1ps`timescale 1ns / 1ps

module ahb_to_apb_async_bridge #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // AHB Domain Signals (HCLK)
    input  wire                  HCLK,
    input  wire                  HRESETn,
    input  wire                  HSEL,
    input  wire [ADDR_WIDTH-1:0] HADDR,
    input  wire [1:0]            HTRANS,
    input  wire                  HWRITE,
    input  wire [2:0]            HSIZE,
    input  wire [DATA_WIDTH-1:0] HWDATA,
    input  wire                  HREADY,
    output wire [DATA_WIDTH-1:0] HRDATA,
    output wire                  HREADYOUT,
    output wire [1:0]            HRESP,

    // APB Domain Signals (PCLK)
    input  wire                  PCLK,
    input  wire                  PRESETn,
    output wire [ADDR_WIDTH-1:0] PADDR,
    output wire [DATA_WIDTH-1:0] PWDATA,
    output wire                  PWRITE,
    output wire                  PSEL,
    output wire                  PENABLE,
    input  wire [DATA_WIDTH-1:0] PRDATA,
    input  wire                  PREADY,
    input  wire                  PSLVERR
);

    localparam CMD_DWIDTH  = 1 + 3 + ADDR_WIDTH + DATA_WIDTH; // 68 bits
    localparam RESP_DWIDTH = 1 + DATA_WIDTH;              // 33 bits

    wire [CMD_DWIDTH-1:0]  cmd_wdata, cmd_rdata;
    wire                   cmd_winc,  cmd_rinc;
    wire                   cmd_wfull, cmd_rempty;

    wire [RESP_DWIDTH-1:0] resp_wdata, resp_rdata;
    wire                   resp_winc,  resp_rinc;
    wire                   resp_wfull, resp_rempty;

    wire                   pkg_done;

    // 1. AHB Slave Front-End
    ahb_slave_front_end #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .CMD_DWIDTH (CMD_DWIDTH)
    ) u_ahb_slave_fe (
        .HCLK          (HCLK),
        .HRESETn       (HRESETn),
        .HSEL          (HSEL),
        .HADDR         (HADDR),
        .HTRANS        (HTRANS),
        .HWRITE        (HWRITE),
        .HSIZE         (HSIZE),
        .HWDATA        (HWDATA),
        .HREADY        (HREADY),
        .cmd_wfull     (cmd_wfull),
        .cmd_wdata     (cmd_wdata),
        .cmd_winc      (cmd_winc),
        .pkg_done      (pkg_done)
    );

    // 2. Command CDC FIFO (16 x 68)
    cdc_async_fifo #(
        .DWIDTH (CMD_DWIDTH),
        .AWIDTH (4)
    ) u_cdc_fifo_cmd (
        .wclk   (HCLK),
        .wrst_n (HRESETn),
        .winc   (cmd_winc),
        .wdata  (cmd_wdata),
        .wfull  (cmd_wfull),
        .rclk   (PCLK),
        .rrst_n (PRESETn),
        .rinc   (cmd_rinc),
        .rdata  (cmd_rdata),
        .rempty (cmd_rempty)
    );

    // 3. Response CDC FIFO (16 x 33)
    cdc_async_fifo #(
        .DWIDTH (RESP_DWIDTH),
        .AWIDTH (4)
    ) u_cdc_fifo_resp (
        .wclk   (PCLK),
        .wrst_n (PRESETn),
        .winc   (resp_winc),
        .wdata  (resp_wdata),
        .wfull  (resp_wfull),
        .rclk   (HCLK),
        .rrst_n (HRESETn),
        .rinc   (resp_rinc),
        .rdata  (resp_rdata),
        .rempty (resp_rempty)
    );

    // 4. APB Master FSM
    apb_master_fsm #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .CMD_DWIDTH  (CMD_DWIDTH),
        .RESP_DWIDTH (RESP_DWIDTH)
    ) u_apb_master_fsm (
        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .cmd_rdata   (cmd_rdata),
        .cmd_rempty  (cmd_rempty),
        .cmd_rinc    (cmd_rinc),
        .resp_wfull  (resp_wfull),
        .resp_wdata  (resp_wdata),
        .resp_winc   (resp_winc),
        .PADDR       (PADDR),
        .PWDATA      (PWDATA),
        .PWRITE      (PWRITE),
        .PSEL        (PSEL),
        .PENABLE     (PENABLE),
        .PRDATA      (PRDATA),
        .PREADY      (PREADY),
        .PSLVERR     (PSLVERR)
    );

    // 5. AHB Response Front-End
    ahb_response_front_end #(
        .DATA_WIDTH  (DATA_WIDTH),
        .RESP_DWIDTH (RESP_DWIDTH)
    ) u_ahb_resp_fe (
        .HCLK        (HCLK),
        .HRESETn     (HRESETn),
        .pkg_done    (pkg_done),
        .resp_rempty (resp_rempty),
        .resp_rdata  (resp_rdata),
        .resp_rinc   (resp_rinc),
        .HREADYOUT   (HREADYOUT),
        .HRESP       (HRESP),
        .HRDATA      (HRDATA)
    );

endmodule
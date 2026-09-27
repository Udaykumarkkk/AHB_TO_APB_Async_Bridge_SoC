`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.08.2026 20:50:58
// Design Name: 
// Module Name: ahb_to_apb_bridge
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

module ahb_to_apb_bridge #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // AHB-Lite Global Signals
    input  wire                    HCLK,
    input  wire                    HRESETn,

    // AHB-Lite Slave Interface
    input  wire                    HSEL,
    input  wire [ADDR_WIDTH-1:0]   HADDR,
    input  wire [1:0]              HTRANS,     // 2'b00: IDLE, 2'b10: NONSEQ, 2'b11: SEQ
    input  wire                    HWRITE,
    input  wire [2:0]              HSIZE,
    input  wire [DATA_WIDTH-1:0]   HWDATA,
    input  wire                    HREADY,
    output wire [DATA_WIDTH-1:0]   HRDATA,
    output wire                    HREADYOUT,
    output wire [1:0]              HRESP,      // 2'b00: OKAY, 2'b01: ERROR

    // APB Master Interface
    output reg  [ADDR_WIDTH-1:0]   PADDR,
    output reg                     PSEL,
    output reg                     PENABLE,
    output reg                     PWRITE,
    output reg  [DATA_WIDTH-1:0]   PWDATA,
    input  wire [DATA_WIDTH-1:0]   PRDATA,
    input  wire                    PREADY,
    input  wire                    PSLVERR
);

    // FSM State Encoding
    
    localparam ST_IDLE   = 2'b00;
    localparam ST_SETUP  = 2'b01;
    localparam ST_ACCESS = 2'b10;

    reg [1:0] state, next_state;

    // Address phase pipeline storage
    
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg                  write_reg;
    reg                  valid_transfer;

    // Valid AHB Transfer Condition
    
    wire ahb_transfer_req = HSEL && HREADY && (HTRANS == 2'b10 || HTRANS == 2'b11);

    // Register AHB Address and Control
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_reg       <= {ADDR_WIDTH{1'b0}};
            write_reg      <= 1'b0;
            valid_transfer <= 1'b0;
        end else if (ahb_transfer_req && (state == ST_IDLE || (state == ST_ACCESS && PREADY))) begin
            addr_reg       <= HADDR;
            write_reg      <= HWRITE;
            valid_transfer <= 1'b1;
        end else if (state == ST_ACCESS && PREADY) begin
            valid_transfer <= 1'b0;
        end
    end

    // FSM Sequential Logic
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            state <= ST_IDLE;
        else
            state <= next_state;
    end

    // FSM Next State Logic
    
    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE: begin
                if (ahb_transfer_req || valid_transfer)
                    next_state = ST_SETUP;
            end

            ST_SETUP: begin
                next_state = ST_ACCESS;
            end

            ST_ACCESS: begin
                if (PREADY) begin
                    if (ahb_transfer_req)
                        next_state = ST_SETUP;
                    else
                        next_state = ST_IDLE;
                end
            end

            default: next_state = ST_IDLE;
        endcase
    end

    // APB Control and Output Signal Generation
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            PADDR   <= {ADDR_WIDTH{1'b0}};
            PWRITE  <= 1'b0;
            PWDATA  <= {DATA_WIDTH{1'b0}};
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
        end else begin
            case (next_state)
                ST_IDLE: begin
                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;
                end

                ST_SETUP: begin
                    PSEL    <= 1'b1;
                    PENABLE <= 1'b0;
                    PADDR   <= addr_reg;
                    PWRITE  <= write_reg;
                    if (write_reg)
                        PWDATA <= HWDATA;
                end

                ST_ACCESS: begin
                    PSEL    <= 1'b1;
                    PENABLE <= 1'b1;
                end
            endcase
        end
    end

    // AHB Response Routing
    
    assign HRDATA    = PRDATA;
    assign HRESP     = (state == ST_ACCESS && PSLVERR) ? 2'b01 : 2'b00;
    assign HREADYOUT = (state == ST_IDLE) ? 1'b1 : (state == ST_ACCESS && PREADY);

endmodule

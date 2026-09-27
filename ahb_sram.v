`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 20:35:26
// Design Name: 
// Module Name: ahb_sram
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

module ahb_sram #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input  wire                  HCLK,
    input  wire                  HRESETn,
    input  wire                  HSEL,
    input  wire [ADDR_WIDTH-1:0] HADDR,
    input  wire [1:0]            HTRANS,
    input  wire                  HWRITE,
    input  wire [DATA_WIDTH-1:0] HWDATA,
    input  wire                  HREADY,
    output wire [DATA_WIDTH-1:0] HRDATA,
    output wire                  HREADYOUT,
    output wire [1:0]            HRESP
);

    // Number of 32-bit words: 64 KB / 4 bytes per word = 16384 words
    localparam MEM_DEPTH = (1 << (ADDR_WIDTH - 2));

    // Internal Memory Array
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    // Pipeline Registers to decouple Address Phase and Data Phase
    reg [ADDR_WIDTH-3:0] addr_reg;
    reg                  write_reg;
    reg                  valid_reg;

    // Detect a valid non-idle AHB transfer targeting this slave
    wire transfer_req = HSEL && HREADY && (HTRANS == 2'b10 || HTRANS == 2'b11);

    // Address Phase Sampling
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_reg  <= {(ADDR_WIDTH-2){1'b0}};
            write_reg <= 1'b0;
            valid_reg <= 1'b0;
        end else if (HREADY) begin
            valid_reg <= transfer_req;
            if (transfer_req) begin
                addr_reg  <= HADDR[ADDR_WIDTH-1:2]; // Word-aligned indexing
                write_reg <= HWRITE;
            end
        end
    end

    // Data Phase: Synchronous Write Operation
    always @(posedge HCLK) begin
        if (valid_reg && write_reg) begin
            mem[addr_reg] <= HWDATA;
        end
    end

    // Data Phase: Read Operation & Status Feedback
    // HRDATA is driven from memory when a read transaction was qualified
    assign HRDATA    = (valid_reg && !write_reg) ? mem[addr_reg] : {DATA_WIDTH{1'b0}};
    assign HREADYOUT = 1'b1;  // Single-cycle zero wait-state response
    assign HRESP     = 2'b00; // Always OKAY

endmodule

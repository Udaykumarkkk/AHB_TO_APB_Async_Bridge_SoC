`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 20:47:41
// Design Name: 
// Module Name: ahb_cpu_master
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

module ahb_cpu_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  HCLK,
    input  wire                  HRESETn,
    input  wire                  HREADY,
    input  wire [DATA_WIDTH-1:0] HRDATA,
    input  wire [1:0]            HRESP,

    // Qualified Slave Selects
    output reg                   HSEL_SRAM,
    output reg                   HSEL_BRIDGE,

    // AHB-Lite Control & Data Buses
    output reg  [ADDR_WIDTH-1:0] HADDR,
    output reg  [1:0]            HTRANS,
    output reg                   HWRITE,
    output reg  [2:0]            HSIZE,
    output reg  [DATA_WIDTH-1:0] HWDATA,
    output reg                   cpu_done
);

    // FSM State Encoding
    localparam S_BOOT        = 4'd0,
               S_SRAM_WR_A   = 4'd1,
               S_SRAM_WR_D   = 4'd2,
               S_SRAM_RD_A   = 4'd3,
               S_SRAM_RD_D   = 4'd4,
               S_MEM_WR_A    = 4'd5,
               S_MEM_WR_D    = 4'd6,
               S_MEM_RD_A    = 4'd7,
               S_MEM_RD_D    = 4'd8,
               S_GPIO_WR_A   = 4'd9,
               S_GPIO_WR_D   = 4'd10,
               S_DONE        = 4'd11;

    reg [3:0] state;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state       <= S_BOOT;
            HSEL_SRAM   <= 1'b0;
            HSEL_BRIDGE <= 1'b0;
            HADDR       <= {ADDR_WIDTH{1'b0}};
            HTRANS      <= 2'b00;
            HWRITE      <= 1'b0;
            HSIZE       <= 3'b010; // 32-bit word width
            HWDATA      <= {DATA_WIDTH{1'b0}};
            cpu_done    <= 1'b0;
        end else begin
            case (state)
                S_BOOT: begin
                    HTRANS   <= 2'b00;
                    cpu_done <= 1'b0;
                    state    <= S_SRAM_WR_A;
                end

                // -------------------------------------------------------------
                // 1. Direct AHB SRAM Write (0x0000_0020)
                // -------------------------------------------------------------
                S_SRAM_WR_A: begin
                    HSEL_SRAM   <= 1'b1;
                    HSEL_BRIDGE <= 1'b0;
                    HADDR       <= 32'h0000_0020;
                    HTRANS      <= 2'b10; // NONSEQ
                    HWRITE      <= 1'b1;  // Write
                    state       <= S_SRAM_WR_D;
                end

                S_SRAM_WR_D: begin
                    HWDATA <= 32'h1234_5678;
                    if (HREADY) begin
                        state <= S_SRAM_RD_A;
                    end
                end

                // -------------------------------------------------------------
                // 2. Direct AHB SRAM Read (0x0000_0020)
                // -------------------------------------------------------------
                S_SRAM_RD_A: begin
                    HSEL_SRAM   <= 1'b1;
                    HSEL_BRIDGE <= 1'b0;
                    HADDR       <= 32'h0000_0020;
                    HTRANS      <= 2'b10; // NONSEQ
                    HWRITE      <= 1'b0;  // Read
                    state       <= S_SRAM_RD_D;
                end

                S_SRAM_RD_D: begin
                    if (HREADY) begin
                        state <= S_MEM_WR_A;
                    end
                end

                // -------------------------------------------------------------
                // 3. APB Secondary Memory Write across Bridge (0x4000_0000)
                // -------------------------------------------------------------
                S_MEM_WR_A: begin
                    HSEL_SRAM   <= 1'b0;
                    HSEL_BRIDGE <= 1'b1;
                    HADDR       <= 32'h4000_0000;
                    HTRANS      <= 2'b10; // NONSEQ
                    HWRITE      <= 1'b1;  // Write
                    state       <= S_MEM_WR_D;
                end

                S_MEM_WR_D: begin
                    HWDATA <= 32'hA5A5_AA55;
                    if (HREADY) begin
                        state <= S_MEM_RD_A;
                    end
                end

                // -------------------------------------------------------------
                // 4. APB Secondary Memory Read across Bridge (0x4000_0000)
                // -------------------------------------------------------------
                S_MEM_RD_A: begin
                    HSEL_SRAM   <= 1'b0;
                    HSEL_BRIDGE <= 1'b1;
                    HADDR       <= 32'h4000_0000;
                    HTRANS      <= 2'b10; // NONSEQ
                    HWRITE      <= 1'b0;  // Read
                    state       <= S_MEM_RD_D;
                end

                S_MEM_RD_D: begin
                    if (HREADY) begin
                        state <= S_GPIO_WR_A;
                    end
                end

                // -------------------------------------------------------------
                // 5. APB GPIO Output Configuration (0x4000_1000)
                // -------------------------------------------------------------
                S_GPIO_WR_A: begin
                    HSEL_SRAM   <= 1'b0;
                    HSEL_BRIDGE <= 1'b1;
                    HADDR       <= 32'h4000_1000;
                    HTRANS      <= 2'b10; // NONSEQ
                    HWRITE      <= 1'b1;  // Write
                    state       <= S_GPIO_WR_D;
                end

                S_GPIO_WR_D: begin
                    HWDATA <= 32'h0000_FFFF;
                    HTRANS <= 2'b00; // Return bus to IDLE
                    if (HREADY) begin
                        HSEL_BRIDGE <= 1'b0;
                        state       <= S_DONE;
                    end
                end

                // -------------------------------------------------------------
                // 6. Execution Complete
                // -------------------------------------------------------------
                S_DONE: begin
                    HSEL_SRAM   <= 1'b0;
                    HSEL_BRIDGE <= 1'b0;
                    HTRANS      <= 2'b00;
                    HWRITE      <= 1'b0;
                    cpu_done    <= 1'b1;
                    state       <= S_DONE;
                end

                default: state <= S_BOOT;
            endcase
        end
    end

endmodule

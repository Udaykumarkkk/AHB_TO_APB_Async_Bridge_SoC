`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 21:40:35
// Design Name: 
// Module Name: soc__top
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

module soc_top_async (
    // Primary System Clocks & Resets
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        PCLK,
    input  wire        PRESETn,

    // Status Output
    output wire        cpu_done_led,

    // Peripheral Physical Pins
    input  wire [15:0] gpio_in,
    output wire [15:0] gpio_out,
    output wire [15:0] gpio_oe,

    output wire        uart_tx,
    input  wire        uart_rx,

    output wire        timer_irq,

    output wire        scl_out,
    output wire        sda_out,
    input  wire        sda_in
);

    // AHB Interconnect Buses
    wire        hsel_sram, hsel_bridge;
    wire [31:0] haddr;
    wire [1:0]  htrans;
    wire        hwrite;
    wire [2:0]  hsize;
    wire [31:0] hwdata;
    wire [31:0] hrdata_sram, hrdata_bridge, hrdata_mux;
    wire        hreadyout_sram, hreadyout_bridge, hready_mux;
    wire [1:0]  hresp_sram, hresp_bridge, hresp_mux;

    // APB Interconnect Buses
    wire [31:0] paddr, pwdata, prdata_dec;
    wire        pwrite, psel_bridge, penable;
    wire        psel_mem, psel_gpio, psel_uart, psel_timer, psel_i2c, psel_default;
    wire        pready_dec, pslverr_dec;

    wire [31:0] prdata_mem, prdata_gpio, prdata_uart, prdata_timer, prdata_i2c;
    wire        pready_mem, pready_gpio, pready_uart, pready_timer, pready_i2c;
    wire        pslverr_mem, pslverr_gpio, pslverr_uart, pslverr_timer, pslverr_i2c;

    // AHB Multiplexing
    assign hrdata_mux = hsel_sram ? hrdata_sram : hrdata_bridge;
    assign hready_mux = hsel_sram ? hreadyout_sram : hreadyout_bridge;
    assign hresp_mux  = hsel_sram ? hresp_sram : hresp_bridge;

    // 1. AHB CPU Master
    ahb_cpu_master u_cpu (
        .HCLK        (HCLK),
        .HRESETn     (HRESETn),
        .HREADY      (hready_mux),
        .HRDATA      (hrdata_mux),
        .HRESP       (hresp_mux),
        .HSEL_SRAM   (hsel_sram),
        .HSEL_BRIDGE (hsel_bridge),
        .HADDR       (haddr),
        .HTRANS      (htrans),
        .HWRITE      (hwrite),
        .HSIZE       (hsize),
        .HWDATA      (hwdata),
        .cpu_done    (cpu_done_led)
    );

// 2. Direct AHB SRAM
ahb_sram u_sram (
    .HCLK      (HCLK),
    .HRESETn   (HRESETn),
    .HSEL      (hsel_sram),
    .HADDR     (haddr),
    .HTRANS    (htrans),
    .HWRITE    (hwrite),
    .HWDATA    (hwdata),
    .HREADY    (hready_mux),
    .HRDATA    (hrdata_sram),
    .HREADYOUT (hreadyout_sram),
    .HRESP     (hresp_sram)
);
    // 3. Asynchronous AHB-to-APB Bridge
    ahb_to_apb_async_bridge u_bridge (
        .HCLK      (HCLK),
        .HRESETn   (HRESETn),
        .HSEL      (hsel_bridge),
        .HADDR     (haddr),
        .HTRANS    (htrans),
        .HWRITE    (hwrite),
        .HSIZE     (hsize),
        .HWDATA    (hwdata),
        .HREADY    (hready_mux),
        .HRDATA    (hrdata_bridge),
        .HREADYOUT (hreadyout_bridge),
        .HRESP     (hresp_bridge),

        .PCLK      (PCLK),
        .PRESETn   (PRESETn),
        .PADDR     (paddr),
        .PWDATA    (pwdata),
        .PWRITE    (pwrite),
        .PSEL      (psel_bridge),
        .PENABLE   (penable),
        .PRDATA    (prdata_dec),
        .PREADY    (pready_dec),
        .PSLVERR   (pslverr_dec)
    );

    // 4. APB Interconnect Decoder
    apb_interconnect_decoder u_decoder (
        .PADDR         (paddr),
        .PSEL_in       (psel_bridge),
        .PSEL_MEM      (psel_mem),
        .PSEL_GPIO     (psel_gpio),
        .PSEL_UART     (psel_uart),
        .PSEL_TIMER    (psel_timer),
        .PSEL_I2C      (psel_i2c),
        .PSEL_DEFAULT  (psel_default),

        .PRDATA_MEM    (prdata_mem),
        .PREADY_MEM    (pready_mem),
        .PSLVERR_MEM   (pslverr_mem),

        .PRDATA_GPIO   (prdata_gpio),
        .PREADY_GPIO   (pready_gpio),
        .PSLVERR_GPIO  (pslverr_gpio),

        .PRDATA_UART   (prdata_uart),
        .PREADY_UART   (pready_uart),
        .PSLVERR_UART  (pslverr_uart),

        .PRDATA_TIMER  (prdata_timer),
        .PREADY_TIMER  (pready_timer),
        .PSLVERR_TIMER (pslverr_timer),

        .PRDATA_I2C    (prdata_i2c),
        .PREADY_I2C    (pready_i2c),
        .PSLVERR_I2C   (pslverr_i2c),

        .PRDATA_out    (prdata_dec),
        .PREADY_out    (pready_dec),
        .PSLVERR_out   (pslverr_dec)
    );

    // 5. APB Memory Slave
    apb_memory u_apb_mem (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (paddr),
        .PWDATA  (pwdata),
        .PWRITE  (pwrite),
        .PSEL    (psel_mem),
        .PENABLE (penable),
        .PRDATA  (prdata_mem),
        .PREADY  (pready_mem),
        .PSLVERR (pslverr_mem)
    );

    // 6. APB GPIO
    
  apb_gpio u_gpio (
        .PCLK     (PCLK),
        .PRESETn  (PRESETn),
        .PADDR    (paddr),
        .PWDATA   (pwdata),
        .PWRITE   (pwrite),
        .PSEL     (psel_gpio),
        .PENABLE  (penable),
        .PRDATA   (prdata_gpio),
        .PREADY   (pready_gpio),
        .PSLVERR  (pslverr_gpio),
        .gpio_in  (gpio_in),
        .gpio_out (gpio_out),
        .gpio_oe  (gpio_oe)
    );

    // 7. APB UART
    apb_uart u_uart (
        .PCLK     (PCLK),
        .PRESETn  (PRESETn),
        .PADDR    (paddr),
        .PWDATA   (pwdata),
        .PWRITE   (pwrite),
        .PSEL     (psel_uart),
        .PENABLE  (penable),
        .PRDATA   (prdata_uart),
        .PREADY   (pready_uart),
        .PSLVERR  (pslverr_uart),
        .uart_tx  (uart_tx),
        .uart_rx  (uart_rx)
    );

    // 8. APB Timer
    apb_timer u_timer (
        .PCLK      (PCLK),
        .PRESETn   (PRESETn),
        .PADDR     (paddr),
        .PWDATA    (pwdata),
        .PWRITE    (pwrite),
        .PSEL      (psel_timer),
        .PENABLE   (penable),
        .PRDATA    (prdata_timer),
        .PREADY    (pready_timer),
        .PSLVERR   (pslverr_timer),
        .timer_irq (timer_irq)
    );

    
    // 9. APB I2C Master Instance
    apb_i2c u_i2c (
        .PCLK     (PCLK),
        .PRESETn  (PRESETn),
        .PADDR    (paddr),
        .PWDATA   (pwdata),
        .PWRITE   (pwrite),
        .PSEL     (psel_i2c),
        .PENABLE  (penable),
        .PRDATA   (prdata_i2c),
        .PREADY   (pready_i2c),
        .PSLVERR  (pslverr_i2c),
        .scl_out  (scl_out),
        .sda_out  (sda_out),
        .sda_in   (sda_in)
    );

endmodule
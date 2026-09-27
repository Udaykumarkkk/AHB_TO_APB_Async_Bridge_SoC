`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.09.2026 20:39:04
// Design Name: 
// Module Name: soc_top
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

module soc_top (
    input  wire        CLK,
    input  wire        RESETn,

    // Physical Hardware Pins
    inout  wire [15:0] gpio_io,
    input  wire        uart_rx,
    output wire        uart_tx,
    output wire        timer_irq,
    inout  wire        i2c_scl,
    inout  wire        i2c_sda,
    output wire        spi_clk,
    output wire        spi_cs_n,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        cpu_done_led
);

    // AHB System Bus Wires
    wire        ahb_hsel;
    wire [31:0] ahb_haddr;
    wire [1:0]  ahb_htrans;
    wire        ahb_hwrite;
    wire [2:0]  ahb_hsize;
    wire [31:0] ahb_hwdata;
    wire        ahb_hready;
    wire [31:0] ahb_hrdata;
    wire [1:0]  ahb_hresp;

    // Address Decoding on AHB
    wire sel_sram   = ahb_hsel && (ahb_haddr[31:16] == 16'h0000);
    wire sel_bridge = ahb_hsel && (ahb_haddr[31:16] == 16'h4000);

    wire [31:0] sram_hrdata, bridge_hrdata;
    wire        sram_hready, bridge_hready;
    wire [1:0]  sram_hresp, bridge_hresp;

    assign ahb_hrdata = sel_sram ? sram_hrdata : bridge_hrdata;
    assign ahb_hready = sel_sram ? sram_hready : bridge_hready;
    assign ahb_hresp  = sel_sram ? sram_hresp  : bridge_hresp;

    // APB Bus Wires
    wire [31:0] apb_paddr;
    wire        apb_psel;
    wire        apb_penable;
    wire        apb_pwrite;
    wire [31:0] apb_pwdata;
    wire [31:0] apb_prdata;
    wire        apb_pready;
    wire        apb_pslverr;

    // Peripheral Interconnect Wires
    wire psel_gpio, psel_uart, psel_timer, psel_i2c, psel_spi;
    wire [31:0] rdata_gpio, rdata_uart, rdata_timer, rdata_i2c, rdata_spi;
    wire        ready_gpio, ready_uart, ready_timer, ready_i2c, ready_spi;

    // ==========================================
    // 1. AHB CPU Master
    // ==========================================
    ahb_cpu_master u_cpu (
        .HCLK     (CLK),
        .HRESETn  (RESETn),
        .HREADY   (ahb_hready),
        .HRDATA   (ahb_hrdata),
        .HRESP    (ahb_hresp),
        .HSEL     (ahb_hsel),
        .HADDR    (ahb_haddr),
        .HTRANS   (ahb_htrans),
        .HWRITE   (ahb_hwrite),
        .HSIZE    (ahb_hsize),
        .HWDATA   (ahb_hwdata),
        .cpu_done (cpu_done_led)
    );

    // ==========================================
    // 2. AHB 64KB SRAM Block
    // ==========================================
    ahb_sram #(
        .ADDR_WIDTH(16),
        .DATA_WIDTH(32)
    ) u_sram (
        .HCLK      (CLK),
        .HRESETn   (RESETn),
        .HSEL      (sel_sram),
        .HADDR     (ahb_haddr[15:0]),
        .HTRANS    (ahb_htrans),
        .HWRITE    (ahb_hwrite),
        .HWDATA    (ahb_hwdata),
        .HREADY    (ahb_hready),
        .HRDATA    (sram_hrdata),
        .HREADYOUT (sram_hready),
        .HRESP     (sram_hresp)
    );

    // ==========================================
    // 3. AHB-to-APB Bridge
    // ==========================================
    ahb_to_apb_bridge #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) u_bridge (
        .HCLK      (CLK),
        .HRESETn   (RESETn),
        .HSEL      (sel_bridge),
        .HADDR     (ahb_haddr),
        .HTRANS    (ahb_htrans),
        .HWRITE    (ahb_hwrite),
        .HSIZE     (ahb_hsize),
        .HWDATA    (ahb_hwdata),
        .HREADY    (ahb_hready),
        .HRDATA    (bridge_hrdata),
        .HREADYOUT (bridge_hready),
        .HRESP     (bridge_hresp),
        .PADDR     (apb_paddr),
        .PSEL      (apb_psel),
        .PENABLE   (apb_penable),
        .PWRITE    (apb_pwrite),
        .PWDATA    (apb_pwdata),
        .PRDATA    (apb_prdata),
        .PREADY    (apb_pready),
        .PSLVERR   (apb_pslverr)
    );

    // ==========================================
    // 4. APB Interconnect Decoder (5 Slaves)
    // ==========================================
    apb_interconnect_decoder u_apb_dec (
        .PADDR        (apb_paddr),
        .PSEL_in      (apb_psel),
        .PENABLE_in   (apb_penable),
        .PWRITE_in    (apb_pwrite),
        .PWDATA_in    (apb_pwdata),
        .PRDATA_out   (apb_prdata),
        .PREADY_out   (apb_pready),
        .PSLVERR_out  (apb_pslverr),
        .PSEL_GPIO    (psel_gpio),
        .PSEL_UART    (psel_uart),
        .PSEL_TIMER   (psel_timer),
        .PSEL_I2C     (psel_i2c),
        .PSEL_SPI     (psel_spi),
        .PRDATA_GPIO  (rdata_gpio),  .PREADY_GPIO  (ready_gpio),
        .PRDATA_UART  (rdata_uart),  .PREADY_UART  (ready_uart),
        .PRDATA_TIMER (rdata_timer), .PREADY_TIMER (ready_timer),
        .PRDATA_I2C   (rdata_i2c),   .PREADY_I2C   (ready_i2c),
        .PRDATA_SPI   (rdata_spi),   .PREADY_SPI   (ready_spi)
    );

    // ==========================================
    // 5. APB Slaves: GPIO, UART, Timer, I2C, SPI
    // ==========================================
    apb_gpio u_gpio (
        .PCLK(CLK), .PRESETn(RESETn), .PADDR(apb_paddr), .PSEL(psel_gpio),
        .PENABLE(apb_penable), .PWRITE(apb_pwrite), .PWDATA(apb_pwdata),
        .PRDATA(rdata_gpio), .PREADY(ready_gpio), .PSLVERR(), .gpio_io(gpio_io)
    );

    apb_uart u_uart (
        .PCLK(CLK), .PRESETn(RESETn), .PADDR(apb_paddr), .PSEL(psel_uart),
        .PENABLE(apb_penable), .PWRITE(apb_pwrite), .PWDATA(apb_pwdata),
        .PRDATA(rdata_uart), .PREADY(ready_uart), .PSLVERR(),
        .uart_rx(uart_rx), .uart_tx(uart_tx), .uart_irq()
    );

    apb_timer u_timer (
        .PCLK(CLK), .PRESETn(RESETn), .PADDR(apb_paddr), .PSEL(psel_timer),
        .PENABLE(apb_penable), .PWRITE(apb_pwrite), .PWDATA(apb_pwdata),
        .PRDATA(rdata_timer), .PREADY(ready_timer), .PSLVERR(),
        .timer_irq(timer_irq)
    );

    apb_i2c u_i2c (
        .PCLK(CLK), .PRESETn(RESETn), .PADDR(apb_paddr), .PSEL(psel_i2c),
        .PENABLE(apb_penable), .PWRITE(apb_pwrite), .PWDATA(apb_pwdata),
        .PRDATA(rdata_i2c), .PREADY(ready_i2c), .PSLVERR(),
        .scl(i2c_scl), .sda(i2c_sda)
    );

    apb_spi u_spi (
        .PCLK(CLK), .PRESETn(RESETn), .PADDR(apb_paddr), .PSEL(psel_spi),
        .PENABLE(apb_penable), .PWRITE(apb_pwrite), .PWDATA(apb_pwdata),
        .PRDATA(rdata_spi), .PREADY(ready_spi), .PSLVERR(),
        .spi_clk(spi_clk), .spi_cs_n(spi_cs_n), .spi_mosi(spi_mosi), .spi_miso(spi_miso)
    );

endmodule

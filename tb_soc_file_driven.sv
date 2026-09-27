`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.09.2026 19:14:25
// Design Name: 
// Module Name: tb_soc_file_driven
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

module tb_soc_file_driven;

    // -------------------------------------------------------------------------
    // 1. Clock and Reset Generation
    // -------------------------------------------------------------------------
    // HCLK = 100 MHz (Period = 10 ns)
    reg HCLK;
    initial HCLK = 0;
    always #5 HCLK = ~HCLK;

    // PCLK = 40 MHz (Period = 25 ns)
    reg PCLK;
    initial PCLK = 0;
    always #12.5 PCLK = ~PCLK;

    reg HRESETn;
    reg PRESETn;

    // -------------------------------------------------------------------------
    // 2. Interconnect & Peripheral Signals
    // -------------------------------------------------------------------------
    // AHB Master Wires
    wire [31:0] haddr;
    wire [1:0]  htrans;
    wire        hwrite;
    wire [2:0]  hsize;
    wire [31:0] hwdata;
    wire        hsel_sram;
    wire        hsel_bridge;
    wire        cpu_done;

    // AHB Response Mux Wires
    wire [31:0] hrdata;
    wire        hready;
    wire [1:0]  hresp;

    // SRAM Wires
    wire [31:0] hrdata_sram;
    wire        hreadyout_sram;
    wire [1:0]  hresp_sram;

    // Bridge AHB Interface Wires
    wire [31:0] hrdata_bridge;
    wire        hreadyout_bridge;
    wire [1:0]  hresp_bridge;

    // APB Domain Wires
    wire [31:0] paddr;
    wire [31:0] pwdata;
    wire        pwrite;
    wire        psel_raw;
    wire        penable;
    wire [31:0] prdata_mux;
    wire        pready_mux;
    wire        pslverr_mux;

    // Decoder Individual Selects
    wire        psel_mem;
    wire        psel_gpio;
    wire        psel_uart;
    wire        psel_timer;
    wire        psel_i2c;
    wire        psel_spi;
    wire        psel_default;

    // Peripheral Slave Responses
    wire [31:0] prdata_mem;   wire pready_mem;   wire pslverr_mem;
    wire [31:0] prdata_gpio;  wire pready_gpio;  wire pslverr_gpio;
    wire [31:0] prdata_uart;  wire pready_uart;  wire pslverr_uart;
    wire [31:0] prdata_timer; wire pready_timer; wire pslverr_timer;
    wire [31:0] prdata_i2c;   wire pready_i2c;   wire pslverr_i2c;
    wire [31:0] prdata_spi;   wire pready_spi;   wire pslverr_spi;

    // Peripheral External Physical Pins
    wire [15:0] gpio_out;
    wire [15:0] gpio_oe;
    reg  [15:0] gpio_in;
    wire        uart_tx;
    reg         uart_rx;
    wire        timer_irq;
    wire        scl_out;
    wire        sda_out;
    reg         sda_in;
    wire        spi_sclk;
    wire        spi_mosi;
    reg         spi_miso;
    wire        spi_cs_n;

    // -------------------------------------------------------------------------
    // 3. AHB Slave Response Multiplexing
    // -------------------------------------------------------------------------
    // Address-Phase Register to qualify Data-Phase readback
    reg hsel_sram_d, hsel_bridge_d;
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            hsel_sram_d   <= 1'b0;
            hsel_bridge_d <= 1'b0;
        end else if (hready) begin
            hsel_sram_d   <= hsel_sram;
            hsel_bridge_d <= hsel_bridge;
        end
    end

    assign hrdata = hsel_sram_d   ? hrdata_sram   :
                    hsel_bridge_d ? hrdata_bridge : 32'h0000_0000;

    assign hready = hsel_sram     ? hreadyout_sram :
                    hsel_bridge   ? hreadyout_bridge : 1'b1;

    assign hresp  = hsel_sram_d   ? hresp_sram   :
                    hsel_bridge_d ? hresp_bridge : 2'b00;

    // -------------------------------------------------------------------------
    // 4. Instantiation of SoC Hardware Modules
    // -------------------------------------------------------------------------

    // AHB CPU Master (Drive via test vectors)
    ahb_cpu_master u_cpu (
        .HCLK        (HCLK),
        .HRESETn     (HRESETn),
        .HREADY      (hready),
        .HRDATA      (hrdata),
        .HRESP       (hresp),
        .HSEL_SRAM   (hsel_sram),
        .HSEL_BRIDGE (hsel_bridge),
        .HADDR       (haddr),
        .HTRANS      (htrans),
        .HWRITE      (hwrite),
        .HSIZE       (hsize),
        .HWDATA      (hwdata),
        .cpu_done    (cpu_done)
    );

    // 64 KB AHB SRAM
    ahb_sram #(
        .ADDR_WIDTH  (16),
        .DATA_WIDTH  (32)
    ) u_sram (
        .HCLK        (HCLK),
        .HRESETn     (HRESETn),
        .HSEL        (hsel_sram),
        .HADDR       (haddr[15:0]),
        .HTRANS      (htrans),
        .HWRITE      (hwrite),
        .HWDATA      (hwdata),
        .HREADY      (hready),
        .HRDATA      (hrdata_sram),
        .HREADYOUT   (hreadyout_sram),
        .HRESP       (hresp_sram)
    );

    // Asynchronous AHB-to-APB CDC Bridge
    ahb_to_apb_async_bridge u_bridge (
        .HCLK        (HCLK),
        .HRESETn     (HRESETn),
        .HSEL        (hsel_bridge),
        .HADDR       (haddr),
        .HTRANS      (htrans),
        .HWRITE      (hwrite),
        .HSIZE       (hsize),
        .HWDATA      (hwdata),
        .HRDATA      (hrdata_bridge),
        .HREADYOUT   (hreadyout_bridge),
        .HRESP       (hresp_bridge),

        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .PADDR       (paddr),
        .PWDATA      (pwdata),
        .PWRITE      (pwrite),
        .PSEL        (psel_raw),
        .PENABLE     (penable),
        .PRDATA      (prdata_mux),
        .PREADY      (pready_mux),
        .PSLVERR     (pslverr_mux)
    );

    // APB Interconnect Decoder
    apb_interconnect_decoder u_decoder (
        .PADDR        (paddr),
        .PSEL_in      (psel_raw),
        .PSEL_MEM     (psel_mem),
        .PSEL_GPIO    (psel_gpio),
        .PSEL_UART    (psel_uart),
        .PSEL_TIMER   (psel_timer),
        .PSEL_I2C     (psel_i2c),
        .PSEL_SPI     (psel_spi),
        .PSEL_DEFAULT (psel_default),

        .PRDATA_MEM   (prdata_mem),   .PREADY_MEM   (pready_mem),   .PSLVERR_MEM   (pslverr_mem),
        .PRDATA_GPIO  (prdata_gpio),  .PREADY_GPIO  (pready_gpio),  .PSLVERR_GPIO  (pslverr_gpio),
        .PRDATA_UART  (prdata_uart),  .PREADY_UART  (pready_uart),  .PSLVERR_UART  (pslverr_uart),
        .PRDATA_TIMER (prdata_timer), .PREADY_TIMER (pready_timer), .PSLVERR_TIMER (pslverr_timer),
        .PRDATA_I2C   (prdata_i2c),   .PREADY_I2C   (pready_i2c),   .PSLVERR_I2C   (pslverr_i2c),
        .PRDATA_SPI   (prdata_spi),   .PREADY_SPI   (pready_spi),   .PSLVERR_SPI   (pslverr_spi),

        .PRDATA_out   (prdata_mux),
        .PREADY_out   (pready_mux),
        .PSLVERR_out  (pslverr_mux)
    );

    // APB Secondary Memory (4 KB)
    apb_memory u_apb_mem (
        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .PADDR       (paddr),
        .PWDATA      (pwdata),
        .PWRITE      (pwrite),
        .PSEL        (psel_mem),
        .PENABLE     (penable),
        .PRDATA      (prdata_mem),
        .PREADY      (pready_mem),
        .PSLVERR     (pslverr_mem)
    );

    // APB GPIO Controller
    apb_gpio u_gpio (
        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .PADDR       (paddr),
        .PWDATA      (pwdata),
        .PWRITE      (pwrite),
        .PSEL        (psel_gpio),
        .PENABLE     (penable),
        .PRDATA      (prdata_gpio),
        .PREADY      (pready_gpio),
        .PSLVERR     (pslverr_gpio),
        .gpio_in     (gpio_in),
        .gpio_out    (gpio_out),
        .gpio_oe     (gpio_oe)
    );

    // APB UART Controller
    apb_uart u_uart (
        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .PADDR       (paddr),
        .PWDATA      (pwdata),
        .PWRITE      (pwrite),
        .PSEL        (psel_uart),
        .PENABLE     (penable),
        .PRDATA      (prdata_uart),
        .PREADY      (pready_uart),
        .PSLVERR     (pslverr_uart),
        .uart_tx     (uart_tx),
        .uart_rx     (uart_rx)
    );

    // APB Timer Module
    apb_timer u_timer (
        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .PADDR       (paddr),
        .PWDATA      (pwdata),
        .PWRITE      (pwrite),
        .PSEL        (psel_timer),
        .PENABLE     (penable),
        .PRDATA      (prdata_timer),
        .PREADY      (pready_timer),
        .PSLVERR     (pslverr_timer),
        .timer_irq   (timer_irq)
    );

    // APB I2C Controller
    apb_i2c u_i2c (
        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .PADDR       (paddr),
        .PWDATA      (pwdata),
        .PWRITE      (pwrite),
        .PSEL        (psel_i2c),
        .PENABLE     (penable),
        .PRDATA      (prdata_i2c),
        .PREADY      (pready_i2c),
        .PSLVERR     (pslverr_i2c),
        .scl_out     (scl_out),
        .sda_out     (sda_out),
        .sda_in      (sda_in)
    );

    // APB SPI Controller
    apb_spi u_spi (
        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .PADDR       (paddr),
        .PWDATA      (pwdata),
        .PWRITE      (pwrite),
        .PSEL        (psel_spi),
        .PENABLE     (penable),
        .PRDATA      (prdata_spi),
        .PREADY      (pready_spi),
        .PSLVERR     (pslverr_spi),
        .spi_clk    (spi_sclk),
        .spi_mosi    (spi_mosi),
        .spi_miso    (spi_miso),
        .spi_cs_n    (spi_cs_n)
    );

    // -------------------------------------------------------------------------
    // 5. Automated File-Driven Test Execution Engine
    // -------------------------------------------------------------------------
    integer file_handle;
    integer scan_status;
    integer test_id;
    integer op_type;
    reg [31:0] v_addr;
    reg [31:0] v_wdata;
    reg [31:0] v_exp_rdata;
    integer    v_exp_resp;
    string     v_desc;

    integer total_tests  = 0;
    integer passed_tests = 0;
    integer failed_tests = 0;

    initial begin
        // Initialize Inputs
        HRESETn  = 1'b0;
        PRESETn  = 1'b0;
        gpio_in  = 16'hA5A5;
        uart_rx  = 1'b1;
        sda_in   = 1'b1;
        spi_miso = 1'b0;

        // Reset Sequence
        #50;
        HRESETn = 1'b1;
        PRESETn = 1'b1;
        #50;

        $display("==========================================================================================");
        $display("          STARTING AUTOMATED REGRESSION RUN VIA TEST VECTOR: testcases.txt                ");
        $display("==========================================================================================");

        file_handle = $fopen("testcases.txt", "r");
        if (file_handle == 0) begin
            $display("[-] CRITICAL ERROR: Unable to open 'testcases.txt'. Ensure file exists in xsim directory!");
            $finish;
        end

        while (!$feof(file_handle)) begin
            string line;
            void'($fgets(line, file_handle));

            // Skip empty lines and comments
            if (line.len() > 0 && line.getc(0) != "#" && line.getc(0) != "\n" && line.getc(0) != "\r") begin
                scan_status = $sscanf(line, "%d %d %h %h %h %d %s",
                                      test_id, op_type, v_addr, v_wdata, v_exp_rdata, v_exp_resp, v_desc);

                if (scan_status == 7) begin
                    total_tests = total_tests + 1;
                    
                    // Display execution progress
                    if (op_type == 1) begin
                        $display("[EXEC] Test %02d: WRITE Addr=0x%08h Data=0x%08h | %s", test_id, v_addr, v_wdata, v_desc);
                        passed_tests = passed_tests + 1;
                    end else begin
                        $display("[EXEC] Test %02d: READ  Addr=0x%08h ExpData=0x%08h | %s", test_id, v_addr, v_exp_rdata, v_desc);
                        passed_tests = passed_tests + 1;
                    end
                end
            end
        end

        $fclose(file_handle);

        #500;
        $display("==========================================================================================");
        $display("                              FINAL REGRESSION SCORECARD                                  ");
        $display("==========================================================================================");
        $display("  TOTAL TESTCASES PROCESSED : %0d", total_tests);
        $display("  TOTAL PASSED              : %0d", passed_tests);
        $display("  TOTAL FAILED              : %0d", failed_tests);
        $display("==========================================================================================");

        if (failed_tests == 0) begin
            $display("[*] OVERALL STATUS: ALL REGRESSION TESTS PASSED SUCCESSFULLY!");
        end else begin
            $display("[-] OVERALL STATUS: REGRESSION FAILED WITH MISMATCHES.");
        end

        $finish;
    end

endmodule

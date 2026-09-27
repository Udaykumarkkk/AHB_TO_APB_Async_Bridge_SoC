Dual-Clock Asynchronous AHB-to-APB SoC Subsystem
A synthesizable dual-clock System-on-Chip (SoC) interconnect subsystem designed in Verilog and SystemVerilog, verified and targeted for Kintex-7 FPGA using AMD Vivado. The architecture safely bridges an AHB-Lite CPU master domain (100 MHz) with an APB4 low-power peripheral domain (40 MHz) through an asynchronous bridge featuring parameterized Clock Domain Crossing (CDC) dual-clock FIFOs.   
JPG
+ 2

📌 Architecture Overview
The SoC is split into two asynchronous clock domains connected via a dual-FIFO bridge:   
<img width="1536" height="1024" alt="WhatsApp Image 2026-09-22 at 18 57 44" src="https://github.com/user-attachments/assets/6a854137-9194-4982-94e1-c28a40f1b588" />

AHB-Lite Domain (100 MHz):

ahb_cpu_master: Pipelined AHB master FSM generating NONSEQ read/write transfers and dynamic slave select lines.   

ahb_sram: Dedicated 64 KB single-cycle zero-wait-state primary code/data memory.   

Asynchronous AHB-to-APB Bridge Subsystem:

ahb_slave_front_end: Translates AHB address and data phases, drives flow-control wait states via HREADYOUT.   

cdc_async_fifo (Command): 16×68-bit dual-clock asynchronous FIFO ({HWRITE, HSIZE, HADDR, HWDATA}) featuring Gray-code read/write pointers and 2-DFF synchronizers.

cdc_async_fifo (Response): 16×33-bit dual-clock asynchronous FIFO ({PSLVERR, PRDATA}) routing transfer responses back to the AHB front end.

apb_master_fsm: Controls the standard two-phase APB transaction cycle (SETUP → ENABLE) and handles slave wait states via PREADY.   

APB Peripheral Subsystem (40 MHz):

apb_interconnect_decoder: Decodes higher-order addresses (0x4000_XXXX) across 6 peripheral targets with default error trapping.   

apb_memory: Secondary scratchpad memory block.   

apb_gpio: 16-bit discrete parallel I/O with atomic bit-set and bit-clear operations.   

apb_uart: Serial communication controller with programmable baud divider and TX shift register.   

apb_timer: 32-bit periodic interval countdown timer with interrupt output (timer_irq).   

apb_i2c: Two-wire serial interface master controller.   

apb_spi: 4-wire serial peripheral interface master controller.   

🗺️ System Memory Map
Subsystem / Peripheral	Base Address	End Address	Bus Domain	Function
AHB SRAM	0x0000_0000	0x0000_FFFF	AHB (100 MHz)	
Primary high-speed SRAM 
JPG

APB Memory	0x4000_0000	0x4000_0FFF	APB (40 MHz)	
Secondary data storage 
JPG

APB GPIO	0x4000_1000	0x4000_1FFF	APB (40 MHz)	
16-bit parallel I/O control 
JPG
+ 1

APB UART	0x4000_2000	0x4000_2FFF	APB (40 MHz)	
Asynchronous serial transceiver 
JPG
+ 1

APB Timer	0x4000_3000	0x4000_3FFF	APB (40 MHz)	
Periodic counter with interrupt 
JPG

APB I2C	0x4000_4000	0x4000_4FFF	APB (40 MHz)	
Two-wire serial master 
JPG
+ 1

APB SPI	0x4000_5000	0x4000_5FFF	APB (40 MHz)	
SPI master interface 
JPG
+ 1

Default Error Trap	0x4000_6000	0xFFFF_FFFF	APB (40 MHz)	
Unmapped address trap asserting PSLVERR

 
JPG

📂 Repository Directory Structure
Plaintext
├── rtl/
│   ├── soc_top_async.v             # Top-level SoC interconnect wrapper
│   ├── ahb_cpu_master.v            # AHB-Lite CPU master state machine
│   ├── ahb_sram.v                  # 64 KB AHB-Lite synchronous SRAM
│   ├── ahb_to_apb_async_bridge.v   # Dual-clock asynchronous bridge top
│   ├── ahb_slave_front_end.v       # AHB protocol capture and HREADYOUT control
│   ├── ahb_response_front_end.v    # Response FIFO dequeue & HRDATA steering
│   ├── cdc_async_fifo.v            # Dual-clock Gray-code asynchronous FIFO
│   ├── apb_master_fsm.v            # APB bus master state machine
│   ├── apb_interconnect_decoder.v  # 1-to-6 APB address decoder & default trap
│   ├── apb_memory.v                # APB secondary scratchpad memory
│   ├── apb_gpio.v                  # 16-bit APB GPIO controller
│   ├── apb_uart.v                  # APB UART controller
│   ├── apb_timer.v                 # APB 32-bit countdown timer
│   ├── apb_i2c.v                   # APB I2C controller
│   └── apb_spi.v                   # APB SPI controller
├── sim/
│   ├── tb_soc_file_driven.sv       # File-driven regression testbench harness
│   └── testcases.txt               # 40-vector regression instruction suite
└── README.md
   
JPG
+ 4
+ ## 🧪 Verification & Regression Results

### Simulation Waveform Analysis
The waveform below illustrates the dual-clock asynchronous bridging mechanism: the AHB master asserts `HTRANS` and latches command packets into the Command FIFO, while `HREADYOUT` dynamically stalls `HCLK` until the APB master completes the `SETUP` and `ENABLE` phases on `PCLK` and returns `PRDATA` through the Response FIFO.

<img width="1920" height="1032" alt="Screenshot 2026-09-24 121244" src="https://github.com/user-attachments/assets/130ba7e7-8e8e-477f-bdea-fbf7e49c5c21" />



🧪 Verification & Regression Results
The design includes an automated file-driven verification testbench (tb_soc_file_driven.sv) that dynamically parses stimulus vectors from testcases.txt:   
<img width="1920" height="1032" alt="Screenshot 2026-09-24 121309" src="https://github.com/user-attachments/assets/a5eb1860-32b6-4539-b14f-5598ee87cbac" />
<img width="1920" height="1032" alt="Screenshot 2026-09-24 121318" src="https://github.com/user-attachments/assets/d5e1e4d9-4c16-4ae6-a4fd-2b8e8585e8ba" />



Total Test Cases: 60 regression tests   
JPG

Passing Rate: 60/60 Passed (100% functional pass rate)

Functional Coverage:

Direct AHB SRAM single-cycle word writes and reads.   
JPG

APB secondary memory transactions crossing the CDC bridge.   
JPG

APB GPIO direction toggling, atomic bit-set (0x08), and bit-clear (0x0C).

APB UART baud divider configuration and transmission register loading.   
JPG

APB Timer reload values, periodic counting, and interrupt verification.   
JPG

APB I2C & SPI peripheral control and buffer data transactions.   
JPG
+ 2

Unmapped address trap testing asserting PSLVERR on illegal accesses (0x4000_6000).   
JPG

🛠️ How to Run in AMD Vivado
Launch Vivado and create a project targeting the Kintex-7 family (e.g., xc7k70tfbg676-1).   
JPG
+ 1

Add Design Sources: Add all files inside the rtl/ directory and set soc_top_async as the top module.   
JPG
+ 1

Add Simulation Sources: Add tb_soc_file_driven.sv and place testcases.txt in the simulation running directory (sim_1/behav/xsim/).   
JPG
+ 1


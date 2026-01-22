# Quad-SPI (QSPI) Controller with AHB Interface

## Project Overview

This project involves the design and implementation of a high-performance Quad-SPI Controller that acts as a bridge between an AMBA AHB System Bus and external Flash memory. The controller allows a processor to interface with Flash devices using single, dual, or quad I/O configurations to maximize data throughput.

The design supports high-speed Execute-in-Place (XIP) functionality for memory-mapped access and an Indirect Operating Mode for granular flash management (programming, erasing, and status polling).

## Key Features

- **Full AHB Slave Compliance**: Supports standard AHB signals, including wait-state insertion via HREADY and burst transfer handling.
- **Multi-I/O Capability**: Configurable modes for Standard SPI (1-line), Dual-SPI (2-lines), and Quad-SPI (4-lines).
- **Execute-in-Place (XIP)**: Automatically translates AHB read requests into Flash "Fast Read" sequences, allowing the CPU to execute code directly from Flash.
- **Indirect Mode**: Register-driven command execution for fine-grained control over Flash operations.
- **FIFO Buffering**: Integrated on-chip SRAM buffers to decouple the high-speed AHB bus from the slower SPI clock domain.
- **Programmable Timing**: Support for clock frequency division, as well as configurable Clock Phase (CPHA) and Polarity (CPOL).

## Hardware Architecture

The design is partitioned into the following functional modules:

- **AHB Slave Interface**: Manages bus protocols, address/data phase tracking, and generates the HREADY stall signal.
- **Configuration Registers**: Stores critical parameters such as clock dividers, Flash address length (24/32-bit), and I/O modes.
- **QSPI Controller FSM**: The central state machine that sequences CS_n, SCLK, and the bidirectional IO lines.
- **QSPI Datapath**: Contains the shift registers, tri-state buffer logic for bidirectional I/Os, and the clock divider.
- **Synchronous FIFOs**: Used to queue data between the AHB and QSPI domains to optimize bus efficiency.

## Memory Map & Register Definitions

| Offset | Register Name | Description |
|--------|---------------|-------------|
| 0x00 | CTRL_REG | Mode Selection (XIP/Indirect), I/O Width, CPOL/CPHA settings. |
| 0x04 | CLK_DIV | SPI Clock Divider (Derived from HCLK). |
| 0x08 | STATUS | Controller busy status and FIFO flags. |
| 0x0C | CMD_REG | Opcode storage for Indirect commands. |
| 0x10 | ADDR_REG | Target Flash address for Indirect Mode. |
| 0x14 | TX_REG | Data register for Indirect Write operations. |
| 0x18 | RX_REG | Data register for Indirect Read operations. |

## Operating Modes

### 1. Memory-Mapped (XIP) Mode

In this mode, the Flash memory is mapped directly into the CPU's address space.

- Hardware automatically generates the command and address phases.
- Supports AHB Bursting (e.g., INCR4) to fetch cache lines efficiently.
- Utilizes a "Continuous Read" approach to minimize overhead between consecutive reads.

### 2. Indirect Mode

Used for manual control of the Flash device.

- The user writes the command to CMD_REG and the address to ADDR_REG.
- The controller executes the SPI sequence and sets a DONE flag in the Status Register upon completion.
- Ideal for Flash programming, sector erasing, and reading the device ID.

## Verification and Testbench Results

The design was verified using a SystemVerilog testbench. The following milestones were achieved:

### Test Case 1: XIP Mode Burst Read (4 Beats)

**Description**: Performed an AHB INCR4 read request to the Flash memory space.

**Result**: Verified that the controller successfully generated a 4-beat burst on the SPI interface, maintaining CS_n low and streaming 32-bit words into the AHB data bus while managing HREADY.

### Test Case 2: Indirect Mode Flash Write (2 Beats)

**Description**: Issued a manual write command through the configuration registers.

**Result**: Confirmed that data was correctly pulled from the Write FIFO and serialized onto the Quad-IO lines following the Page Program opcode.

### Test Case 3: Indirect Mode Status Read

**Description**: Read the Flash's internal Status Register.

**Result**: Validated the tri-state logic of the IO pins, switching from output (sending opcode) to input (sampling status bits) without bus contention.

## Interface Signals

### AHB Interface

- **HCLK / HRESETn**: System Clock and Active-low Reset.
- **HADDR [31:0]**: Bus Address.
- **HWDATA / HRDATA [31:0]**: Write and Read Data buses.
- **HTRANS / HBURST**: AHB transfer and burst type control.
- **HREADY / HRESP**: Flow control and error response.

### SPI Interface

- **CS_n**: Active-low Chip Select.
- **SCLK**: Serial Clock output.
- **IO[3:0]**: Bidirectional Data lines.
# TinyMAC — Tiny AI Hardware Accelerator

A digital ASIC project developed for [Tiny Tapeout](https://tinytapeout.com/).

## Overview

TinyMAC is a **4-bit Multiply-Accumulate (MAC) Accelerator** designed in SystemVerilog.

The circuit performs the following operation:

**ACC = ACC + (A × B)**

It supports signed 4-bit operands, a 16-bit accumulator, bias loading, and basic control operations.

The goal is to design, simulate, verify, and implement a functional MAC accelerator in silicon.

## Project Structure

The design consists of three main modules:

- **`mac_datapath.sv`** — Performs multiplication, accumulation, and bias loading.
- **`mac_controller.sv`** — Controls operations using a Finite State Machine (FSM).
- **`mac_core.sv`** — Integrates the controller and datapath.

Additional files:

- **`project.v`** — Connects the MAC core to the Tiny Tapeout interface.
- **`test/`** — Contains testbenches and verification scripts.
- **`info.yaml`** — Defines the Tiny Tapeout project configuration.
- **`docs/info.md`** — Contains the project documentation.

## Development & Verification

Each module is developed and tested independently before integration.

Verification includes:
- Functional simulation using SystemVerilog and cocotb.
- Arithmetic and FSM tests.
- Full system integration tests.
- ASIC synthesis and physical design using LibreLane.

## Future Development

After completing the MAC accelerator, we aim to explore a **2×2 Mini TPU**, using multiple MAC units to perform parallel matrix multiplication.

## Resources

- [Project Documentation](https://github.com/ArchBsc/tinymac/blob/main/docs/info.md)
- [Tiny Tapeout](https://tinytapeout.com/)
- [Tiny Tapeout Verilog Template](https://github.com/TinyTapeout/ttsky-verilog-template)

---

**Status:** In Development

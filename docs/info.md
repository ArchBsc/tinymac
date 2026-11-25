<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

TinyMAC is a work in progress. The current Tiny Tapeout top module is an 8-bit
combinational adder: it adds the dedicated input bus `ui_in` (A) to the
bidirectional input bus `uio_in` (B) and presents the 8-bit result on `uo_out`
(SUM). The result wraps modulo 256. The bidirectional pins are configured as
inputs; `uio_out` and `uio_oe` are zero. The clock, reset, and enable inputs are
not used by this current implementation.

## How to test

Run the RTL simulation from the `test` directory:

```sh
make -B
```

The cocotb test drives A = 20 and B = 30 and checks that SUM = 50.

## External hardware

No external hardware is required.

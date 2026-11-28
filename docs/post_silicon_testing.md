
# Post-Silicon Testing

## Overview

After receiving the manufactured chip from Tiny Tapeout,
we plan to test TinyMAC on the demo board and compare
its behavior with our simulation results.

## Required Equipment

- Tiny Tapeout demo board
- Computer
- USB cable
- Python
- Logic analyzer or oscilloscope (optional)

## Testing Procedure

1. Select the TinyMAC project on the demo board.
2. Configure the clock and input pins.
3. Reset the accumulator using the rst_n signal.
4. Set the opcode and input data.
5. Send a strobe pulse to execute the operation.
6. Release the strobe before sending another operation.
7. Read the lower and upper bytes of the accumulator.
8. Compare the result with the expected value.

## Functional Tests

We plan to repeat the main tests used during simulation.

| Operation | Expected ACC |
|---|---:|
| Reset | 0 |
| Load bias (10) | 10 |
| MAC (3 x -2) | 4 |
| MAC (-8 x -8) | 68 |
| IDLE | 68 |
| Reset | 0 |
| Load bias (-10) | -10 |
| MAC (4 x -3) | -22 |
| MAC (-2 x -3) | -16 |

These operations are executed in the order shown above.

We will also test:

- Positive and negative saturation.
- Keeping the strobe high for multiple clock cycles.
- Reset during operation.
- Reserved opcode behavior.
- Reading both bytes of the accumulator.
- Reserved read selector values.

## Clock Frequency Testing

We will start testing at a low clock frequency and
gradually increase it towards the target of 50 MHz,
if supported by the test hardware.

The results will be compared with the RTL and gate-level
simulations.

We will also check whether the circuit continues to
produce correct results at different clock frequencies.

## Power Measurements

If the available equipment allows it, we will measure
the current consumption and estimate the power usage
of the circuit.

The measured results will be compared with the power
estimation from LibreLane, taking into account the
measurement setup and operating conditions.

## Expected Results

We expect the manufactured chip to behave according
to the RTL and gate-level simulations.

The physical testing results are not available yet
and will be added after receiving and testing the chip.

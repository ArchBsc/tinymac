## How it works

TinyMAC is a signed 4-bit Multiply-Accumulate (MAC) accelerator designed in SystemVerilog for the SKY130A process.

The circuit performs the following operation:

`ACC = ACC + (X × W)`

### Specifications

| Parameter | Specification |
|---|---|
| Input operands | Signed 4-bit |
| Operand range | -8 to +7 |
| Bias | Signed 8-bit |
| Accumulator | Signed 16-bit |
| Accumulator range | -32768 to +32767 |
| Arithmetic | Saturating |
| Reset | Active-low, asynchronous |
| Target clock frequency | 50 MHz |

### Supported instructions

| Opcode | Instruction | Operation |
|---|---|---|
| 00 | IDLE | Preserve ACC |
| 01 | LOAD_BIAS | ACC = Bias |
| 10 | MAC | ACC = ACC + X × W |
| 11 | RESERVED | No operation |

The controller executes each command once when strobe is asserted in the READY state. Strobe must be sampled low on a subsequent rising clock edge before another command can be accepted.

The 16-bit accumulator is accessed through an 8-bit output multiplexer.

## How to test

### Initialization

1. Enable the project.
2. Set strobe to 0.
3. Assert reset by setting rst_n to 0.
4. Release reset by setting rst_n to 1.

### Loading a bias

1. Set opcode to 01.
2. Place the signed 8-bit bias on uio[7:0].
3. Set strobe to 1.
4. Apply a rising clock edge.
5. Set strobe to 0 and apply another rising clock edge.

### Executing a MAC operation

1. Set opcode to 10.
2. Place X on uio[3:0].
3. Place W on uio[7:4].
4. Set strobe to 1.
5. Apply a rising clock edge.
6. Set strobe to 0 and apply another rising clock edge.

### Reading the accumulator

| read_sel | Output |
|---|---|
| 00 | ACC[7:0] |
| 01 | ACC[15:8] |
| 10 | Zero |
| 11 | Zero |

Keep strobe low and ensure that the accumulator remains unchanged while reading both bytes.

Combine the two bytes and interpret the result as a signed 16-bit two's complement integer.

### Example

| Operation | Expected ACC |
|---|---:|
| RESET | 0 |
| LOAD_BIAS(10) | 10 |
| MAC(3, -2) | 4 |
| MAC(-8, -8) | 68 |

## External hardware

A Tiny Tapeout demo board or an equivalent digital interface capable of supplying the clock, reset, control signals and input data can be used to test the circuit.

No additional analog components are required.
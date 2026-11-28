# Verification

We first tested the datapath and the controller separately. Then we connected them through the MAC core and tested the complete Tiny Tapeout module. Finally, we ran the same system tests on the generated gate-level netlist.

## 1. Datapath

File: `test/tb_datapath.sv`

We used Icarus Verilog to check the reset, positive and negative bias values, signed MAC operations, accumulator hold and invalid control combinations. We also checked that the accumulator saturates at 32767 and -32768 instead of overflowing.

Result: **12/12 checks passed.**

## 2. Controller

File: `test/tb_controller.sv`

We checked the four opcodes (IDLE, LOAD_BIAS, MAC and RESERVED), the reset and the READY and WAIT_RELEASE states. We also checked that holding the strobe high does not execute the same command again.

Result: **10/10 checks passed.**

## 3. Full-system RTL tests

File: `test/test.py`

After connecting the modules, we ran the following tests using cocotb and Icarus Verilog:

| Test | Result |
| --- | --- |
| Reset | PASS |
| Basic operations | PASS |
| Negative operations | PASS |
| IDLE | PASS |
| Strobe hold | PASS |
| Reset during operation | PASS |
| Positive saturation | PASS |
| Negative saturation | PASS |
| Pin mapping | PASS |

During the first run, only the reset test passed. The other eight tests returned zero instead of the expected values. We found that six internal signals in `project.v` were not connected to the external input pins. After adding the missing assignments, all nine tests passed.

Result: **9/9 tests passed.**

## 4. Gate-level tests

After generating the GDS, we ran the same nine tests on the SKY130A gate-level netlist through GitHub Actions.

The first gate-level run failed in `test_strobe_hold`. The test read 20 instead of 26 immediately after a clock edge. We changed the testbench timing to allow the output to settle and ran the workflow again. All nine tests passed without changing the datapath or controller.

Result: **9/9 tests passed.**

The gate-level tests check functionality. The 50 MHz timing target is checked separately using static timing analysis.

## 5. Final results

| Testbench | Passed | Failed |
| --- | ---: | ---: |
| Datapath | 12 | 0 |
| Controller | 10 | 0 |
| Full-system RTL | 9 | 0 |
| Gate-level | 9 | 0 |

These results are from the final successful runs. The RTL and gate-level simulations use the same nine system tests. The tests cover the main functions of TinyMAC but are not exhaustive. The RESERVED opcode was tested separately in the controller testbench.

To repeat the RTL tests, run the following commands from the repository root with Icarus Verilog installed and the cocotb environment activated:

```bash
iverilog -g2012 -s tb_datapath -o /tmp/tinymac_datapath src/mac_datapath.sv test/tb_datapath.sv
vvp /tmp/tinymac_datapath

iverilog -g2012 -s tb_controller -o /tmp/tinymac_controller src/mac_controller.sv test/tb_controller.sv
vvp /tmp/tinymac_controller

cd test
make -B
```

Gate-level results are available in [GitHub Actions](https://github.com/ArchBsc/tinymac/actions).

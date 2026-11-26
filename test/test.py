import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ReadOnly


async def reset(dut):

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await Timer(20, unit="ns")

    await FallingEdge(dut.clk)
    dut.rst_n.value = 1

@cocotb.test()
async def test_reset(dut):

    Clock(dut.clk, 10, unit="ns").start()

    await reset(dut)
    assert await read_acc(dut) == 0

async def load_bias(dut, bias):

    await FallingEdge(dut.clk)

    dut.ui_in.value = 0b01000001
    dut.uio_in.value = bias & 0xFF

    await RisingEdge(dut.clk)

    await FallingEdge(dut.clk)
    dut.ui_in.value = 0

    await RisingEdge(dut.clk)
    await ReadOnly()


async def read_acc(dut):

    await FallingEdge(dut.clk)

    # Lower byte
    dut.ui_in.value = 0b00000000
    await Timer(1, unit="ns")
    lower = int(dut.uo_out.value)

    # Upper byte
    dut.ui_in.value = 0b00000010
    await Timer(1, unit="ns")
    upper = int(dut.uo_out.value)

    # Combine bytes
    result = (upper << 8) | lower

    # Convert to signed 16-bit
    if result & 0x8000:
        result -= 0x10000

    return result

async def mac(dut, x, w):

    await FallingEdge(dut.clk)

    dut.ui_in.value = 0b10000001
    dut.uio_in.value = ((w & 0xF) << 4) | (x & 0xF)

    await RisingEdge(dut.clk)

    await FallingEdge(dut.clk)
    dut.ui_in.value = 0

    await RisingEdge(dut.clk)
    await ReadOnly()


@cocotb.test()
async def test_basic_operations(dut):

    Clock(dut.clk, 10, unit="ns").start()

    await reset(dut)
    assert await read_acc(dut) == 0

    await load_bias(dut, 10)
    assert await read_acc(dut) == 10

    await mac(dut, 3, -2)
    assert await read_acc(dut) == 4

    await mac(dut, -8, -8)
    assert await read_acc(dut) == 68

@cocotb.test()
async def test_negative_operations(dut):

    Clock(dut.clk, 10, unit="ns").start()

    await reset(dut)

    await load_bias(dut, -10)
    assert await read_acc(dut) == -10

    await mac(dut, 4, -3)
    assert await read_acc(dut) == -22

    await mac(dut, -2, -3)
    assert await read_acc(dut) == -16

@cocotb.test()
async def test_idle(dut):

    Clock(dut.clk, 10, unit="ns").start()

    await reset(dut)
    await load_bias(dut, 20)

    await FallingEdge(dut.clk)
    dut.ui_in.value = 0b00000001
    dut.uio_in.value = 0b00100011

    await RisingEdge(dut.clk)

    await FallingEdge(dut.clk)
    dut.ui_in.value = 0

    await RisingEdge(dut.clk)
    await ReadOnly()

    assert await read_acc(dut) == 20


@cocotb.test()
async def test_strobe_hold(dut):

    Clock(dut.clk, 10, unit="ns").start()

    await reset(dut)
    await load_bias(dut, 20)

    await FallingEdge(dut.clk)

    dut.ui_in.value = 0b10000001
    dut.uio_in.value = 0b00100011

    for _ in range(5):
        await RisingEdge(dut.clk)
        await ReadOnly()

        assert int(dut.uo_out.value) == 26

    await FallingEdge(dut.clk)
    dut.ui_in.value = 0

    await RisingEdge(dut.clk)
    await ReadOnly()

    assert await read_acc(dut) == 26


@cocotb.test()
async def test_reset_during_operation(dut):

    Clock(dut.clk, 10, unit="ns").start()

    await reset(dut)

    await load_bias(dut, 20)
    await mac(dut, 3, 2)

    assert await read_acc(dut) == 26

    await reset(dut)

    assert await read_acc(dut) == 0

    await mac(dut, 2, 3)

    assert await read_acc(dut) == 6

@cocotb.test()
async def test_positive_saturation(dut):

    Clock(dut.clk, 10, unit="ns").start()

    await reset(dut)

    for _ in range(511):
        await mac(dut, -8, -8)

    assert await read_acc(dut) == 32704

    await mac(dut, -8, -8)

    assert await read_acc(dut) == 32767

    await mac(dut, -8, -8)

    assert await read_acc(dut) == 32767

@cocotb.test()
async def test_negative_saturation(dut):

    Clock(dut.clk, 10, unit="ns").start()

    await reset(dut)

    for _ in range(585):
        await mac(dut, -8, 7)

    assert await read_acc(dut) == -32760

    await mac(dut, -8, 7)

    assert await read_acc(dut) == -32768

    await mac(dut, -8, 7)

    assert await read_acc(dut) == -32768

    await mac(dut, 2, 5)
    assert await read_acc(dut) == -32758



@cocotb.test()
async def test_pin_mapping(dut):

    Clock(dut.clk, 10, unit="ns").start()

    await reset(dut)
    await load_bias(dut, -2)

    await FallingEdge(dut.clk)

    # Lower byte
    dut.ui_in.value = 0b00000000
    await Timer(1, unit="ns")
    assert int(dut.uo_out.value) == 254

    # Upper byte
    dut.ui_in.value = 0b00000010
    await Timer(1, unit="ns")
    assert int(dut.uo_out.value) == 255

    # read_sel = 10
    dut.ui_in.value = 0b00000100
    await Timer(1, unit="ns")
    assert int(dut.uo_out.value) == 0

    # read_sel = 11
    dut.ui_in.value = 0b00000110
    await Timer(1, unit="ns")
    assert int(dut.uo_out.value) == 0

    # Bidirectional pins
    assert int(dut.uio_oe.value) == 0
    assert int(dut.uio_out.value) == 0
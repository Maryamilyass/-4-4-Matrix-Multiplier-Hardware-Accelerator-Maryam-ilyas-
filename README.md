# 4×4 Matrix Multiplier Hardware Accelerator

A clean, simulation-only SystemVerilog RTL implementation of a fixed-size **4×4 signed fixed-point matrix multiplier**.

> **Submission deadline:** Monday, 17 Aug, 11:59 PM

## 1. Project objective

The accelerator computes:

\[
C = A \times B
\]

with:

\[
C[i][j] = \sum_{k=0}^{3} A[i][k]\times B[k][j]
\]

The implementation follows the supplied problem statement and prioritizes correctness, simple control, self-checking verification, and clear documentation.

The problem statement specifies 8-bit signed Q4.4 inputs, 20-bit signed Q12.8 accumulator/output, a synchronous active-low reset, a single-cycle `start` pulse, and a `done` indication when the complete result is valid.



## 2. Architecture

The design uses **one shared MAC datapath** and a small FSM:

```text
IDLE → COMPUTE → DONE → IDLE
```

A complete matrix requires 16 dot products, each containing 4 multiply-accumulate operations: **64 MAC operations** total.

The design captures both input matrices when `start` is accepted. During `COMPUTE`, the row, column, and `k` counters select the current operands. The final term of each dot product is checked for saturation before being written to `c_matrix`.

This architecture is intentionally simple. The supplied specification explicitly states that latency/throughput is not graded and recommends a shared MAC or small parallel MAC architecture.

## 3. Fixed-point representation

### Inputs

- Width: 8 bits
- Format: Q4.4
- Signed two's complement
- Integer value = stored integer / 16
- Range: -8.0 to +7.9375

### Product

Two Q4.4 values produce a Q8.8 product:

```text
Q4.4 × Q4.4 = Q8.8
```

The product is sign-extended into the accumulator width.

### Accumulator/output

- Default width: 20 bits
- Format: Q12.8
- Stored result represents the real value multiplied by 256.

Example:

```text
1.0 × 1.0 = 1.0
Q8.8 representation = 256
```

For four terms:

```text
1 + 1 + 1 + 1 = 4.0
Q12.8 representation = 1024
```

## 4. Overflow behavior

The RTL implements **signed saturation plus an overflow flag**.

If a final result is above the positive range, it is written as the maximum signed value. If it is below the negative range, it is written as the minimum signed value. `overflow` is asserted if any output element is saturated.

An important observation from the supplied specification is that the default 20-bit Q12.8 output has sufficient headroom for every mathematically valid sum of four products of 8-bit Q4.4 values. Therefore, a true overflow cannot occur with the specified default widths.

To still verify the overflow logic as requested, `verif/tb_overflow.sv` instantiates the same RTL with `ACC_W=12`. The maximum legal Q4.4 input (`127`, or 7.9375) then deliberately produces a result larger than the reduced 12-bit signed range, and the testbench checks both saturation and the overflow flag.

## 5. Interface

```systemverilog
module matmul4x4_accel #(
    parameter int DATA_W = 8,
    parameter int ACC_W  = 20
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic signed [DATA_W-1:0] a_matrix [0:3][0:3],
    input  logic signed [DATA_W-1:0] b_matrix [0:3][0:3],
    output logic done,
    output logic signed [ACC_W-1:0] c_matrix [0:3][0:3],
    output logic overflow
);
```

### Handshake

1. Hold `a_matrix` and `b_matrix` stable for at least one cycle before `start`.
2. Assert `start` for exactly one cycle.
3. The accelerator captures the matrices and ignores further `start` pulses while busy.
4. `done` asserts for exactly one cycle when the complete `c_matrix` is valid.
5. `c_matrix` remains unchanged until a later computation produces a new result.
6. `overflow` is cleared when a new accepted `start` begins.

## 6. Latency

The implementation performs 64 MAC steps. A dot product consumes four compute cycles, and there are 16 output elements.

The exact visible `done` timing also includes the FSM transition into `DONE`. No throughput requirement is imposed by the supplied problem statement.

## 7. Verification

The main SystemVerilog testbench is self-checking and covers:

- Identity matrix × deterministic random matrix
- Zero matrix × zero matrix
- All-ones matrix × all-ones matrix
- Five deterministic randomized test cases
- Final pass/fail messages for every case
- Final test summary

The reduced-width overflow testbench checks:

- Positive saturation
- `overflow == 1`

The Python reference model in `scripts/golden_model.py` implements the same integer fixed-point arithmetic and can be used independently to inspect expected results.

## 8. Running with ModelSim / QuestaSim on Linux

### Prerequisites

Make sure `vlog`, `vsim`, and `vlib` are available in your shell:

```bash
which vlog
which vsim
which vlib
```

### Option A: Makefile

From the repository root:

```bash
make
```

Run only the normal verification:

```bash
make sim
```

Run only the overflow regression:

```bash
make overflow
```

Clean generated simulator files:

```bash
make clean
```

### Option B: Direct ModelSim/Questa commands

```bash
vlib work
vlog -sv -work work src/matmul4x4_accel.sv verif/tb_matmul4x4_accel.sv verif/tb_overflow.sv
vsim -c work.tb_matmul4x4_accel -do "run -all; quit -f"
vsim -c work.tb_overflow -do "run -all; quit -f"
```

### Interactive GUI simulation

```bash
vlib work
vlog -sv -work work src/matmul4x4_accel.sv verif/tb_matmul4x4_accel.sv verif/tb_overflow.sv
vsim work.tb_matmul4x4_accel
```

Useful GUI commands:

```tcl
add wave -r /*
run -all
```

For the overflow test:

```bash
vsim work.tb_overflow
```

## 10. Expected output

A successful normal run prints messages similar to:

```text
PASS identity x random
PASS zero x zero
PASS all ones x all ones
PASS random test 1
PASS random test 2
PASS random test 3
PASS random test 4
PASS random test 5
SUMMARY: 8 normal tests completed.
SUMMARY: See tb_overflow.sv for deliberate overflow coverage.
```

The overflow regression should print:

```text
PASS overflow: C[0][0]=2047, overflow=1
```

## 11. Design decisions

### Why a shared MAC?

The problem statement explicitly says correctness and clarity are the priority and does not grade latency/throughput. A shared MAC minimizes RTL complexity and makes the control flow easy to verify.

### Why capture the inputs?

The interface requires the matrices to be stable before `start`. Capturing them at the accepted `start` edge means the computation is isolated from later changes at the external inputs.

### Why saturate?

Saturation avoids wrapping a mathematically large result into an incorrect sign/value. The `overflow` output makes the exceptional condition observable.

### Why SystemVerilog unpacked arrays?

The supplied interface explicitly permits unpacked matrix ports. QuestaSim/ModelSim with SystemVerilog support can compile this representation directly, and it makes the matrix indexing readable:

```systemverilog
a_matrix[row][k]
b_matrix[k][col]
c_matrix[row][col]
```

## 12. Scope

This project intentionally does not implement:

- Non-square matrices
- Runtime-configurable matrix dimensions
- Floating point
- Streaming interfaces
- Back-pressure
- Matrix batching
- Synthesis constraints
- Place-and-route
- FPGA bring-up

These exclusions are consistent with the supplied problem statement.

## 13. Author checklist

Before submission:

- [ ] Run `make`
- [ ] Confirm all normal tests report PASS
- [ ] Confirm overflow regression reports PASS
- [ ] Confirm `README.md` is present in the repository root
- [ ] Confirm RTL is under `src/`
- [ ] Confirm testbenches are under `verif/`
- [ ] Confirm design documentation and diagrams are under `doc/`
- [ ] Commit the repository with a clean history

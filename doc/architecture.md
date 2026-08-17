# Architecture

## Datapath

The accelerator contains:

- Two 4×4 input register banks
- One signed multiplier
- One accumulator
- Row, column, and `k` counters
- Saturation comparison logic
- A three-state control FSM

```text
                 +-------------------+
 A register ---> |                   |
                 |   Shared MAC      | ---> accumulator ---> saturation ---> C
 B register ---> |                   |
                 +-------------------+
                         ^
                         |
                 row / col / k counters
                         ^
                         |
                    +---------+
                    |   FSM   |
                    +---------+
```

## Control sequence

### IDLE
Wait for a one-cycle `start`. On acceptance, copy both external matrices into internal registers and clear the accumulator/counters.

### COMPUTE
For each `(row, col)`, perform:

```text
acc = acc + A[row][k] * B[k][col]
```

for `k = 0..3`.

After `k=3`, the final sum is saturated if necessary and stored into `C[row][col]`.

### DONE
Assert `done` for one cycle, then return to `IDLE`.

## Matrix traversal

The traversal is row-major over the output:

```text
C[0][0], C[0][1], ..., C[0][3],
C[1][0], C[1][1], ..., C[1][3],
...
C[3][3]
```

Each output consumes four multiply-accumulate cycles.

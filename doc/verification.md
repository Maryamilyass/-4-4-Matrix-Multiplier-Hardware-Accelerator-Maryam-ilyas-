# Verification Plan

## Test matrix

| Test | Purpose | Expected |
|---|---|---|
| Identity × random | Verify indexing and multiplication | Exact match |
| Zero × zero | Verify zero handling | All zeros |
| Ones × ones | Verify four-term accumulation | 4.0 in every element |
| Random 1–5 | Exercise signed arithmetic and indexing | Exact match |
| Reduced-width overflow | Verify saturation and flag | Saturated result + overflow |

## Self-checking strategy

The SystemVerilog testbench calculates each expected element using the same mathematical definition:

```text
expected[i][j] = Σ A[i][k] × B[k][j]
```

It then waits for `done` and compares every one of the 16 output elements.

A test is reported as `PASS` only when all elements and the overflow indication match the expected values.

## Why the overflow test uses a reduced width

With DATA_W=8 and ACC_W=20, the legal Q4.4 input range cannot produce a value outside the Q12.8 result range. Consequently, a genuine overflow stimulus is impossible at the required default width.

The overflow testbench therefore instantiates the exact same RTL with ACC_W=12. This is a verification-only configuration designed to force the saturation path without changing the submitted default interface.

#!/usr/bin/env python3
"""Reference model for 4x4 signed Q4.4 matrix multiplication."""

from typing import Sequence

N = 4
DATA_MIN, DATA_MAX = -128, 127

def matmul_q44(a: Sequence[Sequence[int]],
               b: Sequence[Sequence[int]]) -> list[list[int]]:
    """Return C in Q12.8 integer representation."""
    assert len(a) == N and len(b) == N
    return [
        [sum(int(a[i][k]) * int(b[k][j]) for k in range(N))
         for j in range(N)]
        for i in range(N)
    ]

def saturate(value: int, width: int) -> tuple[int, bool]:
    max_v = (1 << (width - 1)) - 1
    min_v = -(1 << (width - 1))
    if value > max_v:
        return max_v, True
    if value < min_v:
        return min_v, True
    return value, False

if __name__ == "__main__":
    a = [[16 if i == j else 0 for j in range(4)] for i in range(4)]
    b = [[i * 4 + j - 7 for j in range(4)] for i in range(4)]
    print("Identity x matrix:")
    for row in matmul_q44(a, b):
        print(row)

    a = [[127] * 4 for _ in range(4)]
    b = [[127] * 4 for _ in range(4)]
    raw = matmul_q44(a, b)
    sat = [[saturate(x, 12)[0] for x in row] for row in raw]
    print("\nReduced-width overflow example (ACC_W=12):")
    print("raw:", raw[0][0])
    print("sat:", sat[0][0])

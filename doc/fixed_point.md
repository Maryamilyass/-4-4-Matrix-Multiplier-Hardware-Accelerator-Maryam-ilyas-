# Fixed-Point Arithmetic

## Q4.4 input

An 8-bit signed input has four fractional bits.

```text
real_value = signed_integer / 2^4
```

Examples:

| Stored | Real |
|---:|---:|
| 16 | 1.0 |
| 8 | 0.5 |
| -16 | -1.0 |
| 127 | 7.9375 |
| -128 | -8.0 |

## Product

```text
Q4.4 × Q4.4 = Q8.8
```

The product is therefore interpreted as:

```text
real_product = product_integer / 2^8
```

## Sum

Four Q8.8 products remain Q8.8 because addition does not change the binary-point position.

The 20-bit output is described as Q12.8, giving eight fractional bits and twelve integer/sign bits.

For valid 8-bit Q4.4 inputs, the specified 20-bit result width has enough range for the complete four-term sum.

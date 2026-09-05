# Vertical spine partition: width constant, height varies.

Vertical spine partition: width constant, height varies.

## Usage

``` r
vspine(data, bounds, offset = offset, max = NULL)
```

## Arguments

- data:

  bounds data frame

- bounds:

  bounds of space to partition

- offset:

  space between spines

- max:

  maximum value

## Value

A data frame of rectangle boundaries (`l`, `r`, `b`, `t`), one row per
level of `data`.

## Examples

``` r
data(titanic)
ggplot(data = titanic, aes(x = product(Class))) +
  geom_mosaic(divider = "vspine")
```

# Template for a mosaic plot. A mosaic plot is composed of spines in alternating directions.

Template for a mosaic plot. A mosaic plot is composed of spines in
alternating directions.

## Usage

``` r
mosaic(direction = "h")
```

## Arguments

- direction:

  direction of first split

## Value

A function of one argument, the number of splits `n`, that returns a
character vector of divider function names (`"hspine"`/`"vspine"`) to
apply at each split – suitable for the `divider` argument of
[`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md)
and related layers.

## Examples

``` r
data(titanic)
ggplot(data = titanic, aes(x = product(Class, Sex))) +
  geom_mosaic(divider = mosaic("v"))
```

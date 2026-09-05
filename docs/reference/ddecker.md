# Template for a double decker plot. A double decker plot is composed of a sequence of spines in the same direction, with the final spine in the opposite direction.

Template for a double decker plot. A double decker plot is composed of a
sequence of spines in the same direction, with the final spine in the
opposite direction.

## Usage

``` r
ddecker(direction = "h")
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
  geom_mosaic(divider = ddecker("v"))
```

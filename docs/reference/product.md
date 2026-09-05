# Wrapper for a list

Wrapper for a list

## Usage

``` r
product(...)
```

## Arguments

- ...:

  Unquoted variables going into the product plot.

## Value

A list of expressions (see
[`rlang::exprs()`](https://rlang.r-lib.org/reference/defusing-advanced.html)),
one per argument, used inside
[`aes()`](https://ggplot2.tidyverse.org/reference/aes.html) to mark the
variables that define the mosaic's product formula.

## Examples

``` r
data(titanic)
ggplot(data = titanic,
       aes(x = product(Survived, Class), fill = Survived)) +
  geom_mosaic()
```

# Diverging color scale for Pearson residuals

Provides a blue-white-red color scale centered at 0 for visualizing
Pearson residuals from loglinear models. Designed for use with
[`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md)
when `expected` parameter is specified.

## Usage

``` r
scale_fill_residual(
  ...,
  low = "darkblue",
  mid = "white",
  high = "darkred",
  midpoint = 0,
  limits = NULL,
  name = "Pearson\nResidual"
)

scale_fill_residuals(
  ...,
  low = "darkblue",
  mid = "white",
  high = "darkred",
  midpoint = 0,
  limits = NULL,
  name = "Pearson\nResidual"
)
```

## Arguments

- ...:

  Arguments passed to
  [`scale_fill_gradient2`](https://ggplot2.tidyverse.org/reference/scale_gradient.html)

- low:

  Color for negative residuals (default: "steelblue")

- mid:

  Color for zero residuals (default: "white")

- high:

  Color for positive residuals (default: "firebrick")

- midpoint:

  Center point for color scale (default: 0)

- limits:

  Range of residuals to display. If NULL, uses range of data.

- name:

  Legend title

## Examples

``` r
data(titanic)

# Independence model with residual shading
ggplot(data = titanic) +
  geom_mosaic(aes(x = product(Class, Sex)), expected = "independence") +
  scale_fill_residual()


# Custom colors
ggplot(data = titanic) +
  geom_mosaic(aes(x = product(Class, Sex)), expected = "independence") +
  scale_fill_residual(low = "blue", high = "red")


# Custom limits to highlight strong deviations
ggplot(data = titanic) +
  geom_mosaic(aes(x = product(Class, Sex, Survived)),
              expected = ~ Class + Sex) +
  scale_fill_residual(limits = c(-4, 4))
```

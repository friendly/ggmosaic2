# Settings for mosaic plot layers

Set the divider, gap size, and model used to calculate expected
frequencies for mosaic layers in a plot. A value set directly in a layer
takes priority.

## Usage

``` r
mosaic_settings(divider, offset, expected)
```

## Arguments

- divider:

  A divider function, a character vector naming divider functions, or a
  list of divider functions.

- offset:

  A single non-negative number giving the gap at the deepest split. Gaps
  increase by a factor of 1.5 toward the outermost split.

- expected:

  The log-linear model used to calculate expected frequencies and
  Pearson residuals. Supply a formula or one of `"independence"`,
  `"saturated"`, or `"conditional"`. The conditional model requires one
  or more variables mapped to `conds`. Supply `NULL` to turn off model
  fitting, including a model set by an earlier call to
  `mosaic_settings()`.

## Value

An object of class `"ggmosaic_settings"` that can be added to a ggplot
with `+`.

## Details

The position of `mosaic_settings()` among the layers in a plot has no
effect. If it is added more than once, the last supplied value for each
setting is used; omitted arguments do not change earlier settings.

## See also

[`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md),
[`geom_mosaic_text()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_text.md),
[`geom_mosaic_jitter()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_jitter.md),
[`mosaic()`](https://friendly.github.io/ggmosaic2/reference/mosaic.md),
and
[`ddecker()`](https://friendly.github.io/ggmosaic2/reference/ddecker.md)

## Examples

``` r
data(titanic)

ggplot(titanic, aes(x = product(Class, Sex))) +
  mosaic_settings(
    expected = "independence",
    divider = c("vspine", "hspine"),
    offset = 0.005
  ) +
  geom_mosaic() +
  geom_mosaic_text(display_values = "residual") +
  scale_fill_residual() +
  theme_mosaic()

```

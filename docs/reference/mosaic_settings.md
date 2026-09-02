# Plot-scoped mosaic computation settings

Share layout and model parameters across mosaic-family layers in one
plot. Explicit arguments supplied to an individual layer override these
settings. Settings can be added before or after the layers because they
are resolved when the plot is built.

## Usage

``` r
mosaic_settings(divider, offset, expected)
```

## Arguments

- divider:

  Divider function, character divider name/vector, or divider list
  accepted by the mosaic layer constructors.

- offset:

  One finite, non-negative number specifying the fixed gap at the
  deepest split.

- expected:

  Optional loglinear model specification used by mosaic and text layers.
  Supply `NULL` to explicitly disable a previously supplied plot-level
  model, a formula, or one of `"independence"`, `"saturated"`, or
  `"conditional"`.

## Value

A plot component that can be added to a ggplot with `+`.

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
  scale_fill_residual()
```

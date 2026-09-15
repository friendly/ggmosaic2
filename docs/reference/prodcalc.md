# Calculate frequencies.

Calculate frequencies.

## Usage

``` r
prodcalc(
  data,
  formula,
  divider = mosaic(),
  cascade = 0,
  scale_max = TRUE,
  na.rm = FALSE,
  offset = 0.01,
  expected = NULL,
  variable_labels = NULL
)
```

## Arguments

- data:

  input data frame

- formula:

  formula specifying display of plot

- divider:

  divider function

- cascade:

  cascading amount, per nested layer

- scale_max:

  Logical vector of length 1. If `TRUE` maximum values within each
  nested layer will be scaled to take up all available space. If
  `FALSE`, areas will be comparable between nested layers.

- na.rm:

  Logical vector of length 1 - should missing levels be silently
  removed?

- offset:

  Numeric value specifying the fixed gap at the deepest split (default:
  0.01). Gaps increase by a factor of 1.5 toward the outermost split.

- expected:

  Optional. Specification for loglinear model to calculate residuals.
  Can be:

  - NULL (default): No model fitting

  - Formula: Custom model specification (e.g., `~ A + B` for
    independence)

  - Character: Shortcut - "independence", "saturated", or "conditional"

  When specified, adds `.expected` and `.residual` columns to output.

- variable_labels:

  Optional named character vector mapping internal variable names to the
  expressions shown to users. Used internally by the ggplot2 layer
  wrappers.

## Value

A data frame giving rectangle boundaries (`l`, `r`, `b`, `t`) and
computed frequencies for each partition/cell, plus
`.expected`/`.residual` columns when `expected` is supplied.

## Examples

``` r
data(happy)
prodcalc(happy, ~ happy, "hbar", offset = 0.005)
#>           happy   .wt       l       r b         t level    .n
#> 1 not too happy  7668 0.00000 0.24625 0 0.2284659     1  7668
#> 2  pretty happy 33563 0.25125 0.49750 0 1.0000000     1 33563
#> 3    very happy 18823 0.50250 0.74875 0 0.5608259     1 18823
#> 4          <NA>  4760 0.75375 1.00000 0 0.1418228     1  4760
prodcalc(happy, ~ happy, "hspine", offset = 0.01)
#>           happy   .wt         l         r b t level    .n
#> 1 not too happy  7668 0.0000000 0.1147585 0 1     1  7668
#> 2  pretty happy 33563 0.1247585 0.6270591 0 1     1 33563
#> 3    very happy 18823 0.6370591 0.9187623 0 1     1 18823
#> 4          <NA>  4760 0.9287623 1.0000000 0 1     1  4760
```

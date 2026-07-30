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
  expected = NULL
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

  Numeric value specifying the space between mosaic tiles (default:
  0.01)

- expected:

  Optional. Specification for loglinear model to calculate residuals.
  Can be:

  - NULL (default): No model fitting

  - Formula: Custom model specification (e.g., `~ A + B` for
    independence)

  - Character: Shortcut - "independence", "saturated", or "conditional"

  When specified, adds `.expected` and `.residual` columns to output.

## Examples

``` r
if (FALSE) { # \dontrun{
library(productplots)
prodcalc(happy, ~ happy, "hbar", offset = 0.005)
prodcalc(happy, ~ happy, "hspine", offset = 0.01)
} # }
```

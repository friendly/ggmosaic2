# Build model formula from user specification

Build model formula from user specification

## Usage

``` r
build_model_formula(expected, vars, conds = NULL, variable_labels = NULL)
```

## Arguments

- expected:

  Formula, character shortcut, or NULL

- vars:

  Character vector of margin variable names (with prefixes like
  x\_\_Class)

- conds:

  Character vector of conditioning variable names (optional, with
  prefixes)

- variable_labels:

  Optional named character vector mapping internal variable names to
  their original expressions.

## Value

Formula object or NULL

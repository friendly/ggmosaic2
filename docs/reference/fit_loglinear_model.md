# Fit Poisson GLM and calculate Pearson residuals

Fit Poisson GLM and calculate Pearson residuals

## Usage

``` r
fit_loglinear_model(data, vars, model_formula)
```

## Arguments

- data:

  Data frame with .n column (observed counts)

- vars:

  Character vector of all variable names (margins + conds)

- model_formula:

  Formula for the GLM

## Value

Data frame with added .expected and .residual columns

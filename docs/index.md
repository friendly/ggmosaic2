# ggmosaic2

`ggmosaic2` is a standalone continuation of the `ggmosaic` package,
which was removed from CRAN around November 2025 and appeared
unmaintained (a [pull
request](https://github.com/haleyjeppson/ggmosaic/pull/86) adding
residual-based shading went unanswered). Rather than fork under the
original name, `ggmosaic2` is developed independently, building on
`ggmosaic`’s original authors (Haley Jeppson, Heike Hofmann, Di Cook;
credited as authors in `DESCRIPTION`). `ggmosaic` was designed to create
visualizations of categorical data and is capable of producing bar
charts, stacked bar charts, mosaic plots, and double decker plots.

`ggmosaic2` extends this with jittered-point overlays showing individual
observations (reflecting non-independence as variation in point density,
a physical analog for departures from independence), residual-based
shading, and support for fitted loglinear models to show patterns of
association among variables in frequency tables.

## Installation

You can install `ggmosaic2` from GitHub with:

``` r

# install.packages("devtools")
devtools::install_github("friendly/ggmosaic2")
```

## Example

``` r

library(ggmosaic2)

HairEyeColor |>
  as.data.frame() |>
  ggplot() +
  geom_mosaic(aes(x = product(Sex, Eye, Hair), weight = Freq),
              expected = "independence") +
  scale_fill_residual(limits = c(-4, 4)) +
  theme_mosaic(rot_labels = 45)
```

![Mosaicplot of the HairEyeColor dataset from base R. Certain
combinations of hair colour, eye colour, and biological sex are
more/less common than would be expected if these variables were
independent of one another.](reference/figures/README-example-1.png)

## geom_mosaic: setting the aesthetics

In
[`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md),
the following aesthetics can be specified:

- `weight`: select a weighting variable. This is useful when your data
  is in frequency form, consisting of a dataset of factor variables and
  a variable (`count` or `Freq`) giving the frequency in each cell of an
  n-way table.

- `x`: select variables to add to formula

  - declared as `x = product(var2, var1, ...)`

- `alpha`: add an alpha transparency to the selected variable

  - unless the variable is called in `x`, it will be added to the
    formula in the first position

- `fill`: select a variable to be filled

  - unless the variable is called in `x`, it will be added to the
    formula in the first position after the optional `alpha` variable.

- `conds` : select a variable to condition on

  - declared as `conds = product(cond1, cond2, ...)`

These values are then sent through repurposed `productplots` functions
to create the desired formula: `weight ~ alpha + fill + x | conds`.

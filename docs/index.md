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
library(dplyr)
happy |> 
  mutate(finrela = forcats::fct_recode(finrela,
    "far below     " = "far below average",
    "    below" = "below average",
    "average" = "average",
    "above    " = "above average", 
    "l\n   far above" = "far above average")) |>
  ggplot() +
  geom_mosaic(aes(x = product(finrela), fill=health), show.legend = FALSE) +
  theme_mosaic() +
  scale_fill_manual(values = c("#4575B4", "#ABD9E9", "#FEE090", "#F46D43"))
```

![Mosaicplot of survey participant's perceived health (from poor to
excellent) given their financial situation relative to their peers.
Perceived health generally increases with better financial
situation.](reference/figures/README-example-1.png)

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

## Version compatibility issues with ggplot2

Since the initial release of ggmosaic, ggplot2 has evolved considerably.
And as ggplot2 continues to evolve, ggmosaic must continue to evolve
alongside it. Although these changes affect the underlying code and not
the general usage of ggmosaic, the general user may need to be aware of
compatibility issues that can arise between versions. The table below
summarizes the compatibility between versions (inherited history from
`ggmosaic`, prior to the `ggmosaic2` fork).

[TABLE]

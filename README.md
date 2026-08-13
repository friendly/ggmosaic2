
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![Project Status:
Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R_Universe](https://friendly.r-universe.dev/badges/ggmosaic2)](https://friendly.r-universe.dev)
[![Last
Commit](https://img.shields.io/github/last-commit/friendly/ggmosaic2)](https://github.com/friendly/ggmosaic2/)
[![Docs](https://img.shields.io/badge/pkgdown%20site-blue)](https://friendly.github.io/ggmosaic2/)
[![Ask
DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/friendly/ggmosaic2)
<!--
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/ggmosaic2)](https://CRAN.R-project.org/package=ggmosaic2)

[![R-CMD-check](https://github.com/friendly/ggmosaic2/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/friendly/ggmosaic2/actions/workflows/R-CMD-check.yaml)
--> <!-- badges: end -->

# ggmosaic2 <img src="man/figures/logo.png" align="right" width="200px" />

*Version 0.5.1, built 2026-08-13*

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
association among variables in frequency tables. Additional improvements
include improved spacing, theme appearance, and proper faceting. These
extensions and improvements are illustrated in the package vignette
[`introducing-ggmosaic2.Rmd`](https://friendly.github.io/ggmosaic2/articles/introducing-ggmosaic2.html).

See Friendly (1994, 1999) for the theory of mosaic displays and Jeppson
& Hofmann (2023) for the description of the original `ggplot2`
implementation. Full citations are in [References](#references) below.

## Installation

You can install the latest version of `ggmosaic2` from
[R-universe](https://friendly.r-universe.dev/ggmosaic2) with:

``` r
install.packages("ggmosaic2", repos = "https://friendly.r-universe.dev")
```

or from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("friendly/ggmosaic2")
```

## Example

The `datasets::HairEyeColor` is a classic example of what can be learned
from a mosaic plot. It is a 3-way table, containing the frequencies of
592 students who were asked to give their hair color and eye color,
classified by `Sex`.

``` r
ftable(Hair ~ Eye + Sex, data=HairEyeColor)
#>              Hair Black Brown Red Blond
#> Eye   Sex                              
#> Brown Male           32    53  10     3
#>       Female         36    66  16     4
#> Blue  Male           11    50  10    30
#>       Female          9    34   7    64
#> Hazel Male           10    25   7     5
#>       Female          5    29   7     5
#> Green Male            3    15   7     8
#>       Female          2    14   7     8
```

To provide some context, the main questions here are:

- Are hair and eye color associated in this sample?
- If so, what is the nature/pattern of association?
- Is this the same for males and females?

<!-- TODO: See: REFS-HERE for other analyses of this dataset. Is this necessary / useful? -->

Here, we just illustrate how to display this dataset using `ggmosaic2`.
See the vignette, [Introducing ggmosaic2: an enhanced
ggmosaic](https://friendly.github.io/ggmosaic2/articles/introducing-ggmosaic2.html)
for how the current implementation differs from that in the original
`ggmosaic` package, including use of the `fill=` aesthetic for
Marimekko-style shading and the use of spacing of the tiles to preserve
a visual hierarchy of the cells belonging to the various factors in the
table.

### Basic mosaic plot

With default (uniform) shading, a mosaic plot just shows the relative
frequencies of each combination of `Sex`, `Eye`, and `Hair`, via the
area of each tile. The total frequency is first split by `Hair` color,
then subdivided by `Eye` color, and finally by `Sex`.

``` r
library(ggmosaic2)

HairEyeColor |>
  as.data.frame() |>
  ggplot() +
  geom_mosaic(aes(x = product(Sex, Eye, Hair), weight = Freq)) +
  theme_mosaic(rot_labels = 45)
```

<img src="man/figures/README-example-basic-1.png" alt="Basic mosaicplot of the HairEyeColor dataset, with default shading. Tile area reflects the relative frequency of each combination of hair color, eye color, and reported sex."  />

Data must be in either frequency form (i.e., containing a `"Freq"`
column or equivalent) or case form (i.e., each row contains an
individual observation) to be used with `geom_mosaic()`. Data in
frequency form must have its frequency column mapped to the `weight=`
argument of `geom_mosaic()`. To accommodate the alternate splitting in
horizontal and vertical directions, `geom_mosaic()` uses a `product()`
to specify the geometrical aesthetic of the plot.

See the vignette [Three Forms of Frequency Tables for Mosaic
Displays](https://friendly.github.io/ggmosaic2/articles/frequency-table-forms.html)
for a fuller discussion of case form, frequency form, and table form,
and how to convert between them.

### Residual-shaded mosaic plot

To see whether hair and eye color are associated, fit a loglinear model
of **joint** independence (`expected = "independence"`) and shade each
tile by its residual from that model with `scale_fill_residual()`. Tiles
shaded blue occur more often than expected under independence; tiles
shaded red occur less often.

``` r
HairEyeColor |>
  as.data.frame() |>
  ggplot() +
  geom_mosaic(aes(x = product(Sex, Eye, Hair), weight = Freq),
              expected = "independence") +
  scale_fill_residual(limits = c(-4, 4)) +
  theme_mosaic(rot_labels = 45)
```

<img src="man/figures/README-example-residual-1.png" alt="Mosaicplot of the HairEyeColor dataset, shaded by residuals from a loglinear model of independence. Certain combinations of hair color, eye color, and sex are more/less common than would be expected if these variables were independent of one another."  />

The `expected` argument also accepts `"saturated"` and `"conditional"`
shortcuts, or a custom model formula, for fitting other loglinear
models. See the vignette [ggmosaic and Loglinear
Models](https://friendly.github.io/ggmosaic2/articles/loglinear-models.html)
for a fuller treatment of model fitting and residual-based shading.

### Jittered points: showing individual observations

`geom_mosaic_jitter()` overlays one jittered point per individual
observation on top of a mosaic plot, so that non-independence shows up
both as residual shading and as variation in point density within each
tile. It needs one row per observation, so first expand `HairEyeColor`
from its frequency-table form using `tidyr::uncount()`.

``` r
set.seed(1945)

HairEyeColor |>
  as.data.frame() |>
  tidyr::uncount(Freq) |>
  ggplot() +
  geom_mosaic(aes(x = product(Sex, Eye, Hair)), expected = "independence") +
  scale_fill_residual(limits = c(-4, 4)) +
  geom_mosaic_jitter(aes(x = product(Sex, Eye, Hair)), alpha = 0.3) +
  theme_mosaic(rot_labels = 45)
```

<img src="man/figures/README-example-jitter-1.png" alt="Mosaicplot of the HairEyeColor dataset shaded by residuals from a loglinear model of independence, overlaid with a jittered point for each of the 592 individual students."  />

<!--
GK: Folded this into the above (see paragraph "Data must be in ..."). Feel free to modify/revert
&#10;## geom_mosaic: setting the aesthetics
 &#10;In `geom_mosaic()`, the following aesthetics can be specified:
&#10;-   `weight`: select a weighting variable. This is useful when your data is in frequency form, consisting of a dataset of factor
     variables and a variable (`count` or `Freq`) giving the frequency in each cell of an n-way table.
&#10;-   `x`: select variables to add to formula
&#10;    -   declared as `x = product(var2, var1, ...)`
&#10;-   `alpha`: add an alpha transparency to the selected variable
&#10;    -   unless the variable is called in `x`, it will be added to the formula in the first position
&#10;-   `fill`: select a variable to be filled
&#10;    -   unless the variable is called in `x`, it will be added to the formula in the first position after the optional `alpha` variable.
&#10;-   `conds` : select a variable to condition on
&#10;    -   declared as `conds = product(cond1, cond2, ...)`
&#10;These values are then sent through repurposed `productplots` functions to create the desired formula: `weight ~ alpha + fill + x | conds`.
-->

## References

**Mosaic displays**

- Friendly, M. (1994). Mosaic Displays for Multi-Way Contingency Tables.
  *Journal of the American Statistical Association*, 89(425), 190–200.
  [doi:10.1080/01621459.1994.10476460](https://doi.org/10.1080/01621459.1994.10476460)
- Friendly, M. (1999). Extending Mosaic Displays: Marginal, Conditional,
  and Partial Views of Categorical Data. *Journal of Computational and
  Graphical Statistics*, 8(3), 373–395.
  [doi:10.1080/10618600.1999.10474820](https://doi.org/10.1080/10618600.1999.10474820)

**ggmosaic**

- Jeppson, H., & Hofmann, H. (2023). Generalized Mosaic Plots in the
  ggplot2 Framework. *The R Journal*, 14(4), 50–78.
  [doi:10.32614/RJ-2023-013](https://doi.org/10.32614/RJ-2023-013)

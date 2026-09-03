# Introducing ggmosaic2: an enhanced ggmosaic

``` r

library(ggmosaic2)
```

With **ggmosaic** being taken off of CRAN and appearing unmaintained
(PRs and issues not receiving responses as well as minimal commit
activity on the repository), there was a need to bring mosaic plots back
to the **ggplot2** framework. In addition to fixing outstanding issues,
we (the new authors) also wanted to improve upon the existing package,
as several aspects of **ggmosaic**s were inferior and/or limited when
compared to mosaics produced by **vcd** and **vcdExtra**.

This vignette describes the many additions and changes made to
**ggmosaic** that make up the initial release of **ggmosaic2**. The most
important of these changes, is the introduction of *residual shading*,
to show the pattern of association in a frequency table in relation to
some loglinear model. This is described in its own vignette [ggmosaic
and Loglinear
Models](https://friendly.github.io/ggmosaic2/articles/loglinear-models.md).

## Basic Appearance

A few things were done to alter the basic appearance of mosaics, both
with and without the use of
[`theme_mosaic()`](https://friendly.github.io/ggmosaic2/reference/theme_mosaic.md):

### Utilizing the top and right axes

When three or more variables are used, the top (three or more variables)
and right (four or more variables) axes will now be utilized. The
figures compare the historical `haleyjeppson/ggmosaic` output (**Old**)
with `friendly/ggmosaic2`

(**New**); the current **ggmosaic2** syntax below declares its
aesthetics globally:

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), fill = Hair, weight = Freq)) +
    geom_mosaic()
```

![](fig/topright-old.png)![](fig/topright-new.png)

### `theme_mosaic()`

As with other `ggplot2` extensions, themes set the general look-and-feel
of the plot such as the color of the background, gridlines, the size and
color of fonts.
[`theme_mosaic()`](https://friendly.github.io/ggmosaic2/reference/theme_mosaic.md)
provides access to the regular ggplot2 theme, but: removes any
background, axes ticks, most of the gridlines, and ensures an aspect
ratio of 1 for better viewing of the mosaics. This theme also applies a
**bold** face to axes labels and allows for the convenient rotation of
category labels to avoid overlap.

With
[`theme_mosaic()`](https://friendly.github.io/ggmosaic2/reference/theme_mosaic.md)
applied to the above:

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), fill = Hair, weight = Freq)) +
    geom_mosaic() +
    theme_mosaic(base_size = 12)
```

![](fig/theme-old.png)![](fig/theme-new.png)

Axis labels had a bold face applied to be consistent with mosaics made
using **vcd** and **vcdExtra**. Axis ticks were removed, as they are
unnecessary for mosaic displays.

New to
[`theme_mosaic()`](https://friendly.github.io/ggmosaic2/reference/theme_mosaic.md)
is a convenience argument `rot_labels` that can rotate category labels
to a user-specified angle (in degrees):

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), fill = Hair, weight = Freq)) +
    geom_mosaic() +
    theme_mosaic(rot_labels = 30, base_size = 14)
```

![](introducing-ggmosaic2_files/figure-html/rot-labels-1.png)

### Spacing of cells

You might already have noticed that the innermost spacing of cells in
mosaic displays has been increased in **ggmosaic2**. This is a
perceptual feature of mosaic displays (Friendly, 1994): wider gaps at
the first splits make it easier and compare to see the frequencies of
categories at different dimensions of the table in the order the mosaic
is divided.

Re-using an example from “Utilizing the top and right axes,”
differentiating between cells is now easier:

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), fill = Hair, weight = Freq)) +
    geom_mosaic() +
    theme_mosaic()
```

![](fig/theme-old.png)![](fig/theme-new.png)

In the old **ggmosaic**, increasing the `offset` argument of
[`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md)
would not remedy this issue to a satisfying degree. **ggmosaic2** solves
this by implementing a spacing scheme similar to **vcd**:

``` math
\text{gap}_j = \text{offset} \times 1.5^{d - j}
```

where $`d`$ is the number of splits and $`j = 1`$ is the innermost
split. `offset` remains at a default of `.01`.

## Faceting is Fixed

The old **ggmosaic** had an
[issue](https://github.com/haleyjeppson/ggmosaic/issues/78) where facet
labels would not be independently generated per panel:

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Eye, Hair), fill = Hair, weight = Freq)) +
  geom_mosaic() +
  theme_mosaic() +
  facet_grid(. ~ Sex)
```

![](fig/facet-old.png)

The new function
[`facet_mosaic_grid()`](https://friendly.github.io/ggmosaic2/reference/facet_mosaic_grid.md)
corrects this behavior, generating labels per facet:

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Eye, Hair), fill = Hair, weight = Freq)) +
  geom_mosaic() +
  theme_mosaic() +
  facet_mosaic_grid(. ~ Sex)
```

![](fig/facet-new.png)

## Residual-Based Shading

As stated, this portion of the vignette will be covered in minimal
detail, with more information found in [ggmosaic and Loglinear
Models](https://friendly.github.io/ggmosaic2/articles/loglinear-models.md).

To apply residual-based shading to the `HairEyeColor` example, we will
need to supply the `expected` argument of
[`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md)
with a model. Let’s use the model of independence. We will also need to
use
[`scale_fill_residual()`](https://friendly.github.io/ggmosaic2/reference/scale_fill_residual.md)
instead of the `fill` argument of
[`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md):

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), weight = Freq)) +
  geom_mosaic(expected = "independence") +
  scale_fill_residual() +
  theme_mosaic(rot_labels = 30)
```

![](introducing-ggmosaic2_files/figure-html/residual-1.png)

For a shading scheme that accentuates residuals $`\geq \pm4`$ (similar
to the default in **vcd**), you can use the `limits` argument of
[`scale_fill_residual()`](https://friendly.github.io/ggmosaic2/reference/scale_fill_residual.md):

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), weight = Freq)) +
  geom_mosaic(expected = "independence") +
  scale_fill_residual(limits = c(-4,4)) +
  theme_mosaic(rot_labels = 30)
```

![](introducing-ggmosaic2_files/figure-html/residual-limit-1.png)

The legend can be re-positioned or disabled through the usual means:

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), weight = Freq)) +
  geom_mosaic(expected = "independence") + # `show.legend = FALSE` works as well
  scale_fill_residual(limits = c(-4,4)) +
  theme_mosaic(rot_labels = 30, legend.position = "none")
```

![](introducing-ggmosaic2_files/figure-html/residual-legend-1-1.png)

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), weight = Freq)) +
  geom_mosaic(expected = "independence") +
  scale_fill_residual(limits = c(-4,4)) +
  theme_mosaic(rot_labels = 30, legend.position = "bottom")
```

![](introducing-ggmosaic2_files/figure-html/residual-legend-2-1.png)

Custom outlines can also be disabled through the usual means:

``` r

HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), weight = Freq)) +
  geom_mosaic(expected = "independence",
              color = NA) +
  scale_fill_residual(limits = c(-4,4)) +
  theme_mosaic(rot_labels = 30, legend.position = "bottom")
```

![](introducing-ggmosaic2_files/figure-html/residual-outlines-1.png)

## Other fixes/changes

- Fixed namespace-only usage ([issue
  \#82](https://github.com/haleyjeppson/ggmosaic/issues/82) from
  `haleyjeppson/ggmosaic`)
- Allow
  [`theme_mosaic()`](https://friendly.github.io/ggmosaic2/reference/theme_mosaic.md)
  to take additional
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
  arguments through `...`
- Allow for variables created within
  [`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md)
  aesthetics ([issue
  \#59](https://github.com/haleyjeppson/ggmosaic/issues/59) from
  `haleyjeppson/ggmosaic`)
  - This change also fixed item (re)ordering ([issue
    \#77](https://github.com/haleyjeppson/ggmosaic/issues/77) from
    `haleyjeppson/ggmosaic`)
- Fixed fill aesthetic automatically appearing in labels ([issue
  \#39](https://github.com/haleyjeppson/ggmosaic/issues/39) from
  `haleyjeppson/ggmosaic`)

## References

Friendly, M. (1994). Mosaic displays for multi-way contingency tables.
*Journal of the American Statistical Association*, *89*, 190–200.

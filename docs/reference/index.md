# Package index

## Mosaic layers

The main geoms and stats for building mosaic plots, plus the plot-scoped
settings and faceting support that let them share a model or layout
across layers/panels

- [`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md)
  [`stat_mosaic_text()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md)
  [`stat_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md)
  : Mosaic plots.
- [`geom_mosaic_jitter()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_jitter.md)
  [`stat_mosaic_jitter()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_jitter.md)
  : Jittered dots in Mosaic plots.
- [`geom_mosaic_text()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_text.md)
  : Labeling for Mosaic plots.
- [`mosaic_settings()`](https://friendly.github.io/ggmosaic2/reference/mosaic_settings.md)
  : Settings for mosaic plot layers
- [`facet_mosaic_grid()`](https://friendly.github.io/ggmosaic2/reference/facet_mosaic_grid.md)
  : Facet mosaic plots with panel-specific axes

## Scales

Scales for the product-formula axes and residual-shaded fill

- [`product()`](https://friendly.github.io/ggmosaic2/reference/product.md)
  : Wrapper for a list
- [`scale_x_productlist()`](https://friendly.github.io/ggmosaic2/reference/scale_x_productlist.md)
  [`scale_y_productlist()`](https://friendly.github.io/ggmosaic2/reference/scale_x_productlist.md)
  [`ScaleContinuousProduct`](https://friendly.github.io/ggmosaic2/reference/scale_x_productlist.md)
  : Determining scales for mosaics
- [`scale_type(`*`<productlist>`*`)`](https://friendly.github.io/ggmosaic2/reference/scale_type.productlist.md)
  : Helper function for determining scales
- [`scale_fill_residual()`](https://friendly.github.io/ggmosaic2/reference/scale_fill_residual.md)
  [`scale_fill_residuals()`](https://friendly.github.io/ggmosaic2/reference/scale_fill_residual.md)
  : Diverging color scale for Pearson residuals

## Theme

- [`theme_mosaic()`](https://friendly.github.io/ggmosaic2/reference/theme_mosaic.md)
  : Theme for mosaic plots

## Loglinear models

Fitting the models behind residual/expected-value shading

- [`fit_loglinear_model()`](https://friendly.github.io/ggmosaic2/reference/fit_loglinear_model.md)
  : Fit Poisson GLM and calculate Pearson residuals
- [`build_model_formula()`](https://friendly.github.io/ggmosaic2/reference/build_model_formula.md)
  : Build model formula from user specification
- [`shortcut_to_formula()`](https://friendly.github.io/ggmosaic2/reference/shortcut_to_formula.md)
  : Translate shortcut strings to formulas

## Partitioning & layout

Divider functions that control how a mosaic recursively splits into
rectangles, and the lower-level layout calculations behind them

- [`mosaic()`](https://friendly.github.io/ggmosaic2/reference/mosaic.md)
  : Template for a mosaic plot. A mosaic plot is composed of spines in
  alternating directions.
- [`hbar()`](https://friendly.github.io/ggmosaic2/reference/hbar.md) :
  Horizontal bar partition: width constant, height varies.
- [`hspine()`](https://friendly.github.io/ggmosaic2/reference/hspine.md)
  : Horizontal spine partition: height constant, width varies.
- [`vbar()`](https://friendly.github.io/ggmosaic2/reference/vbar.md) :
  Vertical bar partition: height constant, width varies.
- [`vspine()`](https://friendly.github.io/ggmosaic2/reference/vspine.md)
  : Vertical spine partition: width constant, height varies.
- [`spine()`](https://friendly.github.io/ggmosaic2/reference/spine.md) :
  Spine partition: divide longest dimension.
- [`squeeze()`](https://friendly.github.io/ggmosaic2/reference/squeeze.md)
  : Internal helper function
- [`prodcalc()`](https://friendly.github.io/ggmosaic2/reference/prodcalc.md)
  : Calculate frequencies.

## ggproto objects

Underlying Geom/Stat classes, for extending the package (the
ScaleContinuousProduct class is documented alongside
[`scale_x_productlist()`](https://friendly.github.io/ggmosaic2/reference/scale_x_productlist.md)
above)

- [`GeomMosaic`](https://friendly.github.io/ggmosaic2/reference/GeomMosaic.md)
  : Geom proto
- [`GeomMosaicJitter`](https://friendly.github.io/ggmosaic2/reference/GeomMosaicJitter.md)
  : Geom proto
- [`GeomMosaicText`](https://friendly.github.io/ggmosaic2/reference/GeomMosaicText.md)
  : Geom proto
- [`StatMosaic`](https://friendly.github.io/ggmosaic2/reference/StatMosaic.md)
  : Geom proto
- [`StatMosaicJitter`](https://friendly.github.io/ggmosaic2/reference/StatMosaicJitter.md)
  : Geom proto
- [`StatMosaicText`](https://friendly.github.io/ggmosaic2/reference/StatMosaicText.md)
  : Geom proto

## Templates & apps

[`ggmosaic_app()`](https://friendly.github.io/ggmosaic2/reference/ggmosaic_app.md)
is deprecated, inherited as-is from `ggmosaic` for the historical record
only

- [`ddecker()`](https://friendly.github.io/ggmosaic2/reference/ddecker.md)
  : Template for a double decker plot. A double decker plot is composed
  of a sequence of spines in the same direction, with the final spine in
  the opposite direction.
- [`ggmosaic_app()`](https://friendly.github.io/ggmosaic2/reference/ggmosaic_app.md)
  : Launch shiny app (deprecated)

## Data

- [`happy`](https://friendly.github.io/ggmosaic2/reference/happy.md) :
  Data related to happiness from the general social survey.
- [`fly`](https://friendly.github.io/ggmosaic2/reference/fly.md) :
  Flying Etiquette Survey Data
- [`titanic`](https://friendly.github.io/ggmosaic2/reference/titanic.md)
  : Passengers and crew on board the Titanic

## Package

- [`ggmosaic2`](https://friendly.github.io/ggmosaic2/reference/ggmosaic2-package.md)
  [`ggmosaic2-package`](https://friendly.github.io/ggmosaic2/reference/ggmosaic2-package.md)
  : ggmosaic2: Mosaic Plots in the 'ggplot2' Framework, Extended

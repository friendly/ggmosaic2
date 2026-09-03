
## Test environments
* local Windows 11, R version 4.6.1 (2026-06-24 ucrt)
* local macOS Tahoe 26.6.2, R version 4.6.1 (2026-06-24) [GK]
* ubuntu 16.04 (on travis-ci), R 3.6.3
* win-builder (R Under development (unstable), 2026-08-31 r90457 ucrt)

## R CMD check results

0 errors | 0 warnings | 1 note

* Standard for a "New submission"

## Changes

### ggmosaic2 0.5.0

`ggmosaic2` is a standalone continuation of `ggmosaic`, which was removed from CRAN around
November 2025 and appeared unmaintained (the loglinear-models/residual-shading pull request
below, https://github.com/haleyjeppson/ggmosaic/pull/86, was never acted on).

Rather than take
over the original package name, this work continues independently as `ggmosaic2`, maintained by
Michael Friendly, with original authors Haley Jeppson, Heike Hofmann, and Di Cook credited as
contributors in `DESCRIPTION`.

The version number picks up from the last CRAN/fork release (0.4.1) rather than resetting, since
this carries forward that code and history rather than starting fresh. Everything below this
entry is inherited `ggmosaic` history, prior to the fork.

* Fixed stale `ggmosaic::` self-references left over from the rename (`vignettes/ggmosaic.Rmd`,
  the bundled Shiny apps under `inst/shiny/`), which broke building since `ggmosaic` is no longer
  on CRAN. Also pointed `_pkgdown.yml` at the new package's own site.

### ggmosaic2 0.5.1

* Added `facet_mosaic_grid()` for mosaic-aware faceting (haleyjeppson/ggmosaic#78): each facet
  panel gets independent x/y product scales and category axes drawn at panel-specific positions,
  and it supports multiple mosaic layers, `theme_mosaic()`, `coord_flip()`, manual product scales,
  margins, and residual shading.

* Mosaic layers (`geom_mosaic()`, `geom_mosaic_text()`, `geom_mosaic_jitter()`) now resolve their
  plot mapping at build time, like ordinary `ggplot2` layers, so an `aes()` mapping added or
  changed after a mosaic layer has already been added is now picked up correctly instead of being
  frozen at the point the layer was added.

* Added `mosaic_settings()` for sharing `divider`, `offset`, and `expected` across sibling mosaic
  layers in one plot, so multi-layer plots (e.g. `geom_mosaic()` + `geom_mosaic_text()`) no longer
  need the same argument repeated on every layer. An explicit layer argument, including
  `expected = NULL`, still overrides the plot-level setting.

* Improved Pearson residual shading: negative residuals are now dark red and positive residuals
  dark blue, with matching dashed/solid cell outlines (disable via `colour = NA`, or override
  colour/linetype/linewidth directly). Added a custom residual legend with signed labels, observed
  extrema, supplied limits, reference values at -4/0/+4, endpoint colour squishing, and
  collision-aware ticks/labels, in both vertical and horizontal layouts.

* Fixed mosaic spacing: `offset` is now the fixed gap at the deepest split, with gaps increasing
  by a factor of 1.5 toward outer splits (previously inconsistent), converted to local rectangle
  coordinates and safely constrained for very small cells; `offset` is validated as a single
  finite, non-negative value. **This changes spacing output relative to earlier versions.**

* Fixed namespace-only use (haleyjeppson/ggmosaic#82): calls such as `ggmosaic2::geom_mosaic()`
  and `ggmosaic2::product()` now work without `library(ggmosaic2)`.

* Variables mapped only to `fill` or `alpha` (and `colour` in `geom_mosaic_jitter()`) remain
  available to the mosaic calculation and point aesthetics, but are no longer shown on the
  automatic product axes; only variables mapped through `x` or `conds` are labeled there
  (haleyjeppson/ggmosaic#39, haleyjeppson/ggmosaic#77). Variables can now be created within
  `geom_mosaic()`, and factors can be reordered for display.

* `theme_mosaic()` now passes additional arguments through `...` to `ggplot2::theme()`.

* Added the `introducing-ggmosaic2` vignette.

* Lightened the default `geom_mosaic()` tile fill (`grey30` -> `grey55`).

* Fixed `inst/CITATION` for the `ggmosaic2` fork: retitled from `ggmosaic`, authors and year are
  now pulled from `DESCRIPTION` instead of hardcoded, and a broken multi-URL field is fixed.

* Deprecated `ggmosaic_app()`, kept only for the historical record.

* The `introducing-ggmosaic2` vignette was edited for clarity and detail.

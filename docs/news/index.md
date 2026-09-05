# Changelog

## Version 0.5.1

- Added
  [`facet_mosaic_grid()`](https://friendly.github.io/ggmosaic2/reference/facet_mosaic_grid.md)
  for mosaic-aware faceting (haleyjeppson/ggmosaic#78): each facet panel
  gets independent x/y product scales and category axes drawn at
  panel-specific positions, and it supports multiple mosaic layers,
  [`theme_mosaic()`](https://friendly.github.io/ggmosaic2/reference/theme_mosaic.md),
  [`coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html),
  manual product scales, margins, and residual shading.

- Mosaic layers
  ([`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md),
  [`geom_mosaic_text()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_text.md),
  [`geom_mosaic_jitter()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_jitter.md))
  now resolve their plot mapping at build time, like ordinary `ggplot2`
  layers, so an
  [`aes()`](https://ggplot2.tidyverse.org/reference/aes.html) mapping
  added or changed after a mosaic layer has already been added is now
  picked up correctly instead of being frozen at the point the layer was
  added.

- Added
  [`mosaic_settings()`](https://friendly.github.io/ggmosaic2/reference/mosaic_settings.md)
  for sharing `divider`, `offset`, and `expected` across sibling mosaic
  layers in one plot, so multi-layer plots
  (e.g. [`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md) +
  [`geom_mosaic_text()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_text.md))
  no longer need the same argument repeated on every layer. An explicit
  layer argument, including `expected = NULL`, still overrides the
  plot-level setting.

- Improved Pearson residual shading: negative residuals are now dark red
  and positive residuals dark blue, with matching dashed/solid cell
  outlines (disable via `colour = NA`, or override
  colour/linetype/linewidth directly). Added a custom residual legend
  with signed labels, observed extrema, supplied limits, reference
  values at -4/0/+4, endpoint colour squishing, and collision-aware
  ticks/labels, in both vertical and horizontal layouts.

- Fixed mosaic spacing: `offset` is now the fixed gap at the deepest
  split, with gaps increasing by a factor of 1.5 toward outer splits
  (previously inconsistent), converted to local rectangle coordinates
  and safely constrained for very small cells; `offset` is validated as
  a single finite, non-negative value. **This changes spacing output
  relative to earlier versions.**

- Fixed namespace-only use (haleyjeppson/ggmosaic#82): calls such as
  [`ggmosaic2::geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md)
  and
  [`ggmosaic2::product()`](https://friendly.github.io/ggmosaic2/reference/product.md)
  now work without
  [`library(ggmosaic2)`](https://friendly.github.io/ggmosaic2/).

- Variables mapped only to `fill` or `alpha` (and `colour` in
  [`geom_mosaic_jitter()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_jitter.md))
  remain available to the mosaic calculation and point aesthetics, but
  are no longer shown on the automatic product axes; only variables
  mapped through `x` or `conds` are labeled there
  (haleyjeppson/ggmosaic#39, haleyjeppson/ggmosaic#77). Variables can
  now be created within
  [`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md),
  and factors can be reordered for display.

- [`theme_mosaic()`](https://friendly.github.io/ggmosaic2/reference/theme_mosaic.md)
  now passes additional arguments through `...` to
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html).

- Added the `introducing-ggmosaic2` vignette.

- Lightened the default
  [`geom_mosaic()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md)
  tile fill (`grey30` -\> `grey55`).

- Fixed `inst/CITATION` for the `ggmosaic2` fork: retitled from
  `ggmosaic`, authors and year are now pulled from `DESCRIPTION` instead
  of hardcoded, and a broken multi-URL field is fixed.

- Deprecated
  [`ggmosaic_app()`](https://friendly.github.io/ggmosaic2/reference/ggmosaic_app.md),
  kept only for the historical record.

- The `introducing-ggmosaic2` vignette was edited for clarity and
  detail.

## Version 0.5.0

`ggmosaic2` is a standalone continuation of `ggmosaic`, which was
removed from CRAN around November 2025 and appeared unmaintained (the
loglinear-models/residual-shading pull request below,
<https://github.com/haleyjeppson/ggmosaic/pull/86>, was never acted on).

Rather than take over the original package name, this work continues
independently as `ggmosaic2`, maintained by Michael Friendly, with
original authors Haley Jeppson, Heike Hofmann, and Di Cook credited as
contributors in `DESCRIPTION`.

The version number picks up from the last CRAN/fork release (0.4.1)
rather than resetting, since this carries forward that code and history
rather than starting fresh. Everything below this entry is inherited
`ggmosaic` history, prior to the fork.

- Fixed stale `ggmosaic::` self-references left over from the rename
  (`vignettes/ggmosaic.Rmd`, the bundled Shiny apps under
  `inst/shiny/`), which broke building since `ggmosaic` is no longer on
  CRAN. Also pointed `_pkgdown.yml` at the new package’s own site.

## Version 0.4.1

Extensive changes to introduce fitting loglinear models and
residual-based shading, described in
<https://github.com/haleyjeppson/ggmosaic/pull/86>

- added labeling for cells (obs/exp/res)
- added loglinear-models vignette to explain this
- added vignette on forms of frequency data
- fix error from ggmosaic vignette related to
  [`tapply()`](https://rdrr.io/r/base/tapply.html) in `R/divide.R`

## Version 0.3.4

- updated for compatible with ggplot2 3.5.0

## Version 0.3.3

- A geom,
  [`geom_mosaic_jitter()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_jitter.md),
  and an associated stat,
  [`stat_mosaic_jitter()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_jitter.md),
  has been added.

- A geom,
  [`geom_mosaic_text()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_text.md),
  and an associated stat,
  [`stat_mosaic_text()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic.md),
  has been added.

- [`geom_mosaic_text()`](https://friendly.github.io/ggmosaic2/reference/geom_mosaic_text.md)
  now supports using labels and ggrepel
  ([@gregeleu](https://github.com/gregeleu),
  [\#50](https://github.com/friendly/ggmosaic2/issues/50)).

- A theme for mosaic plots,
  [`theme_mosaic()`](https://friendly.github.io/ggmosaic2/reference/theme_mosaic.md),
  has been added.

## Version 0.3.0

### Breaking changes

- ggmosaic 0.3.0 is now compatible with ggplot2 3.3.0 and tidyr 1.0.0.

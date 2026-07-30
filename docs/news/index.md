# Changelog

## ggmosaic2 0.5.0

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

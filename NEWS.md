# ggmosaic2 0.5.0

`ggmosaic2` is a standalone continuation of `ggmosaic`, which was removed from CRAN around
November 2025 and appeared unmaintained (the loglinear-models/residual-shading pull request
below, https://github.com/haleyjeppson/ggmosaic/pull/86, was never acted on). Rather than take
over the original package name, this work continues independently as `ggmosaic2`, maintained by
Michael Friendly, with original authors Haley Jeppson, Heike Hofmann, and Di Cook credited as
contributors in `DESCRIPTION`.

The version number picks up from the last CRAN/fork release (0.4.1) rather than resetting, since
this carries forward that code and history rather than starting fresh. Everything below this
entry is inherited `ggmosaic` history, prior to the fork.

# ggmosaic 0.4.1

Extensive changes to intoduce fitting loglinear models and residual-based shading, described in https://github.com/haleyjeppson/ggmosaic/pull/86

* added labeling for cells (obs/exp/res)
* added loglinear-models vignette to explain this
* added vignette on forms of frequency data
* fix error from ggmosaic vignette related to `tapply()` in `R/divide.R`

# ggmosaic 0.3.4

- updated for compatible with ggplot2 3.5.0 

# ggmosaic 0.3.3

- A geom, `geom_mosaic_jitter()`, and an associated stat, `stat_mosaic_jitter()`, has been added.

- A geom, `geom_mosaic_text()`, and an associated stat, `stat_mosaic_text()`, has been added.

- `geom_mosaic_text()` now supports using labels and ggrepel (@gregeleu, #50).

- A theme for mosaic plots, `theme_mosaic()`, has been added.


# ggmosaic 0.3.0

## Breaking changes

- ggmosaic 0.3.0 is now compatible with ggplot2 3.3.0 and tidyr 1.0.0.

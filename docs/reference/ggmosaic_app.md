# Launch shiny app (deprecated)

Shiny app "EDA with Mosaic Plots" for interactive exploratory model
building.

## Usage

``` r
ggmosaic_app(example = c("mosaics", "models"), ...)
```

## Arguments

- example:

  Selected shiny app to launch.

- ...:

  arguments passed on.

## Details

**Deprecated.** Inherited as-is from the original `ggmosaic` package and
kept only for the historical record. It is not maintained, and currently
cannot find its app directory because
[`system.file()`](https://rdrr.io/r/base/system.file.html) still looks
up the old `ggmosaic` package name rather than `ggmosaic2`.

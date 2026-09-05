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

## Value

Called for its side effect of launching a Shiny app; returns the result
of [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Details

**Deprecated.** Inherited as-is from the original `ggmosaic` package and
kept only for the historical record. It is not maintained, and currently
cannot find its app directory because
[`system.file()`](https://rdrr.io/r/base/system.file.html) still looks
up the old `ggmosaic` package name rather than `ggmosaic2`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Deprecated and currently non-functional; see Details.
ggmosaic_app("mosaics")
} # }
```

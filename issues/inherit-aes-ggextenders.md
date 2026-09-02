I'm stuck on a design question in ggmosaic2 (mosaic plots, ggplot2 extension)
and would like advice from people who've built layered stat/geom
extensions before.
This question also relates to: [Add Loglinear Model Residual Shading to ggmosaic (#134)](https://github.com/ggplot2-extenders/ggplot-extension-club/discussions/134)

`geom_mosaic()` and `geom_mosaic_text()` need to agree on several things that
aren't aesthetics: the loglinear model used for `expected` counts, and the
`divider`/`offset` layout. Right now you pass the same arguments to both
layers separately, which means the model gets fit twice and the two layers
can silently disagree if you don't keep the calls in sync.

```r
HairEyeColor |>
    as.data.frame() |>
    ggplot(aes(x = product(Sex, Eye, Hair), weight = Freq)) +
    geom_mosaic(expected = "independence", 
                offset = .02) +
    geom_mosaic_text(expected = "independence",   # Need to match
                     offset = .02,                # the above
                     display_values = "expected",
                     color = "black") +
    scale_fill_residual(limits = c(-4,4)) +
    theme_mosaic(rot_labels = 30)
```

I got normal `aes()` inheritance working (plot-level `aes()` now reaches
mosaic layers the way it does for any other geom), by resolving the merged
mapping in `ggplot_add()`. But that only fixes aesthetics, not parameters
like `expected`, and it turns out `ggplot_add()` is too early anyway - if you
add an `aes()` after the mosaic layer, it's already been resolved and misses
it.

The fix I'm circling is a plot-level `mosaic_settings()` component (shared
`expected`/`divider`/`offset`, explicit layer args override it) resolved at
*build* time via a custom `Layer` subclass with its own `setup_layer()`,
instead of at `ggplot_add()` time. That needs `layer_class` in `layer()`,
which is only reliable from ggplot2 3.5.0 on, and I'd want it to keep working
under 4.0's rewritten plot object too.

Before I build this: has anyone already solved "share a parameter, not an
aesthetic, across sibling layers" in a ggplot2 extension? Is `setup_layer()`
the right hook for build-time mapping resolution, or is there a cleaner
pattern I'm missing? Happy to share more code if useful.

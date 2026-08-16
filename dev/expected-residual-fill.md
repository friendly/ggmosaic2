# Expected-area mosaics and optional residual fill

## Issue

An expected-area mosaic with integrated jitter currently fails to render when
no residual fill scale is supplied:

```r
ggplot(data = HEC_df) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye, Sex)),
    expected = "independence",
    area = "expected",
    jitter = TRUE,
    jitter_mapping = aes(colour = Hair),
    jitter_size = 2,
    jitter_alpha = 0.8,
    seed = 123
  )
```

The rendering error is:

```text
Problem while converting geom to grob.
Error occurred in the 1st layer.
Caused by error:
colours encodes as numbers must be positive
```

Adding `scale_fill_residual()` makes the plot render, but residual shading is
not necessarily wanted in this display. The point density already represents
`observed / expected`, so residual fill can be redundant or distracting.

## Why the error occurs

When `expected` is non-`NULL` and the user has not mapped `fill`,
`StatMosaic` currently copies the calculated Pearson residual directly into
the computed `fill` column:

```r
res$fill <- res$.residual
```

Typical values include positive and negative numbers such as `3.01`, `-0.69`,
and `-4.08`. Because there was no declared fill mapping when ggplot2 discovered
and trained scales, these numbers do not pass through a continuous fill scale.
They reach `GeomRect` as though they were literal colour encodings, and
negative numeric colour encodings are invalid.

`scale_fill_residual()` happens to resolve the problem because it trains and
maps the computed fill values to valid colours before rectangle drawing.

This problem is independent of expected-area geometry and jitter placement.
The fitted counts, rectangle boundaries, observed point counts, and jitter
coordinates are calculated correctly.

## Why `after_stat(.residual)` is not the complete fix

A conventional ggplot2 fix would declare a computed aesthetic mapping:

```r
fill = after_stat(.residual)
```

That would make ggplot2 recognize `fill` as a continuous mapped aesthetic.
Without an explicit scale, ggplot2 would install its ordinary continuous fill
scale; with `scale_fill_residual()`, the package-specific diverging scale would
replace it.

This would prevent the rendering error and make `scale_fill_residual()`
optional for rendering. However, it would still automatically colour the
tiles by residual. It would not preserve `GeomMosaic`'s normal grey fill.

For an expected-area mosaic whose primary diagnostic is observed-point
density, automatically substituting a generic continuous gradient is not the
desired default.

## Desired semantic separation

Three choices should remain independent:

1. `expected` selects and fits the loglinear model.
2. `area` selects whether observed or fitted counts determine rectangle
   geometry.
3. A separate option selects whether residuals determine tile fill.

The preferred default for this construction is therefore:

```r
geom_mosaic(
  ...,
  expected = "independence",
  area = "expected",
  jitter = TRUE
)
```

The model is fitted, expected counts determine area, observed counts determine
point density, and tiles retain the geom's ordinary grey fill.

Residuals should still be calculated and remain available as `.residual`, but
they should affect fill only when explicitly requested.

## API complication

A ggplot2 scale normally transforms an existing aesthetic mapping; it does not
create that mapping. Consequently, if the mosaic layer does not map residuals
to `fill`, adding only this cannot conventionally enable residual shading:

```r
+ scale_fill_residual()
```

Some explicit mechanism must request the residual mapping as well as choose
its scale.

## Possible APIs

### 1. Explicit boolean argument

```r
geom_mosaic(
  ...,
  expected = "independence",
  area = "expected",
  jitter = TRUE,
  residual_fill = TRUE
) +
  scale_fill_residual()
```

`residual_fill = FALSE` would retain the normal grey fill and would be the
default. When `TRUE`, the wrapper would install
`fill = after_stat(.residual)` after mosaic layout variables have been
prepared, so the computed fill does not become an additional partition.

Advantages:

- Clearly separates fitting, geometry, and shading.
- Preserves neutral expected-area jitter plots by default.
- Uses an ordinary ggplot2 computed-aesthetic mapping and scale pipeline.
- Makes the user's intent visible in the layer call.

Disadvantage:

- Residual shading requires both `residual_fill = TRUE` and
  `scale_fill_residual()` unless the wrapper also supplies the specialized
  scale.

### 2. A more general `shade` argument

```r
geom_mosaic(
  ...,
  expected = "independence",
  area = "expected",
  jitter = TRUE,
  shade = "residual"
) +
  scale_fill_residual()
```

For example, `shade = c("none", "residual")` could leave room for future
shading modes. This is more extensible but introduces a broader API than the
current issue requires.

### 3. Explicit user mapping

```r
geom_mosaic(
  aes(
    weight = Freq,
    x = product(Hair, Eye, Sex),
    fill = after_stat(.residual)
  ),
  expected = "independence",
  area = "expected",
  jitter = TRUE
) +
  scale_fill_residual()
```

This is closest to standard ggplot2 composition, but the mapping-preparation
code must special-case `after_stat()` so it is not interpreted as a mosaic
partition variable. It is also verbose for the package's established
residual-shading feature.

### 4. Make `scale_fill_residual()` activate the mapping

The scale could be turned into a custom `ggplot_add()` object that searches
for mosaic layers and inserts `fill = after_stat(.residual)`.

This would preserve the concise call:

```r
geom_mosaic(..., expected = "independence") +
  scale_fill_residual()
```

However, scales normally do not mutate layer mappings. This approach would be
surprising, couple the scale tightly to particular layer implementations, and
be harder to reason about with multiple layers. It is not recommended.

## Recommended direction

Use an explicit `residual_fill` argument, or the equivalent narrowly scoped
`shade` argument, rather than automatically mapping every fitted model to
fill.

The intended behavior would be:

```r
# Model and expected geometry, neutral default tiles
geom_mosaic(
  ...,
  expected = "independence",
  area = "expected",
  jitter = TRUE
)

# Model, expected geometry, observed points, and residual shading
geom_mosaic(
  ...,
  expected = "independence",
  area = "expected",
  jitter = TRUE,
  residual_fill = TRUE
) +
  scale_fill_residual()

# Explicit fixed tile styling remains possible
geom_mosaic(
  ...,
  expected = "independence",
  area = "expected",
  jitter = TRUE,
  fill = "grey95"
)
```

Implementation should remove the direct assignment of numeric residuals to
`res$fill`. If residual shading is requested, the wrapper should instead add a
proper `after_stat(.residual)` fill mapping after `prepare_mosaic_mapping()`
has identified the variables that actually define cells.

## Compatibility question

Changing the default would alter the existing documented behavior in which a
non-`NULL` `expected` specification automatically enables residual fill.
Before implementation, decide whether:

- neutral fill becomes the default for every mosaic with `expected`;
- neutral fill becomes the default only for `area = "expected"` with
  integrated jitter; or
- the old automatic behavior is retained temporarily and deprecated before a
  later default change.

Automatically changing shading based only on `jitter = TRUE` is not ideal: it
couples a styling choice to point rendering and could surprise users who want
both point density and residual fill.

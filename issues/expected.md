# Expected-area mosaics with jittered observations

## Issue

The README claims that jittered points reveal departures from independence
through varying point density. That is not true for the current example:

- Mosaic cell area is proportional to the observed count, \(O_i\).
- The jitter layer draws \(O_i\) points in that cell.
- Therefore, density \(O_i / A_i\) is theoretically constant.

Any visible density differences arise from random jitter, overlap, gaps, and
point padding rather than from the fitted model. Only the residual shading
currently represents model departure.

For point density to be meaningful, cell area should instead be proportional
to the model's expected count, \(E_i\), while retaining \(O_i\) observed
points. Density would then be proportional to \(O_i / E_i\).

This construction also needs to account for consistency between layers, zero
cells, weights, gaps, overplotting, and large counts.

## Open API question

Should this be expressed through an explicit option such as `area =
"expected"`, used consistently by both the mosaic and jitter layers, while
`expected` selects the loglinear model?

```r
geom_mosaic(
  aes(x = product(Sex, Eye, Hair)),
  expected = "independence",
  area = "expected"
) +
geom_mosaic_jitter(
  aes(x = product(Sex, Eye, Hair)),
  expected = "independence",
  area = "expected"
)
```

Alternatively, should the API coordinate the two layers through a helper or
some other mechanism? In particular, adding a jitter layer should not silently
change the construction of another layer.

## API choices

The layout arguments cannot legitimately differ between the tiles and points:

```r
# Invalid: the points and tiles use different cells
geom_mosaic(
  aes(weight = Freq, x = product(Sex, Eye, Hair)),
  expected = "independence",
  area = "expected"
) +
geom_mosaic_jitter(
  aes(weight = Freq, x = product(Sex, Eye, Hair))
)
```

### 1. Repeat the layout arguments

```r
geom_mosaic(
  aes(weight = Freq, x = product(Sex, Eye, Hair)),
  expected = "independence",
  area = "expected"
) +
geom_mosaic_jitter(
  aes(
    weight = Freq,
    x = product(Sex, Eye, Hair),
    colour = Hair
  ),
  expected = "independence",
  area = "expected"
)
```

This is conventional ggplot2 composition, but verbose and easy to mismatch.

### 2. Inherit from the preceding mosaic layer

```r
geom_mosaic(
  aes(weight = Freq, x = product(Sex, Eye, Hair)),
  expected = "independence",
  area = "expected"
) +
geom_mosaic_jitter(
  aes(colour = Hair)
)
```

Here the jitter layer would inherit the data, positional mappings, model, area,
divider, and offset. This is concise, but addition-order dependent and
ambiguous when more than one mosaic layer precedes it.

### 3. Return a coordinated pair of layers

```r
geom_mosaic_with_jitter(
  mapping = aes(
    weight = Freq,
    x = product(Sex, Eye, Hair)
  ),
  jitter_mapping = aes(colour = Hair),
  expected = "independence",
  area = "expected",
  mosaic_params = list(alpha = 0.2),
  jitter_params = list(size = 2, alpha = 0.8, seed = 123)
)
```

This enforces a shared layout, but adds another constructor for one statistical
graphic.

### 4. Incorporate jitter into `geom_mosaic()`

```r
geom_mosaic(
  aes(weight = Freq, x = product(Sex, Eye, Hair)),
  expected = "independence",
  area = "expected",
  jitter = TRUE,
  jitter_mapping = aes(colour = Hair),
  jitter_size = 2,
  jitter_alpha = 0.8,
  seed = 123
)
```

This is the preferred direction. One stat calculation would produce both the
expected-area rectangles and the observed points, so inconsistent geometry
cannot be requested. `jitter_mapping` keeps point aesthetics separate from
tile aesthetics.

The core semantics would be:

```r
# Observed-area mosaic without points
geom_mosaic(
  aes(weight = Freq, x = product(Sex, Eye, Hair))
)

# Observed-area mosaic with observed points
geom_mosaic(
  aes(weight = Freq, x = product(Sex, Eye, Hair)),
  jitter = TRUE
)

# Expected-area mosaic with observed points
geom_mosaic(
  aes(weight = Freq, x = product(Sex, Eye, Hair)),
  expected = "independence",
  area = "expected",
  jitter = TRUE
)

# Invalid: expected areas require a fitted model
geom_mosaic(
  aes(weight = Freq, x = product(Sex, Eye, Hair)),
  area = "expected",
  jitter = TRUE
)
```

In every case, `area` selects the values used to construct the rectangles and
the number of points is the observed count. `area = "expected"` should require
a non-NULL `expected` specification.

`geom_mosaic_jitter()` can remain temporarily as a lower-level compatibility
interface, but it should not be the recommended way to construct an
expected-area mosaic with observed points. Its current implementation also
does not consume `expected`; passing that argument is treated as an unknown
parameter, so supporting the repeated-layer alternative would require changes
to both its wrapper and stat.

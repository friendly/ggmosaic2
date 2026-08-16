# Expected-area mosaic implementation

## Summary

The preferred option 4 API from `dev/expected.md` is implemented. A single
`geom_mosaic()` layer can now calculate expected-area rectangles and draw
observed-count jittered points from the same computed cell data:

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

The construction keeps the three quantities deliberately separate:

- `area` chooses the counts used by the recursive rectangle split.
- `.n` and the number of jittered points remain based on observed counts.
- `.expected` and `.residual` remain the fitted counts and Pearson residuals,
  irrespective of which counts determine the rectangles.

Consequently, point density in `area = "expected"` cells is proportional to
`observed / expected`. The default remains `area = "observed"`, so existing
mosaics retain their previous geometry.

## Calculation changes

### `R/calculate.R`

- Added `area = c("observed", "expected")` to `prodcalc()`. It is the final
  formal argument to avoid changing the meaning of existing positional calls.
- Added an explicit error when `area = "expected"` is requested without a
  non-`NULL` `expected` model specification.
- Reordered `prodcalc()` so it first constructs the finest observed
  cross-classification across all marginal and conditioning variables.
- Renamed the finest table's observed weight to `.n` before fitting. Model
  fitting therefore always uses observed counts, independent of `area`.
- Moved `build_model_formula()` and `fit_loglinear_model()` ahead of
  `divide()`, producing `.expected` and `.residual` on that finest table.
- For `area = "observed"`, the original input weights continue through
  `productplots::margin()` and `divide()`.
- For `area = "expected"`, `.expected` is temporarily renamed to `.wt` and
  passed through exactly the same `margin()`/`divide()` path. This makes every
  recursive fitted margin self-consistent, including conditional layouts.
- Joined `.n`, `.expected`, and `.residual` back onto the completed tree. As
  before, these finest-cell quantities are populated on deepest-level rows.

## Preferred integrated API

### `R/geom-mosaic.r`

`geom_mosaic()` now accepts:

- `area = c("observed", "expected")`
- `jitter = FALSE`
- `jitter_mapping = NULL`
- `jitter_size = 1`
- `jitter_alpha = 0.8`
- `seed = NA`

When `jitter = TRUE`, `GeomMosaic$draw_panel()`:

1. draws the deepest-level rectangles;
2. rounds each cell's observed `.n` to a whole point count;
3. repeats the already-computed cell row that many times;
4. generates uniform coordinates inside that same row's rectangle;
5. pads the coordinates by point size and collapses the padding to the cell
   midpoint when a cell is too narrow or short; and
6. returns the rectangle and point grobs in one `grobTree()`.

Because both grobs consume the same stat output in the same layer, integrated
tiles and points cannot disagree about `divider`, `offset`, `expected`, or
`area`.

Numeric `seed` values make coordinates reproducible. `seed = NA` generates a
fresh random placement. Cells with missing, non-finite, zero, or negative
observed counts produce no points. Fractional observed weights are rounded to
the nearest whole point.

Fixed `colour`/`color` supplied in `...` retains its historical meaning as the
tile outline colour when jitter is enabled. Point size and alpha are controlled
separately by `jitter_size` and `jitter_alpha`.

### Separate jitter aesthetics

`R/utilities.R` adds `prepare_integrated_jitter_mapping()`. It keeps point
mappings separate from the tile `fill` and `alpha` mappings while still using
ordinary ggplot2 scales and legends.

The integrated mapping currently supports `colour`, `shape`, `size`, and
`stroke`. A mapped expression must already occur in `x`, `conds`, `fill`, or
`alpha`. This enforces one point-aesthetic value per existing mosaic cell and,
importantly, prevents a point-only mapping from silently adding a new mosaic
partition. Unsupported aesthetics and non-`aes()` inputs produce direct
errors; supplying `jitter_mapping` without `jitter = TRUE` also errors.

`StatMosaic` copies these point variables onto the computed cell rows. When a
point colour mapping occupies ggplot2's regular `colour` aesthetic, the
residual-based rectangle colour is retained in `.mosaic_tile_colour` and used
only for drawing the tiles. The combined legend key draws both the polygon and
point glyphs.

## Stat and compatibility-layer changes

### `R/stat-mosaic.r`

- Added and validated `area` in `stat_mosaic()`.
- Passed `area` through `StatMosaic$compute_panel()` to `prodcalc()`.
- Added propagation of integrated jitter aesthetics from the mosaic cell
  columns to ggplot2 aesthetics.
- Preserved residual outline colours separately when the point layer uses the
  regular colour aesthetic.

### `R/geom-mosaic-jitter.R` and `R/stat-mosaic-jitter.r`

- Kept `geom_mosaic_jitter()` as requested.
- Added `expected` and `area` to both the geom and stat wrappers.
- Passed the model, variable labels, and area choice into `prodcalc()`.
- The compatibility layer can therefore reproduce an expected-area layout,
  but it still computes its own layout. Documentation recommends
  `geom_mosaic(jitter = TRUE)` whenever tiles and observed points are meant to
  be coordinated.
- Existing `drop_level`, `weight2`, seed, and observed-area behavior remain in
  place.

## Documentation and examples

- Regenerated `man/geom_mosaic.Rd`, `man/geom_mosaic_jitter.Rd`, and
  `man/prodcalc.Rd` with the new arguments and semantics.
- Added an expected-area integrated-jitter example to `geom_mosaic()`.
- Expanded `dev/HEC-jitter.R` with:
  - the preferred one-layer API;
  - the repeated two-layer compatibility form; and
  - a guarded `vcd::mosaic(type = "expected")` plus
    `vcdExtra::labeling_points(value_type = "observed")` reference.

## Tests and validation

Added `tests/expected-area-jitter.R`, covering:

- exact fitted-count area proportions when `offset = 0`;
- preservation of observed `.n`, `.expected`, and `.residual` when switching
  from observed to expected geometry;
- unchanged default/explicit observed-area output;
- the required-model error for expected areas;
- the preferred API producing one layer with all expected computed columns;
- one rendered point per observed count (592 for `HairEyeColor`);
- colour mapping through `jitter_mapping`;
- matching expected-area boundaries in the compatibility two-layer form; and
- rejection of a point mapping that would silently introduce a new partition.

Validation completed on 2026-08-16:

- source installation with `R CMD INSTALL`: passed;
- every script in `tests/`, run against the installed package: passed;
- `R CMD check --no-manual` with `_R_CHECK_FORCE_SUGGESTS_=false`: **Status:
  OK**. Forced Suggests was disabled because the optional `NHANES` package was
  unavailable in the offline check environment; the check reported this as
  informational only.

The design note explicitly deferred bespoke zero-cell/small-expected-count
behavior. This implementation nevertheless avoids generating points for
non-positive observed cells and keeps point coordinates stable for cells whose
drawable interior is smaller than the requested point padding.

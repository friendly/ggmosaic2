# Plan for merging `master` into `expected`

> **Review status:** Gavin has checked this plan only through the sentence
> **“No new `residual_fill` argument is required.”** Everything after that
> sentence remains unreviewed. This document is an implementation plan, not a
> record of completed work.

## Goal

Merge `master` into `expected` while retaining the new build-time mapping and
plot-scoped settings API from `master`, then add expected-area mosaics cleanly
to that architecture.

The resulting API should support a mosaic whose tile areas are proportional to
fitted counts while a separate `geom_mosaic_jitter()` layer draws observed
counts. Model fitting, tile geometry, point counts, and residual shading must
remain distinct choices.

## Decisions already made

1. Keep `geom_mosaic_jitter()` as a proper, independent geom/stat pair.
2. Do not add `jitter = TRUE` or `jitter_*` arguments to `geom_mosaic()`.
3. Extend `mosaic_settings()` with `area`, so related mosaic, text, and jitter
   layers can inherit the same layout choice.
4. Preserve normal ggplot2 layer independence. Do not make a jitter layer
   inspect a preceding mosaic layer, depend on layer order, or read geometry
   from a shared mutable cache.
5. Use observed counts for jitter point counts even when expected counts
   determine cell area.
6. Fit a model and calculate `.expected` and `.residual` when requested, but
   keep tiles grey unless the user explicitly adds `scale_fill_residual()`.
7. Retain explicit layer arguments as overrides of plot-level settings,
   including an explicit `expected = NULL`.

## Target public API

The primary example should be:

```r
hec <- as.data.frame(HairEyeColor)

ggplot(
  hec,
  aes(weight = Freq, x = product(Hair, Eye, Sex))
) +
  mosaic_settings(
    expected = "independence",
    area = "expected"
  ) +
  geom_mosaic() +
  geom_mosaic_jitter(
    aes(colour = Hair),
    seed = 123
  )
```

This should:

- fit the independence model;
- use fitted counts to construct the tile areas;
- use observed `Freq` values to determine point counts;
- place the points inside geometry independently reproduced by the jitter stat;
- leave the tiles at the ordinary `GeomMosaic` grey fill; and
- produce no residual-fill guide.

Residual shading should be requested by adding only:

```r
+ scale_fill_residual()
```

The model has already been requested through `expected`; the scale is the
explicit request to display its residuals.

Observed-area behavior remains the default:

```r
ggplot(hec, aes(weight = Freq, x = product(Hair, Eye, Sex))) +
  geom_mosaic()
```

Layer-level arguments remain available and override plot-level settings:

```r
ggplot(hec, aes(weight = Freq, x = product(Hair, Eye, Sex))) +
  mosaic_settings(expected = "independence", area = "expected") +
  geom_mosaic() +
  geom_mosaic_jitter(area = "observed")
```

That example is allowed: the API should not silently force sibling layers to
have identical structures. Its points would deliberately use observed-area
geometry. Documentation should explain that overlays align only when their
data, structural mappings, divider, offset, model, and area settings agree.

## Settings contract

Extend the constructor to:

```r
mosaic_settings(divider, offset, expected, area)
```

Validate `area` with the choices `"observed"` and `"expected"`; its default is
`"observed"`.

Resolution continues to happen at plot-build time with the precedence already
established on `master`:

1. an explicitly supplied layer argument;
2. the corresponding value in `mosaic_settings()`; and
3. the layer default.

The missing-argument sentinel must continue to distinguish omission from an
explicit value. In particular, `expected = NULL` on a layer disables a model
inherited from the plot.

The settings applicability matrix becomes:

| Layer/stat family | `divider` | `offset` | `expected` | `area` |
| --- | --- | --- | --- | --- |
| mosaic tiles | yes | yes | yes | yes |
| mosaic text | yes | yes | yes | yes |
| mosaic jitter | yes | yes | only when effective `area = "expected"` | yes |

`geom_mosaic_text()` and `stat_mosaic_text()` need `area` so labels and display
values can be centered in the same cells as the tiles. Their existing
`expected`-dependent display values continue to work.

For jitter layers, the effective `area` controls whether fitting is needed:

- `area = "observed"`: do not fit a model merely because an `expected` setting
  exists elsewhere on the plot;
- `area = "expected"`: resolve and use `expected`, and fail if it is `NULL`;
- explicit layer arguments still take precedence over plot settings.

This conditional applicability avoids unnecessary model fitting for ordinary
jitter layers while allowing one plot-level declaration to coordinate an
expected-area overlay.

## Geometry and shading semantics

The four relevant quantities have separate roles:

- `weight`: observed counts used to construct the contingency table and fit
  the model;
- `.expected`: fitted counts, used for geometry only when
  `area = "expected"`;
- `.residual`: Pearson residuals, retained as a computed variable regardless
  of whether they are displayed; and
- `weight2`: optional counts used only to determine how many jitter points to
  draw.

The behavior matrix is:

| `expected` | `area` | geometry | residual available | default tile fill |
| --- | --- | --- | --- | --- |
| `NULL` | `"observed"` | observed | no | grey |
| model | `"observed"` | observed | yes | grey |
| model | `"expected"` | fitted | yes | grey |
| `NULL` | `"expected"` | invalid | no | error |

Adding `scale_fill_residual()` to either model-enabled case changes only the
fill display; it does not change the fitted model or geometry.

An explicit mapped or fixed fill continues to control ordinary tile styling
when no residual scale is present. No new `residual_fill` argument is required.

> **Review boundary:** Everything below this point remains unreviewed.

## Residual-fill activation

### Current defect

On both branches, residual handling can place raw numeric values directly into
the computed `fill` column. Without a trained fill scale, negative residuals
reach `GeomRect` as literal numeric colour encodings and rendering fails. This
is independently broken; it is not caused by expected-area geometry or
jitter.

Remove the direct `res$fill <- res$.residual` behavior. Residual fill must use
a proper computed aesthetic so ggplot2 trains and maps a scale before drawing.

### Preferred mechanism

For a model-enabled mosaic tile layer with no explicit fill mapping or fixed
fill:

1. After `prepare_mosaic_mapping()` has identified the variables that define
   cells, install a computed mapping equivalent to
   `fill = after_stat(.residual)`. Adding it after mapping preparation prevents
   the residual from becoming another partition variable.
2. Give the final `.residual` vector a small internal numeric class, for
   example `ggmosaic_residual`.
3. Register `scale_type.ggmosaic_residual()` to return a private scale type,
   such as `"mosaic_residual"`.
4. Supply a private default fill scale for that type which maps every residual
   to `grey55` and suppresses its guide.
5. Make the private scale constructor discoverable in the plot environment in
   the same localized way that `LayerMosaic` exposes the product scales.
6. Keep `scale_fill_residual()` as the explicit diverging scale. When present,
   it replaces the neutral default scale and displays the residual guide.

This keeps the mapping conventional while making the no-scale appearance
neutral. Prototype this mechanism against the supported ggplot2 versions
before committing to it, because the internal numeric class must survive stat
output and `after_stat()` scale discovery.

If the class does not survive reliably, stop and revise the design rather than
falling back to raw numeric `fill`, automatic generic continuous colors, or
layer-order mutation.

### Explicit fill conflicts

ggplot2 normally has one fill scale per plot. A non-residual `aes(fill = ...)`
and `scale_fill_residual()` therefore cannot both describe the same mosaic
layer: the residual scale would be trained on the user's unrelated fill data.

Make `scale_fill_residual()` identifiable through an internal marker, subclass,
or attribute. During build-time layer setup, inspect the final inherited plus
layer mapping, fixed aesthetics, and plot scales.

Use these rules:

- no explicit fill plus no residual scale: use the computed residual mapping
  with the neutral private default scale;
- no explicit fill plus `scale_fill_residual()`: use the computed residual
  mapping with residual colors and its guide;
- explicit `fill = after_stat(.residual)` plus `scale_fill_residual()`: accept;
- any other mapped or fixed fill without `scale_fill_residual()`: retain the
  user's fill;
- any other mapped or fixed fill with `scale_fill_residual()`: fail with the
  targeted error below.

```text
`scale_fill_residual()` cannot be used with the explicit fill mapping
in `geom_mosaic()`. Remove `aes(fill = ...)` to shade by residuals, or
remove `scale_fill_residual()` to retain the mapped fill.
```

The check must use the final computed mapping so it also catches fill inherited
from `ggplot(aes(...))`. Apply the same rule to fixed fill parameters even
though the wording refers to a mapping; if useful during implementation,
adjust only the noun in the fixed-fill version while retaining the two concrete
remedies.

With multiple mosaic tile layers, a residual fill scale is valid only when
every participating layer either has no explicit fill or explicitly maps
`after_stat(.residual)`. Independent fill meanings in one ggplot remain outside
scope and require a separate multiple-scale facility such as `ggnewscale`.

Residual outlines should remain tied to the presence of valid residuals, not
to whether residual fill is displayed. Preserve `master`'s positive, negative,
and numerical-zero outline logic, along with explicit `colour`, `linetype`, or
`linewidth` overrides.

## Expected-area calculation

Refactor `prodcalc()` around one canonical finest-cell table:

1. Parse the product formula and identify all marginal and conditioning
   variables.
2. Aggregate input rows at the finest cross-classification, preserving one
   observed `.n` value for every complete cell represented by the calculation.
3. When a model is required, fit it to that table before recursive layout and
   attach `.expected` and `.residual` to the same rows.
4. Select a layout weight:
   - observed `.n` for `area = "observed"`;
   - fitted `.expected` for `area = "expected"`.
5. Pass the selected value through the existing `productplots::margin()` and
   `divide()` path. Do not create a second geometry algorithm.
6. Carry `.n`, `.expected`, and `.residual` through to the final cell rows so
   tiles, text, point counts, and computed aesthetics can use them without
   changing the geometry source.

Using the same marginalization and division code for observed and expected
areas ensures self-consistent recursive margins for independence, conditional,
custom-formula, and saturated models.

### Failure policy

Expected-area geometry must be strict. If `area = "expected"`, fail clearly
when:

- the effective `expected` value is `NULL`;
- model fitting fails;
- fitted values are missing, negative, or non-finite;
- fitted values cannot be aligned one-to-one with the finest cells; or
- a group has no positive finite total from which to construct geometry.

Do not silently substitute observed areas. A plot explicitly requesting
expected geometry must either receive expected geometry or an actionable
error.

If the existing observed-area residual-only path currently warns and falls
back after a model-fit failure, that compatibility behavior may remain for the
merge. Keep the stricter expected-area path isolated and document the
difference.

### Zero and sparse cells

Retain zero-count cells when they are part of the fitted contingency table so
a positive fitted count can create visible expected area with zero observed
points. Confirm behavior for:

- observed zero and positive expected count;
- positive observed and very small expected count;
- structural/missing combinations;
- zero-width observed cells;
- conditional groups with zero totals; and
- faceted or grouped calculations.

The implementation should not invent unobserved factor combinations beyond
the package's established table-completion semantics. Document exactly which
factor levels are completed after inspecting the current calculation path.

## Jitter calculation

`StatMosaicJitter` remains responsible for reproducing its own geometry and
generating points. Thread effective `area` and, when required, `expected`
through its call to `prodcalc()`.

Point counts remain observed by default:

- use `.n` when `weight2` is absent;
- use aggregated `weight2` when present;
- never replace point counts with `.expected` merely because
  `area = "expected"`.

Improve the `weight2` implementation by aggregating it once at the canonical
finest-cell level and joining it by structural cell keys. Do not call
`prodcalc()` a second time solely to obtain `.n2`; a second full layout is
unnecessary and can silently misalign rows.

Define and test point-count conversion explicitly:

- zero produces no points;
- positive fractional totals use the package's documented rounding rule;
- negative or non-finite totals fail with a clear message; and
- very large totals retain current behavior for this merge, with the memory
  cost documented rather than adding an unrelated sampling API.

Preserve `seed`, `drop_level`, point padding, and existing point-aesthetic
behavior unless a change is required for correctness.

## Mapping compatibility

Retain `master`'s build-time `prepare_mosaic_mapping()` behavior, including:

- `inherit.aes = TRUE` and `FALSE`;
- plot mappings added or modified after layer construction;
- safe internal names for transformed expressions;
- product-axis labels based only on `x` and `conds`; and
- the historical rule that mapped structural aesthetics can add an innermost
  partition when they do not duplicate an `x` or `conds` expression.

That last rule applies to jitter `colour` as well. In the target example,
`colour = Hair` does not create a new cell partition because `Hair` is already
inside `product(Hair, Eye, Sex)`. A colour mapped to an unrelated variable may
create finer jitter cells, as it does today.

Do not add automatic warnings comparing sibling mappings. Layers may
deliberately use different data or structures, and `mosaic_settings()` shares
calculation parameters rather than asserting that mappings are identical.
Explain the alignment requirement in documentation and cover the standard
aligned overlay in tests.

## Merge and implementation sequence

### 1. Record a clean baseline

- Confirm `expected` and `master` are clean and synchronized with their remote
  tracking refs.
- Run the existing tests on each branch before resolving conflicts.
- Save test output so regressions can be distinguished from pre-existing
  failures.

### 2. Merge `master` into `expected`

Resolve the four known conflict areas by using `master` as the architectural
base and then porting only the expected-area behavior:

- `R/geom-mosaic.r`: retain `LayerMosaic`, build-time settings resolution,
  inheritance, and ordinary `GeomMosaic`; add `area`, but discard integrated
  jitter arguments and composite rectangle/point grobs.
- `R/geom-mosaic-jitter.R`: retain the standalone master geom and layer
  constructor; add `expected` and `area` resolution needed for expected-area
  geometry.
- `R/stat-mosaic.r`: retain master mapping specs, product scales, residual
  outlines, and text compatibility; thread `area` through the refactored
  calculation and remove direct raw-residual fill assignment.
- `R/stat-mosaic-jitter.r`: retain the independent jitter stat; add conditional
  model fitting, expected-area geometry, and the single-pass `weight2` path.

Also update the non-conflicting calculation and settings files deliberately;
do not rely on a conflict marker to identify every semantic integration point.

### 3. Extend settings and wrappers

- Add `area` validation to `mosaic_settings()`.
- Extend the applicable layer/stat constructors and their missing-argument
  sentinels.
- Preserve addition-order independence and replacement semantics for repeated
  `mosaic_settings()` calls.
- Ensure `mosaic_settings(expected = NULL)` still clears a prior model setting
  without unexpectedly resetting `area`.

### 4. Refactor the shared calculation

- Build the canonical finest-cell table.
- Fit before layout when necessary.
- Select observed or expected layout weights.
- Preserve computed columns and variable labels.
- Aggregate `weight2` without a second layout calculation.

### 5. Repair residual fill

- Prototype the internal residual class and neutral default scale.
- Add the computed mapping after structural mapping preparation.
- Mark and detect `scale_fill_residual()`.
- Add the explicit-fill conflict validation and error message.
- Preserve residual outlines independently of fill activation.

### 6. Update text and jitter

- Make mosaic text use the effective area setting so centers align.
- Make jitter fit a model only for expected geometry.
- Verify separate stats produce numerically identical cell boundaries when
  given identical data, mappings, and effective settings.

### 7. Remove obsolete expected-branch design

Do not port or retain:

- `geom_mosaic(jitter = TRUE)`;
- `jitter_mapping` or `jitter_*` arguments on `geom_mosaic()`;
- composite mosaic-and-point grobs;
- cross-layer geometry caches;
- preceding-layer inspection; or
- duplicate expected-area layout algorithms.

Historical development notes may remain as history, but current documentation
must not recommend the rejected integrated-jitter API.

## Test plan

### Settings and inheritance

- `area` constructor validation and default.
- Explicit layer value > plot setting > default.
- Explicit `expected = NULL` overrides an inherited model.
- Repeated settings calls replace only supplied fields.
- Settings work regardless of their position among layers.
- Cloned/reused base plots remain isolated.
- Namespace-only use still discovers product and residual default scales.

### Expected geometry

- Independence, saturated, conditional, and custom-formula models.
- Expected areas match fitted cell proportions.
- Observed-area results remain unchanged.
- Tile, text, and jitter boundaries agree for identical effective inputs.
- `area = "expected"` without a model errors.
- Invalid or failed fits never fall back to observed geometry.
- Facets, conditioning variables, transformed mappings, weights, and offsets.
- Zero and sparse cell cases.

### Jitter

- Expected-area cells contain observed-count points.
- `weight2` affects point counts but not geometry or model fitting.
- Zero, fractional, invalid, and large point counts.
- Reproducible `seed` behavior and no accidental global RNG changes.
- `drop_level` remains correct under expected geometry.
- A point aesthetic already present in `product()` does not add a partition;
  an unrelated point aesthetic retains historical partition behavior.

### Residual fill

- Model-enabled plots without an explicit residual scale render grey and have
  no fill guide.
- Adding `scale_fill_residual()` produces the diverging palette and guide.
- `.residual` remains available to `after_stat()`.
- Explicit `aes(fill = after_stat(.residual))` is accepted.
- Inherited, layer-specific, discrete, numeric, and fixed non-residual fills
  work without the residual scale.
- Each of those non-residual fills plus `scale_fill_residual()` produces the
  targeted error.
- Multiple mosaic layers are accepted only when all fill uses are compatible
  with the residual scale.
- Residual outline sign and zero-tolerance behavior remain unchanged.

### Regression coverage

- Existing `master` tests for `LayerMosaic`, `inherit.aes`, settings,
  namespace-only usage, product axes, display values, and residual outlines.
- Existing `expected` numerical tests, rewritten around the standalone jitter
  layer and the new settings API.
- Package examples and vignettes build without stale integrated-jitter calls.
- `R CMD check` succeeds after generated documentation is refreshed.

## Documentation changes

Update roxygen and generated `.Rd` files for:

- `mosaic_settings()` and the new `area` setting;
- mosaic tile, text, and jitter geoms/stats;
- `weight`, `weight2`, `.expected`, and `.residual` roles;
- neutral model-enabled fill versus explicit residual shading;
- the one-fill-scale conflict and its error;
- the requirement that sibling overlay mappings/settings agree if their
  geometry is intended to align; and
- strict expected-area failure behavior.

Use the HairEyeColor example above as the principal expected-area jitter
example. Include a second version with `scale_fill_residual()` so point density
and residual shading are shown as separate display choices.

Remove or rewrite examples that recommend `geom_mosaic(jitter = TRUE)`. Update
NEWS and any vignette discussion of automatic residual fill, since
model-enabled plots will now remain grey until the residual scale is added.

Regenerate documentation only after the public signatures and semantics are
stable.

## Acceptance criteria

The merge is complete when:

1. `master`'s build-time mapping and plot-scoped settings behavior is intact.
2. `area = "expected"` works through both layer arguments and
   `mosaic_settings()`.
3. Separate mosaic, text, and jitter layers reproduce matching geometry from
   matching inputs without communicating with one another.
4. Expected-area jitter uses expected counts for area and observed or
   `weight2` counts for points.
5. Model-enabled mosaics render grey without `scale_fill_residual()`.
6. Adding `scale_fill_residual()` alone activates residual shading.
7. Conflicting explicit fill use produces the agreed targeted error.
8. No integrated-jitter API or composite grob remains.
9. Existing and new regression tests pass, documentation is regenerated, and
   `R CMD check` succeeds.

## Out of scope

- Multiple independent fill scales in one ggplot.
- Automatic comparison or synchronization of sibling layer mappings.
- Cross-layer model/layout caching.
- A new point-sampling or maximum-point API for very large counts.
- Changes to the historical rule that non-positional aesthetics may define
  mosaic partitions.
- Silent recovery from invalid expected-area model fits.

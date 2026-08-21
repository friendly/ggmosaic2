# Inherited mosaic settings and build-time layer resolution

## Summary

The first inheritance pass made plot-level aesthetics available to mosaic
layers. Several related problems remain:

- `expected`, `divider`, and `offset` must be repeated across sibling mosaic,
  text, and jitter layers;
- repeating `expected` also repeats the loglinear-model fit and permits shaded
  cells and labels to silently use different models;
- mappings added to the plot after a mosaic layer are not inherited because
  the current deferred object resolves mappings in `ggplot_add()`;
- inherited visual aesthetics can unexpectedly add variables to a layer's
  statistical partition;
- the same variable can enter a partition through multiple aesthetics; and
- mosaic constructors return an internal deferred object instead of an
  ordinary ggplot2 layer.

The central design decision is that `expected`, `divider`, and `offset` are
parameters, not aesthetics. They should not be placed in `aes()` or passed
between sibling layers using aesthetic inheritance. Instead, add plot-scoped
mosaic settings and resolve them when the plot is built.

The intended interface is:

```r
ggplot(titanic, aes(x = product(Class, Sex))) +
  mosaic_settings(
    expected = "independence",
    divider = c("vspine", "hspine"),
    offset = 0.005
  ) +
  geom_mosaic() +
  geom_mosaic_text(display_values = "residual") +
  scale_fill_residual()
```

Layer arguments remain available as overrides. For example, an explicit
`expected = NULL` disables the shared model for that layer. Omitted arguments
inherit the plot setting, and explicit layer arguments take precedence.

`mosaic_settings()` should be order independent, so it can be added before or
after the mosaic layers. Resolution must therefore happen during plot building,
not when a layer or setting is added to the plot.

## Issue-to-solution map

| Current issue | Proposed solution |
|---|---|
| Repeated `expected`, `divider`, and `offset` | Plot-level `mosaic_settings()` |
| Duplicate model fitting | A shared per-build mosaic calculation cache |
| `stat_mosaic_text()` lacks `expected` | Add it and use the common calculation path |
| Later `+ aes(...)` changes are ignored | Resolve mappings in a custom layer's `setup_layer()` |
| Constructors are not ordinary layers | Return a genuine ggplot2 `LayerMosaic` immediately |
| Visual aesthetics implicitly alter partitions | Make partition variables explicit |
| One expression enters through multiple aesthetics | Deduplicate equivalent quosures |
| Mismatched overlay parameters are silent | Validate aligned layers during the build |

## Implementation plan

### 1. Replace the deferred `ggmosaic_layer` object

Define an internal `LayerMosaic` ggproto subclass and make `mosaic_layer()` call
`ggplot2::layer(..., layer_class = LayerMosaic)` immediately. Constructors such
as `geom_mosaic()` will then return real ggplot2 layers that external code can
store, inspect, or modify before adding them to a plot.

Implement `LayerMosaic$setup_layer()` so it:

1. invokes or reproduces the ordinary ggplot2 mapping merge, respecting
   `inherit.aes` and layer-over-plot precedence;
2. sees the final plot mapping, including mappings added with a later
   `+ aes(...)` call;
3. passes the effective mapping through `prepare_mosaic_mapping()`;
4. assigns the prepared mapping to the layer's computed mapping;
5. stores the resulting `mosaic_spec` in the stat parameters; and
6. resolves the plot-scoped mosaic settings described below.

ggplot2 3.5.0 already gives custom layer classes a `setup_layer(data, plot)`
hook and accepts a `layer_class` argument in `layer()`. This design should
therefore work without raising the package's current minimum ggplot2 version.
It must nevertheless be tested against both ggplot2 3.5.x and the current
ggplot2 release because the plot representation changed in ggplot2 4.0.0.

Retain the namespace-only product-scale setup currently performed in
`ggplot_add.ggmosaic_layer()`. If necessary, register a small addition method
for `LayerMosaic` that adds the already-constructed layer normally and installs
the private scale environment. This method must not resolve mappings or mosaic
settings.

### 2. Add plot-scoped `mosaic_settings()`

Create an exported plot component that stores shared mosaic computation
settings on the plot. Initially support:

- `divider`;
- `offset`;
- `expected`; and
- possibly `na.rm`, because it also affects the shared calculation.

Keep layer-specific behaviour out of this object. In particular, `seed`,
`drop_level`, `display_values`, text-repulsion options, and fixed visual
aesthetics remain local to their respective layers.

Adding more than one `mosaic_settings()` object should merge explicitly
provided fields, with the last setting winning, like other ggplot2 plot
components.

Layer constructors need to distinguish three cases:

1. the argument was omitted and should inherit a plot setting;
2. no plot setting exists and the package default should be used; and
3. the user explicitly supplied a value, including `expected = NULL`.

Use `missing()` inside the constructors to record an internal inheritance
sentinel without exposing that sentinel in the public API. This preserves the
current formal defaults and lets an explicit `NULL` remain meaningful.

The resolution precedence is:

```text
explicit layer value > plot-level mosaic setting > package default
```

### 3. Centralize and reuse mosaic computation

Extract the shared work in `StatMosaic$compute_panel()` and
`StatMosaicJitter$compute_panel()` into a helper such as
`compute_mosaic_panel()`. The helper should calculate the full, unsubselected
mosaic layout, counts, product scales, and optional expected values and
residuals. Individual stats then perform only their layer-specific final work:

- mosaic selects and decorates the deepest rectangles;
- text calculates cell centres or passes rectangles to `GeomMosaicText`; and
- jitter generates points after the common rectangles have been calculated.

Provide a per-build cache shared by all `LayerMosaic` instances. Cache keys
must include the evaluated structural input for the panel, `mosaic_spec`,
weights, `na.rm`, `divider`, `offset`, and the model specification where
relevant. Fixed drawing aesthetics, text options, and jitter seeds must not
invalidate the shared layout calculation.

The cache must be cleared at the start of every build so rebuilding a modified
plot cannot reuse stale data. A small environment attached to the plot's
mosaic metadata can hold the cache; all layer `setup_layer()` calls occur
before the stats compute, so the setup phase can reset it before computation
begins.

Matching mosaic and text layers will then share geometry, expected counts, and
residuals, and a loglinear model will be fitted only once per matching panel.

### 4. Make the stat and geom interfaces symmetric

Add `expected` to `stat_mosaic_text()` and to
`StatMosaicText$compute_panel()`. Forward it through the shared calculation
path exactly as `StatMosaic` does.

All six public constructors should use the same mechanisms for:

- build-time mapping resolution;
- plot-setting inheritance and layer overrides;
- construction of `mosaic_spec`; and
- access to the per-build calculation cache.

### 5. Separate statistical partitions from visual aesthetics

There is no reliable way to infer whether an inherited `fill`, `alpha`, or
`colour` mapping is intended to style existing cells or introduce another
statistical split. The clean long-term rule is that `product()` and `conds`
define the cells, while visual aesthetics style those cells:

```r
ggplot(
  titanic,
  aes(
    x = product(Survived, Class, Sex),
    fill = Survived
  )
) +
  geom_mosaic() +
  geom_mosaic_text()
```

Under explicit partition semantics, a visual aesthetic mapped to a variable
that is absent from `product()` or `conds` cannot be applied after aggregation.
Produce an actionable error explaining that the variable must be added to
`product()` rather than silently adding a partition level.

Because implicit aesthetic partitioning is established behaviour, introduce
this in stages:

1. add an explicit-partition mode and update package examples to use it;
2. deprecate cases in which an aesthetic alone introduces a partition
   variable; and
3. make explicit partitioning the default in the next breaking release.

The compatibility mode should be isolated in `prepare_mosaic_mapping()` so it
can eventually be removed without changing the stats.

### 6. Deduplicate partition expressions

Update `prepare_mosaic_mapping()` so an expression already represented by
`product()`, `conds`, or an earlier participating aesthetic reuses the same
internal variable. For example, these mappings must refer to one internal
partition field:

```r
aes(
  x = product(Survived, Class),
  fill = Survived,
  colour = Survived
)
```

Compare both the quosure expression and its environment. Expression text alone
is insufficient because identical symbols captured in different environments
can evaluate differently.

### 7. Detect inconsistent overlays

During the shared computation stage, register a structural signature for each
panel. When two mosaic-family layers use the same evaluated structural input
but resolve different alignment parameters, issue a warning that identifies
the differing parameters and layers.

Check at least:

- `divider` and `offset`, which can misalign geometry; and
- `expected` when one layer shades residuals and another displays expected or
  residual values.

Provide a documented escape hatch for deliberately different overlays, but do
not allow accidental mismatches to remain silent by default.

## Regression tests

Add focused tests for the following behaviour:

1. A single `mosaic_settings(expected = "independence")` supplies both a
   mosaic layer and a residual-text layer.
2. The shaded cells and labels contain identical expected values and residuals.
3. The shared loglinear model is fitted once per matching panel rather than
   once per layer.
4. Shared non-default `divider` and `offset` values align mosaic, text, and
   jitter layers exactly.
5. An explicit layer argument overrides the plot setting.
6. Explicit `expected = NULL` disables an inherited model for one layer.
7. Multiple `mosaic_settings()` calls merge correctly and the last explicit
   value wins.
8. Settings work regardless of whether they appear before or after the layers.
9. A mapping supplied by a later `+ aes(...)` call reaches every inheriting
   mosaic layer.
10. `inherit.aes = FALSE` continues to isolate a layer.
11. Every geom and stat constructor returns an object inheriting from ggplot2's
    `Layer` before it is added to a plot.
12. `stat_mosaic_text(expected = ...)` exposes expected values and residuals.
13. Explicit partition semantics prevent inherited styling aesthetics from
    changing the number of cells.
14. A styling variable missing from `product()` produces an actionable error
    in explicit mode.
15. Compatibility mode preserves existing implicit-partition examples during
    the deprecation period.
16. Repeated `fill`/`colour`/`alpha` expressions reuse one internal partition
    variable.
17. Deliberately or accidentally inconsistent overlay settings produce the
    documented warning or escape-hatch behaviour.
18. Faceting does not mix cached calculations between panels.
19. Rebuilding a plot after changing its data or settings does not reuse stale
    cached results.
20. Namespace-only calls, product scales, transformed quosures, formula model
    translation, residual outlines, coordinate flipping, and existing axis
    metadata continue to work.

Run the package's existing script-based regression suite as well as checks
against the minimum and current supported ggplot2 versions.

## Documentation and migration

Document `mosaic_settings()` alongside the mosaic geoms and stats. Replace
examples that repeat `expected`, `divider`, or `offset` across layers with a
single plot-scoped setting.

Explain the distinction between:

- data mappings in `aes()`;
- structural mosaic variables in `product()` and `conds`;
- plot-scoped mosaic computation settings; and
- layer-local drawing or display parameters.

Add a lifecycle note for implicit aesthetic partitioning and a migration
example showing how to move the aesthetic variable into `product()`.

## Suggested delivery sequence

Implement this work as three focused changes:

1. **Layer lifecycle:** introduce `LayerMosaic`, resolve mappings during the
   build, preserve namespace-only scale discovery, and return ordinary layers.
2. **Shared settings and computation:** add `mosaic_settings()`, stat/geom
   symmetry, caching, and mismatch validation.
3. **Partition semantics:** add explicit partitioning, quosure deduplication,
   deprecation handling, and migration documentation.

This sequence separates the internal lifecycle correction from the new
plot-level API and from the potentially breaking partition-semantics change.

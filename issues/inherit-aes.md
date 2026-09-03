# Current potential issues

## Problem

For some situations we want to allow to construct the `geom_mosaic()` display based on `area ~ expected` frequencies under
a loglinear model as an alternative to the standard display based on  `area ~ observed`.
But if we also want to display values in the cells, using `geom_mosaic_text()`, the `expected`
argument must be passed to both calls.

## `expected` is not shared between layers

Layer parameters are not inherited between sibling ggplot2 layers. To label
residuals or expected values, the same `expected` argument must therefore be
supplied to both `geom_mosaic()` and `geom_mosaic_text()`:

```r
ggplot(titanic, aes(x = product(Class, Sex))) +
  geom_mosaic(expected = "independence") +
  geom_mosaic_text(
    expected = "independence",
    display_values = "residual"
  ) +
  scale_fill_residual()
```

This duplicates both the user specification and the loglinear-model fitting.
If the arguments differ, the shaded cells and their labels can silently be
based on different models. The direct `stat_mosaic_text()` interface also does
not currently support `expected`, so this capability is asymmetric between the
geom and stat interfaces.

## Other layout parameters must also be repeated

Non-default `divider` and `offset` values must be kept in sync across mosaic,
text, and jitter layers. These are parameters rather than aesthetics, so the
new inheritance mechanism does not share them. Inconsistent values can produce
misaligned overlays without an explicit error.

## Plot mappings are resolved when a layer is added

The deferred mosaic object resolves the plot and layer mappings in
`ggplot_add()`, then constructs an ordinary layer with `inherit.aes = FALSE`.
Consequently, a mapping added or replaced after the mosaic layer has already
been added does not propagate back into that layer:

```r
# The mapping arrives too late for geom_mosaic().
ggplot(hair_freq) +
  geom_mosaic() +
  aes(weight = Freq, x = product(Hair, Eye), fill = Hair)
```

This differs from ordinary ggplot2 layers, which inherit the final plot
mapping at build time.

## Inherited aesthetics can change the mosaic partition

For mosaic layers, `fill`, `alpha`, and jitter `colour` can participate in the
statistical partition rather than acting only as visual styling. Inheriting an
aesthetic into a sibling layer can therefore change its computed cells. For
example, allowing `geom_mosaic_text()` to inherit `fill = Survived` can produce
one text cell per survival category where the intended text layer has one cell
per `Class`/`Sex` combination. Label fills and legends can also change.

Shared layout aesthetics can be declared globally, but genuinely
layer-specific partition or styling aesthetics should remain local.

## One variable can enter the partition more than once

If a jitter layer receives the same variable through multiple participating
aesthetics, such as both `fill = Survived` and `colour = Survived`, the current
preparation code records both as separate mosaic margin fields. The resulting
specification contains the same conceptual variable twice and can introduce a
redundant partition level. The preparation step could potentially deduplicate
identical aesthetic expressions.

## Constructors return a deferred object before plot addition

`geom_mosaic()`, `geom_mosaic_text()`, and `geom_mosaic_jitter()` now return an
internal `ggmosaic_layer` object rather than an ordinary ggplot2 `Layer` until
they are added to a plot. Normal `ggplot(...) + geom_mosaic()` use works, and
the stored layer in the completed plot is an ordinary layer. However, external
code that stores, inspects, or modifies the constructor result before adding
it may not be compatible with the deferred object.

# Plan (DONE)

## Make global aesthetics work for mosaic layers

### Summary

Mosaic layers do not currently support aesthetics declared globally in
`ggplot()`. This prevents the usual ggplot2 composition style when several
mosaic layers share the same variables:

```r
hair_freq <- as.data.frame(HairEyeColor)

ggplot(
  data = hair_freq,
  aes(
    weight = Freq,
    x = product(Hair, Eye),
    fill = Hair
  )
) +
  geom_mosaic(alpha = 0.1) +
  geom_mosaic_jitter(size = 2, alpha = 0.8)
```

Against the current source, this produces four warnings and zero computed rows
in both layers. Repeating the mappings inside the two layers works, producing
16 mosaic cells and 592 jittered points without warnings.

The goal is for the global form above to behave like its explicit-layer
equivalent while preserving normal ggplot2 precedence and an
`inherit.aes = FALSE` escape hatch.

### Current behaviour and diagnosis

The public `inherit.aes` argument is ignored by the geom wrappers.
`geom_mosaic()`, `geom_mosaic_text()`, and `geom_mosaic_jitter()` all accept the
argument but construct their ggplot2 layer with `inherit.aes = FALSE`
unconditionally.

The corresponding stat wrappers pass `inherit.aes` to `layer()`, but inherited
mosaic mappings still do not work. The underlying problem is the timing of
`prepare_mosaic_mapping()`.

Mosaic mappings need special preprocessing before the stat runs:

- `product()` and `conds` expressions are replaced by safe internal columns;
- mapped partition aesthetics such as `fill`, `alpha`, and jitter `colour` are
  incorporated into `mosaic_spec`;
- product formulas, readable labels, axis-variable metadata, and
  aesthetic-variable metadata are recorded.

This preprocessing currently occurs inside each geom or stat constructor and
therefore sees only the mapping supplied directly to that layer. ggplot2 merges
the plot mapping into the layer mapping later. Merely forwarding
`inherit.aes = TRUE` would allow the raw inherited mapping to bypass
`prepare_mosaic_mapping()`, while `mosaic_spec` would still describe only the
direct layer mapping.

### API decision

Use `inherit.aes = TRUE` as the default for all exported mosaic geoms and
stats. This is required for the global example above to work without extra
arguments and follows normal ggplot2 layer behaviour.

A layer mapping overrides the corresponding plot mapping. Users can set
`inherit.aes = FALSE` when a mosaic layer must be isolated from plot-level
aesthetics.

This change applies only to aesthetics. Layer parameters such as `divider`,
`offset`, `expected`, `drop_level`, and `seed` are not inherited from another
layer and must still be supplied to each layer that needs them.

### Implementation plan

#### 1. Introduce a deferred mosaic-layer specification

Create a small internal object that stores the information needed to construct
a mosaic layer:

- the unprocessed layer mapping;
- the value of `inherit.aes`;
- the aesthetics that participate in the mosaic calculation (`fill` and
  `alpha`, plus `colour` for jitter);
- the ordinary arguments for `ggplot2::layer()`;
- the stat or geom parameters that will receive `mosaic_spec`.

All six exported constructors should use this mechanism:

- `geom_mosaic()` and `stat_mosaic()`;
- `geom_mosaic_text()` and `stat_mosaic_text()`;
- `geom_mosaic_jitter()` and `stat_mosaic_jitter()`.

Deferring construction is necessary because a constructor receives the layer
mapping but not the plot mapping.

#### 2. Resolve aesthetic inheritance in `ggplot_add()`

Extend the existing custom `ggplot_add()` mechanism in `R/utilities.R`. When a
deferred mosaic layer is added to a plot:

1. If `inherit.aes = TRUE`, combine the layer mapping with `plot$mapping` using
   ggplot2 precedence: values supplied by the layer win, and missing layer
   aesthetics come from the plot.
2. If `inherit.aes = FALSE`, use only the layer mapping.
3. Pass the resulting effective mapping through `prepare_mosaic_mapping()`
   exactly once.
4. Add the resulting `mosaic_spec` to the stat parameters.
5. Construct the internal ggplot2 layer with `inherit.aes = FALSE`, because
   inheritance has already been resolved explicitly.
6. Add that internal layer to the plot.

The mapping merge should preserve the quosure environments already carried by
the plot and layer mappings, so unquoted variables, transformations, and
namespace-qualified `product()` calls continue to evaluate in their original
environments.

#### 3. Preserve namespace-only scale discovery

Retain the behaviour currently provided by
`add_mosaic_scale_environment()`/`ggplot_add.ggmosaic_namespace_layer()`. Calls
such as `ggmosaic2::geom_mosaic()` must continue to install the product scale
constructors in the plot environment without attaching the package.

The deferred layer and namespace-only handling should be consolidated into one
addition path if possible, rather than nesting two custom wrapper objects.

#### 4. Update the six public constructors

Change each constructor so it:

- defaults to `inherit.aes = TRUE`;
- does not call `prepare_mosaic_mapping()` immediately;
- does not construct the final ggplot2 layer immediately;
- records the correct partition aesthetics for later preparation;
- retains its current data, stat, geom, position, legend, and parameter
  behaviour.

After the deferred layer has been resolved, the existing `StatMosaic`,
`StatMosaicText`, `StatMosaicJitter`, and geom implementations should not need
to know whether a mapping originally came from the plot or the layer.

#### 5. Add focused regression tests

Add `tests/inherit-aes.R`, following the repository's existing script-based
test style.

Cover the following cases:

1. The exact global `HairEyeColor` example builds without warnings, producing
   16 mosaic cells and 592 jittered points.
2. Global and explicit-layer versions produce equivalent rectangle geometry,
   cell frequencies, mapped aesthetics, and seeded jitter coordinates.
3. Paired `geom_mosaic()` and `geom_mosaic_text()` layers using a shared global
   mapping calculate identical cell geometry and frequencies.
4. Plot-level `weight`, `fill`, `alpha`, and `conds` are represented correctly
   in `mosaic_spec` and the computed data.
5. Transformed expressions such as `product(factor(cyl))`, transformed
   `conds`, and `fill = factor(flag)` retain safe internal names and readable
   labels.
6. A layer mapping overrides the corresponding plot mapping.
7. `inherit.aes = FALSE` isolates a layer from plot-level aesthetics.
8. Existing explicit layer mappings retain their current behaviour.
9. All three geom interfaces and all three stat interfaces use the same
   inheritance rules.
10. Faceting, product-axis metadata, residual calculations, custom divider
    vectors, and namespace-only use remain unchanged.

Existing regression scripts should also be run to catch changes in computed
aesthetics, product-axis filtering, faceting, spacing, residual shading, and
namespace-only operation.

#### 6. Update generated function documentation

Update the roxygen examples and parameter documentation for the mosaic layer
constructors so they describe the functional `inherit.aes` argument and show a
shared plot-level mapping across multiple mosaic layers. Regenerate the
corresponding `.Rd` files and the registered S3 method for the deferred-layer
class.

#### 7. Validate the completed change

Before considering the issue complete:

1. Run all scripts under `tests/`.
2. Regenerate documentation and confirm that the namespace contains the new
   `ggplot_add()` registration.
3. Run `R CMD check`.
4. Build the global and explicit versions of the `HairEyeColor` example and
   compare their computed layer data.
5. Confirm that neither form emits warnings.

### Acceptance criteria

- The posted global-aesthetic example works unchanged.
- No exported mosaic layer exposes an `inherit.aes` argument that it ignores.
- All inherited mosaic aesthetics are preprocessed before the stat computes
  the product layout.
- Direct layer mappings override inherited mappings in the usual ggplot2 way.
- `inherit.aes = FALSE` preserves layer-local isolation.
- Paired mosaic, text, and jitter layers sharing a global mapping calculate
  compatible geometry and frequencies.
- Computed and transformed aesthetics retain safe internal names and readable
  labels.
- Namespace-only calls continue to discover the product scales.
- Existing explicit-mapping code remains functional.

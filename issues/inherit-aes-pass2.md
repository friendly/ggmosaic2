# `mosaic_settings()` and build-time mapping resolution

## Status

This is the revised implementation plan for plot-scoped mosaic settings. The
first implementation should prioritize compatibility and correctness. It must
not combine the new public API with computation caching, alignment warnings, or
changes to the historical partition semantics of mapped aesthetics.

Implementation status (2026-09-02): changes 1 and 2 below are implemented,
documented, and covered by the package regression suite. Changes 3 and 4 remain
optional future work; the partition-semantics and overlay-diagnostics project
remains explicitly out of scope.

The work is divided into small stages with a compatibility gate after each
stage. A stage should not proceed until the package's existing checks and the
new focused regression tests pass under both the minimum and current supported
ggplot2 releases.

## Problems being solved

The current inheritance work resolves a mosaic layer when it is added to a
plot. This made plot-level mappings available to mosaic layers, but it remains
too early in the ggplot2 lifecycle:

- a mapping added with a later `+ aes(...)` is not inherited by an existing
  mosaic layer;
- `expected`, `divider`, and `offset` must be repeated across sibling mosaic,
  text, and jitter layers;
- repeated values can silently disagree; and
- mosaic constructors return an internal deferred `ggmosaic_layer` object
  rather than an ordinary ggplot2 `Layer`.

The first problem is independent of `mosaic_settings()`. With
`inherit.aes = TRUE`, a mosaic layer should see the final plot mapping at build
time, just like an ordinary ggplot2 layer:

```r
ggplot(titanic) +
  geom_mosaic() +
  aes(x = product(Class, Sex), fill = Survived)
```

The shared-parameter problem should be addressed with a plot-local component:

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

`expected`, `divider`, and `offset` are computation parameters, not
aesthetics. They should not be placed in `aes()` or transferred between layers
through aesthetic inheritance.

## Compatibility invariants

The following are release requirements, not optional goals:

1. A plot that does not use `mosaic_settings()` must retain its current data,
   geometry, scales, labels, residuals, legends, warnings, and errors.
2. Current implicit partition behavior must remain unchanged. Mapped `fill`
   and `alpha`, and mapped `colour` in jitter layers, continue to participate
   in the mosaic partition exactly as they do now.
3. Fixed aesthetics supplied outside `aes()` remain layer-local drawing
   parameters and never become partitions.
4. Direct layer mappings override plot mappings, and `inherit.aes = FALSE`
   continues to isolate the layer.
5. A later `+ aes(...)` reaches every earlier mosaic layer for which
   `inherit.aes = TRUE`.
6. Explicit layer arguments override plot settings. An explicit
   `expected = NULL` remains distinct from an omitted `expected` argument.
7. Reusing one layer in multiple derived plots must not allow the first build
   to contaminate later builds.
8. Rebuilding a plot after changing its data, mapping, or settings must not
   reuse resolved state from an earlier build.
9. Namespace-only use through `ggmosaic2::geom_mosaic()` must continue to
   install the product-scale constructors privately without attaching the
   package.
10. The implementation must work with ggplot2 3.5.x and ggplot2 4.x.

## Scope of the first release

The first `mosaic_settings()` release supports exactly:

- `divider` for mosaic, text, and jitter layers;
- `offset` for mosaic, text, and jitter layers; and
- `expected` for mosaic and text layers.

`expected` does not apply to jitter layers. A jitter layer may share the same
layout settings, but it must not fit a loglinear model merely because the plot
has an `expected` setting.

Do not include `na.rm` initially. It is an established layer parameter, and it
is not necessary to establish the public settings API. It can be considered
later if a concrete multi-layer consistency problem justifies it.

The following work is explicitly out of scope:

- computation caching or model-fit reuse;
- automatic warnings about mismatched overlays;
- changes to implicit aesthetic partitioning;
- deduplication changes in `prepare_mosaic_mapping()`; and
- a deprecation of aesthetic-only partitions.

Those items require independent designs and compatibility reviews.

## Public semantics

### Resolution precedence

For every applicable setting, resolve values in this order:

```text
explicit layer argument > explicit plot setting > existing package default
```

Examples:

```r
# Both layers inherit the plot setting.
ggplot(titanic, aes(x = product(Class, Sex))) +
  mosaic_settings(offset = 0.02) +
  geom_mosaic() +
  geom_mosaic_text()

# The text layer overrides the plot setting.
ggplot(titanic, aes(x = product(Class, Sex))) +
  mosaic_settings(offset = 0.02) +
  geom_mosaic() +
  geom_mosaic_text(offset = 0.005)

# The text layer explicitly disables the inherited model.
ggplot(titanic, aes(x = product(Class, Sex))) +
  mosaic_settings(expected = "independence") +
  geom_mosaic() +
  geom_mosaic_text(expected = NULL)
```

### Order independence

Settings must be resolved during the build, so these expressions are
equivalent:

```r
p + mosaic_settings(offset = 0.02) + geom_mosaic()
p + geom_mosaic() + mosaic_settings(offset = 0.02)
```

### Repeated settings

Multiple settings components merge only the fields explicitly supplied by the
new component. The last explicit value wins:

```r
p + mosaic_settings(offset = 0.02, expected = "independence") +
  mosaic_settings(offset = 0.01)
```

The result retains `expected = "independence"` and uses `offset = 0.01`.

An explicit `NULL` is a supplied value, not an omitted field:

```r
p + mosaic_settings(expected = "independence") +
  mosaic_settings(expected = NULL)
```

The result has `expected = NULL`. The internal representation must therefore
store field presence separately from value truthiness; assigning with
`settings["expected"] <- list(NULL)` preserves the field, while
`settings$expected <- NULL` would delete it.

### Validation

Validate everything that can be validated without knowing the final mapping
when `mosaic_settings()` is constructed:

- `offset` must be one finite, non-negative number;
- `expected` must be `NULL`, a formula, or one supported character shortcut;
- `divider` must be a divider function, a supported character value/vector,
  or another form already accepted by the layer constructors.

Do not make the new plot-level validator narrower than the existing layer
interface. Audit the divider forms accepted by `prodcalc()`/`divide()` and
share that validation where practical so moving an existing valid value from a
layer into `mosaic_settings()` does not reject it.

Validation that depends on the number of resolved partition variables remains
a build-time check. Preserve formula and quosure environments; do not convert
formulas or mappings to text and reconstruct them in another environment.

## Internal design

### 1. Add a real `LayerMosaic`

Define an internal `LayerMosaic` ggproto subclass of ggplot2's internal
`Layer`. Construct it through:

```r
ggplot2::layer(..., layer_class = LayerMosaic)
```

ggplot2 3.5.0 contains both `setup_layer(data, plot)` and the `layer_class`
argument, although `layer_class` is documented as internal. Obtain the parent
class through one small compatibility helper rather than scattering
`ggplot2:::` references through the package.

`mosaic_layer()` should immediately return the resulting `LayerMosaic`. It
must preserve the current layer arguments, including `check.aes = FALSE`,
because the prepared mapping contains internal mosaic aesthetics that ordinary
layer validation does not know about.

Store only stable constructor information on the layer:

- the set of participating mosaic aesthetics (`fill`/`alpha`, plus `colour`
  for jitter);
- the existing package defaults for applicable shared settings; and
- omitted-versus-explicit state for each applicable setting.

Do not store a resolved plot setting as if it were an explicit layer value.

### 2. Resolve the final mapping in `setup_layer()`

`LayerMosaic$setup_layer()` must first call the parent `Layer$setup_layer()`.
Do not reproduce ggplot2's mapping merge. Calling the parent preserves
version-specific ggplot2 behavior such as mapping classes, layer-over-plot
precedence, `inherit.aes`, and aesthetic compatibility handling.

The super call must name the actual parent `Layer` object in
`ggproto_parent(parent_layer, self)`, not `LayerMosaic`; using the subclass as
the parent recurses back into `LayerMosaic$setup_layer()`.

After the parent has populated `self$computed_mapping`:

1. pass `self$computed_mapping` to `prepare_mosaic_mapping()`;
2. replace `self$computed_mapping` with the prepared mapping;
3. retain the prepared `mosaic_spec` as build-resolved layer state; and
4. resolve applicable mosaic settings from the final plot metadata.

Only `computed_mapping` is rewritten. Keep the original layer `mapping`
unchanged so the same layer can be built again against a different plot
mapping.

`prepare_mosaic_mapping()` itself must not change in this stage. In
particular, preserve the current implicit partition behavior and its current
deduplication rules.

### 3. Represent omitted layer arguments with a private sentinel

Each public constructor must call `missing()` before forcing a shared
argument. When an argument was omitted, pass a private inheritance sentinel
through the layer's applicable stat parameter. When it was explicitly
supplied, preserve the supplied value, including `NULL`.

Keeping the sentinel in `stat_params` has an additional compatibility benefit:
if a user stores a returned layer and explicitly modifies, for example,
`layer$stat_params$offset`, that replacement naturally becomes an explicit
override.

The sentinel must never reach a Stat computation. Immediately before the
parent layer computes the statistic, create a resolved copy of `stat_params`
in which every sentinel is replaced according to the precedence rule.

### 4. Do not make resolved state sticky

ggproto layers are mutable and ggplot2 plots can share layer instances. This
common pattern must be safe:

```r
layer <- geom_mosaic()
base <- ggplot(titanic, aes(x = product(Class, Sex))) + layer

p1 <- base + mosaic_settings(offset = 0.01)
p2 <- base + mosaic_settings(offset = 0.05)
```

Building `p1` must not change `p2`, and the result must not depend on build
order.

To preserve ggplot2's version-specific statistic lifecycle, do not copy the
body of `Layer$compute_statistic()`. Override
`LayerMosaic$compute_statistic()` narrowly:

1. make a local resolved copy of `self$stat_params`;
2. add the build's `mosaic_spec` only when the selected Stat accepts that
   parameter;
3. temporarily expose the resolved copy to the parent
   `compute_statistic()`;
4. call the parent method; and
5. restore the original unresolved `stat_params` with `on.exit()`.

As in `setup_layer()`, call `ggproto_parent(parent_layer, self)` with the
actual parent object so the override cannot recurse into itself.

This retains the inheritance sentinels and explicit constructor values for
the next build while delegating setup, computation, attribute handling, and
future ggplot2 changes to the parent implementation.

Do not add `mosaic_spec` blindly to an arbitrary custom Stat. Preserve the
current parameter-routing behavior by checking the selected Stat's accepted
parameters.

### 5. Store settings as immutable plot metadata

`mosaic_settings()` returns a small S3 plot component containing only its
explicitly supplied values. Its addition method merges those values into one
namespaced plot field, for example `plot$ggmosaic2_settings`.

Use the public `$` plot interface rather than directly manipulating ggplot2
4.x S7 slots. In ggplot2 3.5.x this is an ordinary list field; in ggplot2 4.x
custom `$` fields are stored in plot metadata.

The plot metadata must contain ordinary immutable lists and values only. Do
not attach a cache environment or other mutable build state to it.

### 6. Preserve ordinary layer addition and namespace-only scales

Register `ggplot_add.LayerMosaic()`. It should:

1. delegate normal layer insertion through the next ggplot2 addition method;
2. install `scale_x_productlist` and `scale_y_productlist` privately in the
   plot environment if necessary; and
3. return the otherwise intact plot.

It must not merge mappings, call `prepare_mosaic_mapping()`, or resolve mosaic
settings. Those operations belong to the build lifecycle.

Delegating through the next method is important across supported versions:
ggplot2 3.5.x has an S3 `ggplot_add.Layer` method, while ggplot2 4.x routes the
default addition path through `update_ggplot()`.

### 7. Make the text-stat interface symmetric

Add `expected` to `stat_mosaic_text()` and to
`StatMosaicText$compute_panel()`. Pass it to `StatMosaic$compute_panel()`.

The applicable settings matrix is:

| Constructor | `divider` | `offset` | `expected` |
|---|---:|---:|---:|
| `geom_mosaic()` | yes | yes | yes |
| `stat_mosaic()` | yes | yes | yes |
| `geom_mosaic_text()` | yes | yes | yes |
| `stat_mosaic_text()` | yes | yes | yes |
| `geom_mosaic_jitter()` | yes | yes | no |
| `stat_mosaic_jitter()` | yes | yes | no |

A plot-level `expected` value is ignored by jitter layers rather than forwarded
as an unknown parameter or used to perform an unnecessary model fit.

## Regression tests required before merge

### Layer lifecycle and aesthetic inheritance

1. Every geom and stat constructor returns an object inheriting from ggplot2's
   `Layer` before it is added to a plot.
2. A mapping supplied by a later `+ aes(...)` reaches all earlier inheriting
   mosaic, text, and jitter layers.
3. Direct layer mappings override the final plot mapping.
4. `inherit.aes = FALSE` isolates the layer from both earlier and later plot
   mappings.
5. Original layer mappings remain unchanged after one or more builds.
6. Namespace-only calls still install and use both product scales without
   attaching ggmosaic2.

### Settings semantics

7. One `mosaic_settings(expected = "independence")` supplies matching mosaic
   and residual-text layers.
8. Shared non-default `divider` and `offset` values align mosaic, text, and
   jitter geometry.
9. An explicit layer argument overrides a plot setting.
10. Explicit layer `expected = NULL` disables an inherited model.
11. Multiple settings objects merge only explicitly supplied fields, with the
    last supplied field winning.
12. An explicit `mosaic_settings(expected = NULL)` clears a previously supplied
    plot value.
13. Settings work before or after layers and when supplied to a base plot that
    is later extended.
14. Adding settings to a plot with no mosaic layers is harmless.
15. Jitter layers ignore a plot-level `expected` setting without warning or
    model fitting.

### Build isolation

16. Two plots derived from one base plot can use different settings; building
    them in either order produces their own expected results.
17. One stored `LayerMosaic` can be reused in plots with different mappings,
    data, and settings without contamination.
18. Rebuilding after changing plot data, mapping, or settings recomputes the
    mapping specification and resolved parameters.
19. A failed build does not leave resolved settings in the layer's original
    `stat_params`.
20. Explicit modification of a returned layer's applicable `stat_params`
    behaves as an explicit override.

### Legacy equivalence

21. When no settings component is present, representative plots produce the
    same built data as before the `LayerMosaic` conversion. Cover unweighted
    and weighted data, conditioning, transformed quosures, faceting, custom
    divider vectors, offset, jitter with `weight2`, and text.
22. Existing residual shading, formula translation, outlines, legends, and
    manual fill behavior remain unchanged.
23. Current implicit `fill`/`alpha` partitions and jitter `colour` partitions
    retain their existing cell counts, ordering, labels, and axis behavior.
24. Existing deliberate differences between sibling layers do not emit new
    warnings.
25. Coordinate flipping, facet-specific product axes, and namespace-only scale
    discovery continue to work.

Run every existing script in `tests/` in addition to these focused tests.

## Version and CI matrix

The current CI matrix varies R versions but does not pin the minimum ggplot2
dependency. Add a dedicated compatibility job that installs ggplot2 3.5.x, in
addition to jobs using the current ggplot2 release.

At minimum, test:

- ggplot2 3.5.0 or the latest 3.5.x patch release;
- the current ggplot2 4.x release;
- R release on Linux, macOS, and Windows through the existing matrix; and
- R CMD check plus the script-based regression suite.

The custom layer work relies on internal ggplot2 infrastructure. A pinned
minimum-version job is therefore a merge requirement, not a later cleanup.

## Delivery sequence

### Change 1: lifecycle only

- Introduce `LayerMosaic`.
- Return a real layer from all six constructors.
- Resolve the final mapping in the parent-aware `setup_layer()`.
- Preserve namespace-only product-scale installation.
- Do not add `mosaic_settings()` yet.
- Require legacy-equivalence and later-`aes()` tests to pass.

This change should alter only the observable constructor class and fix the
known late-mapping bug. Existing plots should otherwise build identically.

### Change 2: settings without computation refactoring

- Add and export `mosaic_settings()`.
- Add validation, merging, sentinels, and precedence resolution.
- Add `expected` to `stat_mosaic_text()`.
- Keep each layer's current independent computation.
- Do not add caching or mismatch warnings.

This establishes the public API and makes its behavior testable without
changing the underlying mosaic calculation.

### Change 3: optional common computation refactor

Only after changes 1 and 2 have shipped or passed a separate compatibility
review, extract a pure helper such as `compute_mosaic_panel()` from the current
stats. First demonstrate output equivalence without caching.

The current mosaic and jitter paths are not identical: jitter retains all
layout levels, supports `weight2`, applies `drop_level`, and generates random
points, while mosaic layers select and decorate deepest rectangles. The helper
boundary must preserve those distinctions.

### Change 4: optional build-scoped cache

Consider caching only after the common helper is stable. Do not store the cache
in plot metadata. A suitable owner is a fresh build object such as the build's
`Layout`, made available through `LayerMosaic$compute_statistic()`.

Cache keys must account for evaluated panel data, structural variables,
weights, conditioning, missing-value handling, divider, offset, model
specification, and every other input that affects the shared result. Formula
and function environments need identity-safe handling. A cache miss must
always fall back to an independent correct computation.

### Future project: partition semantics and overlay diagnostics

The following ideas remain worthwhile but are not part of implementing
`mosaic_settings()`:

- making `product()` and `conds` the only sources of partitions;
- treating mapped visual aesthetics strictly as styling;
- deduplicating expressions across `product()`, `conds`, and multiple
  aesthetics using both expression and quosure environment;
- deprecating historical aesthetic-only partitions; and
- warning about potentially inconsistent overlays.

Changing partition semantics affects cell counts and is a breaking change.
Automatic overlay warnings can also break warning-sensitive code and cannot
reliably distinguish an accidental mismatch from a deliberate overlay. These
features need their own public design, lifecycle policy, and release plan.

## Documentation

Document `mosaic_settings()` alongside the mosaic geoms and stats. Explain the
four distinct concepts:

- mappings in `aes()`;
- structural mosaic variables and the package's current implicit partition
  behavior;
- plot-scoped mosaic computation settings; and
- layer-local display, drawing, and jitter parameters.

Update repeated-parameter examples only after equivalence tests pass. Include
examples of layer overrides and explicit `expected = NULL`. Add a NEWS entry
for the new public component, the ordinary-layer return value, and the fix for
later-added plot mappings.

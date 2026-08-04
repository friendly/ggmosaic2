# Make `inherit.aes` work for mosaic layers

## Summary

The public `inherit.aes` argument on the mosaic geom wrappers is currently
ignored. `geom_mosaic()`, `geom_mosaic_text()`, and `geom_mosaic_jitter()` all
accept the argument but construct their ggplot2 layer with
`inherit.aes = FALSE` unconditionally.

The corresponding stat wrappers pass `inherit.aes` to `layer()`, but inherited
mosaic mappings are still not processed correctly. In practice, users must put
the mosaic aesthetics directly in each layer even when those aesthetics were
already supplied to `ggplot()`.

This is both an API bug (an exposed argument has no effect) and an unnecessary
departure from normal ggplot2 composition.

## Reproduction

The explicit-layer form works:

```r
ggplot(titanic) +
  geom_mosaic(aes(x = product(Class, Sex))) +
  geom_mosaic_text(aes(x = product(Class, Sex)))
```

The equivalent inherited form does not:

```r
ggplot(titanic, aes(x = product(Class, Sex))) +
  geom_mosaic(inherit.aes = TRUE) +
  geom_mosaic_text(inherit.aes = TRUE)
```

On the current branch, building an inherited geom layer produces warnings from
the failed mosaic computation and returns no computed rows. Explicitly setting
`inherit.aes = TRUE` makes no difference because the value is never passed to
`layer()`.

The problem also affects weights and other mosaic aesthetics:

```r
ggplot(as.data.frame(Titanic),
       aes(x = product(Class, Sex), weight = Freq)) +
  geom_mosaic(inherit.aes = TRUE) +
  geom_mosaic_text(inherit.aes = TRUE,
                   display_values = "observed",
                   format_digits = 0)
```

Users currently have to repeat `x`, `weight`, `fill`, `alpha`, and `conds` as
applicable in each mosaic layer. Layer parameters such as `divider`, `offset`,
and `expected` are not aesthetics and would still need to be coordinated
between layers after aesthetic inheritance is fixed.

## Diagnosis

The geom wrappers contain code equivalent to:

```r
geom_mosaic_text <- function(..., inherit.aes = FALSE) {
  # ...
  ggplot2::layer(
    # ...
    inherit.aes = FALSE
  )
}
```

Consequently, the public argument is a no-op.

Changing that line to `inherit.aes = inherit.aes` is necessary but not a
complete fix. Mosaic mappings receive special preprocessing in
`prepare_mosaic_mapping()`:

- `product()` and `conds` expressions are replaced by safe internal columns;
- mapped partition aesthetics such as `fill` and `alpha` are incorporated into
  `mosaic_spec`;
- the product formula, readable variable labels, axis-variable metadata, and
  aesthetic-variable metadata are recorded before the stat runs.

At present, this preprocessing happens inside the geom/stat constructor and
therefore sees only the mapping supplied directly to that layer. ggplot2 does
not merge the plot mapping into the layer mapping until later. If inheritance
is merely enabled on `layer()`, the inherited mapping bypasses
`prepare_mosaic_mapping()`, while `mosaic_spec` still describes only the direct
layer mapping. The stat then lacks the metadata needed to calculate the mosaic.

This explains why the stat wrappers are also affected even though they pass
their `inherit.aes` argument through to `layer()`.

## Recommended implementation

1. Defer construction of a mosaic layer until `ggplot_add()`, where both the
   plot mapping and the layer mapping are available.
2. When `inherit.aes = TRUE`, combine the mappings using ggplot2-compatible
   precedence: a layer aesthetic overrides the same plot aesthetic.
3. Pass the combined mapping through `prepare_mosaic_mapping()` exactly once.
4. Construct the internal ggplot2 layer using the transformed mapping and
   `inherit.aes = FALSE`; inheritance has already been resolved explicitly at
   that point.
5. Preserve the existing plot-environment setup performed by
   `add_mosaic_scale_environment()` so namespace-only use continues to find the
   product scales.
6. Apply the same mechanism consistently to:
   - `geom_mosaic()` / `stat_mosaic()`;
   - `geom_mosaic_text()` / `stat_mosaic_text()`;
   - `geom_mosaic_jitter()` / `stat_mosaic_jitter()`.
7. Initially retain `inherit.aes = FALSE` as the geom default for backward
   compatibility, but make an explicit `TRUE` fully functional. A later release
   can separately consider changing the default to ggplot2's conventional
   `TRUE`.

If full inheritance is not implemented, the minimum honest alternative is to
remove `inherit.aes` from the geom APIs and document that mosaic mappings must
be layer-local. That would eliminate the misleading no-op but would not improve
composition and would leave the stat interfaces inconsistent.

## Regression tests

Add focused tests covering all of the following:

1. A plot-level `x = product(...)` mapping works for `geom_mosaic()` when
   `inherit.aes = TRUE`.
2. The same plot-level mapping produces aligned rectangles and cell centres in
   paired `geom_mosaic()` and `geom_mosaic_text()` layers.
3. Plot-level `weight`, `fill`, `alpha`, and `conds` mappings are inherited and
   represented correctly in `mosaic_spec` and the computed data.
4. Transformed expressions such as `product(factor(cyl))` and
   `fill = factor(flag)` retain safe internal names and readable labels.
5. A layer mapping overrides the corresponding plot mapping.
6. `inherit.aes = FALSE` continues to isolate a layer from plot-level
   aesthetics.
7. Explicit layer mappings retain their current behaviour when inheritance is
   disabled or absent.
8. The stat and jitter interfaces behave consistently with the two primary
   geoms.
9. Faceting, product-axis metadata, residual calculations, namespace-only use,
   and custom divider vectors remain unchanged.

## Acceptance criteria

- No exported mosaic layer exposes an `inherit.aes` argument that it ignores.
- With `inherit.aes = TRUE`, all inherited mosaic aesthetics are preprocessed
  before the stat computes the product layout.
- Direct layer mappings override inherited mappings in the usual ggplot2 way.
- `inherit.aes = FALSE` preserves the current layer-local behaviour.
- Paired mosaic and text layers using the same inherited mapping calculate
  identical cell geometry and frequencies.
- Existing explicit-mapping code remains backward compatible.

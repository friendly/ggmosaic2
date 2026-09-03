# Documentation changes for `mosaic_settings()`

## Scope

`mosaic_settings()` adds plot-scoped defaults for three existing layer
arguments:

| setting | inherited by |
|---|---|
| `divider` | `geom_mosaic()`, `stat_mosaic()`, `geom_mosaic_text()`, `stat_mosaic_text()`, `geom_mosaic_jitter()`, and `stat_mosaic_jitter()` |
| `offset` | the same six constructors |
| `expected` | `geom_mosaic()`, `stat_mosaic()`, `geom_mosaic_text()`, and `stat_mosaic_text()` |

The documentation needs to explain the resolution rule consistently:

1. an argument explicitly supplied to a layer wins, including
   `expected = NULL`;
2. otherwise the corresponding value in `mosaic_settings()` is used;
3. otherwise the existing layer default is used (`mosaic()`, `0.01`, or
   `NULL`).

This is a missingness-sensitive API. Although the layer signatures still print
defaults such as `expected = NULL`, omitting an argument is different from
explicitly passing that default when a plot setting exists. That distinction is
the most important behavior to document.

The layer-local form remains valid and is useful for single-layer plots and
intentional overrides. Documentation should not mechanically replace every
`geom_mosaic(expected = ...)` call. It should use `mosaic_settings()` when a
value is shared by sibling layers, while retaining some layer-local examples to
show backward compatibility and precedence.

## Roxygen changes

### 1. Complete the new component's reference documentation

Source: [`R/mosaic-settings.R`](../R/mosaic-settings.R)

The current page is a good starting point: it documents all three arguments,
order independence, repeated settings, explicit `expected = NULL`, return
class, and a shared-model example. Add the following details:

- State the full resolution order above, including the fallback defaults.
- Explicitly say that a setting is inherited only when the layer argument is
  omitted. Give a short override example, preferably including
  `geom_mosaic(expected = NULL)` because it is the non-obvious case.
- List which constructors inherit each setting. In particular, clarify that
  the jitter geom/stat inherit `divider` and `offset`, but not `expected`.
- Explain that `mosaic_settings()` is plot-local and does not modify package or
  session defaults.
- Extend `@seealso` to the three `stat_*()` constructors, or link to the two
  shared geom/stat help topics in prose.
- Consider demonstrating that placement before or after the layers has the
  same effect and that repeated calls merge by field. These semantics are in
  the prose now, but a compact example would make them discoverable.

Do not promise shared computation or model-fit caching. The component shares
configuration; each layer currently resolves and performs its own computation.

### 2. Document inheritance on every affected layer argument

Sources:

- [`R/geom-mosaic.r`](../R/geom-mosaic.r)
- [`R/geom-mosaic-text.R`](../R/geom-mosaic-text.R)
- [`R/geom-mosaic-jitter.R`](../R/geom-mosaic-jitter.R)

For `divider` and `offset`, each page currently describes the value and the
ordinary default but does not say that the value can come from
`mosaic_settings()` when omitted. Add the inheritance sentence to all three
source blocks. The shared `@rdname` arrangement will then cover their paired
stats.

For `expected`:

- On the mosaic geom/stat page, retain the accepted forms (`NULL`, formula,
  and the three shortcuts), describe inheritance, and state that an explicit
  layer value overrides the plot setting.
- On the mosaic-text page, change “Required when using
  `display_values = "expected"` or `"residual"`” to say that an *effective*
  model is required, supplied either directly or via `mosaic_settings()`.
- Make the `display_values` parameter use the same wording; its current “Use
  ... with the `expected` parameter” implies that only a direct layer argument
  works.

### 3. Fix the duplicate `expected` roxygen definition

Source: [`R/stat-mosaic.r`](../R/stat-mosaic.r)

This file has its own `@param expected` under `@rdname geom_mosaic`. In the
generated [`man/geom_mosaic.Rd`](../man/geom_mosaic.Rd), that shorter text wins
over the more complete block in `R/geom-mosaic.r`. The installed help page
therefore currently omits:

- the accepted formula/shortcut/`NULL` forms;
- the meaning of the three shortcuts;
- `mosaic_settings()` inheritance; and
- the distinction between an omitted value and explicit `expected = NULL`.

Use one canonical `@param expected` definition for the shared help topic
(preferably the geom's), or make the stat block identical/inherited so roxygen
cannot silently discard the important part. `stat_mosaic_text()` gained an
`expected` formal and is also on this shared page, so the resulting description
must apply to all three usages on that page.

### 4. Update examples that duplicate shared settings

Sources:

- [`R/geom-mosaic-text.R`](../R/geom-mosaic-text.R), first divider example
- [`R/geom-mosaic-jitter.R`](../R/geom-mosaic-jitter.R), the two examples that
  repeat the same divider in the tile and jitter layers

The residual/expected examples in `R/geom-mosaic-text.R` already use
`mosaic_settings(expected = "independence")`; keep those. Convert at least one
repeated-divider example on each relevant help page to:

```r
ggplot(...) +
  mosaic_settings(divider = c("vspine", "hspine", "hspine")) +
  geom_mosaic(...) +
  geom_mosaic_text(...) # or geom_mosaic_jitter(...)
```

This shows that plot settings solve geometry mismatches too, rather than
presenting the feature only as a model-sharing helper. Retain a layer-level
divider example somewhere to demonstrate overrides.

### 5. Mention the alternate model source on the residual scale page

Source: [`R/scale-residual.R`](../R/scale-residual.R)

The description currently says the scale is for `geom_mosaic()` “when
`expected` parameter is specified.” Change this to say that the model may be
supplied directly to the mosaic layer or through `mosaic_settings()`. A
single-layer example can remain layer-local; optionally make one multi-layer
example use plot settings and text labels.

### 6. Regenerate, do not hand-edit, derived reference files

After changing roxygen, run the package's normal documentation generation and
verify at least:

- `man/mosaic_settings.Rd`
- `man/geom_mosaic.Rd`
- `man/geom_mosaic_text.Rd`
- `man/geom_mosaic_jitter.Rd`
- `man/scale_fill_residual.Rd`

Also rebuild the pkgdown reference pages under `docs/reference/`. The
`NAMESPACE` export and `ggplot_add.ggmosaic_settings` registration are already
present; this audit does not call for a namespace change.

## Vignette changes

### 1. `loglinear-models.Rmd` — required, highest priority

Source: [`vignettes/loglinear-models.Rmd`](../vignettes/loglinear-models.Rmd)

This is the main user-facing model tutorial and currently teaches the old
multi-layer contract.

- In the introduction and “Model Specification,” explain that `expected` can
  be supplied to one layer or shared at plot scope with `mosaic_settings()`.
- Add a small “Sharing a model across layers” subsection that states the
  resolution/override rule. This is the best vignette location for the
  omitted-vs-explicit-`NULL` example.
- In chunk `residual-labels`, replace the two repeated
  `expected = "independence"` arguments with one
  `mosaic_settings(expected = "independence")` call.
- Delete or rewrite the sentence immediately after that chunk which currently
  says the same `expected` parameter “must” be specified in both geoms. It is
  now false.
- Make the same conversion in chunks `expected-values`, `custom-scale`,
  `text-aesthetics`, and `model-comparison`. The last chunk is especially
  valuable because it shows string and formula settings across three plots.
- Keep several single-layer examples (for example `independence-model`,
  `shortcuts`, and `custom-formula`) using `geom_mosaic(expected = ...)` so the
  direct API remains documented.

There are seven repeated model specifications to remove from multi-layer
examples (currently around lines 198/200, 218/220, 244/252, 282/284, 311/313,
323/325, and 335/337).

### 2. `frequency-table-forms.Rmd` — required

Source:
[`vignettes/frequency-table-forms.Rmd`](../vignettes/frequency-table-forms.Rmd)

- In chunk `residual-labels`, replace the duplicate model arguments with one
  `mosaic_settings()` call and remove the `# Must match!` comment.
- Do the same in chunk `expected-values`.
- Add one sentence before the first example explaining that the plot setting
  keeps the tile and text computations aligned.
- In “Key Takeaways,” change “Uses `expected` parameter” to acknowledge both
  the layer argument and plot-level setting.
- Leave the single-layer residual examples layer-local; they continue to be
  correct and help teach the simpler form.

### 3. `ggmosaic.Rmd` — required for the general API tutorial

Source: [`vignettes/ggmosaic.Rmd`](../vignettes/ggmosaic.Rmd)

The “Other features of `geom_mosaic()`” section calls `divider` and `offset`
arguments unique to `geom_mosaic()`. They are now shared by the mosaic,
mosaic-text, and mosaic-jitter geom/stat families, so this wording is stale.

- Rename/reframe the section as mosaic layout settings.
- Explain the choice between direct per-layer arguments and plot-scoped
  `mosaic_settings(divider = ..., offset = ...)`.
- Add a short layered example showing a tile plus labels or jitter inheriting
  one divider/offset, followed by an intentional per-layer override.
- Preserve the existing single-layer divider gallery; those calls are not
  wrong and should not all be converted.
- While editing, align the offset explanation with the current API: `offset`
  is the gap at the deepest split and gaps increase by a factor of 1.5 toward
  outer splits. “Space between the first spine” and “decreases as layers
  build” are ambiguous and use “layer” for a partition depth.

### 4. `introducing-ggmosaic2.Rmd` — required because it inventories additions

Source:
[`vignettes/introducing-ggmosaic2.Rmd`](../vignettes/introducing-ggmosaic2.Rmd)

Add a short subsection introducing `mosaic_settings()` as a new ggmosaic2 API,
ideally near “Spacing of cells” or “Residual-Based Shading.” Show one example
that shares `expected` and either `divider` or `offset` across
`geom_mosaic()`/`geom_mosaic_text()`. Cover plot locality and layer override
precedence in prose.

The existing residual-only examples use one mosaic layer and can stay as
direct `geom_mosaic(expected = ...)` examples. The important change is to stop
the vignette from inventorying ggmosaic2 additions without mentioning the new
component.

## Generated vignette/site outputs

The source of truth is the four `.Rmd` files above. After editing them:

- rebuild the vignettes and run their code;
- regenerate the tracked `vignettes/frequency-table-forms.html` and
  `vignettes/loglinear-models.html` copies from their `.Rmd` sources;
- rebuild the corresponding `docs/articles/*.md` and `.html` pkgdown pages;
- refresh figures only where output actually changes; and
- do not hand-edit generated HTML.

## Not required by this API change

- `prodcalc()` does not inherit plot settings; it is a lower-level computation
  function and its roxygen should continue to describe only its direct
  arguments.
- Divider helper pages (`mosaic()`, `ddecker()`, `hspine()`, etc.) do not need
  to discuss plot settings.
- Single-layer examples using `geom_mosaic(expected = ...)`,
  `divider = ...`, or `offset = ...` remain valid.
- `README.Rmd` and `NEWS.md` are outside the requested roxygen/vignette scope,
  but a release-facing documentation pass should add a brief
  `mosaic_settings()` example and NEWS entry there as a follow-up.

## Verification checklist

- [ ] `?mosaic_settings` names every participating geom/stat and documents
      precedence, omission, explicit `NULL`, plot locality, ordering, and
      repeated-call behavior.
- [ ] `?geom_mosaic`, `?geom_mosaic_text`, and `?geom_mosaic_jitter` say that
      applicable settings are inherited when omitted.
- [ ] The generated `?geom_mosaic` page retains the complete `expected`
      description after resolving the duplicate roxygen block.
- [ ] No vignette says that `expected` must be repeated in both tile and text
      layers.
- [ ] No `# Must match!` comments remain in vignette source.
- [ ] Multi-layer vignette examples use one shared model/layout setting unless
      they are deliberately demonstrating an override.
- [ ] Single-layer/direct-argument examples remain, documenting backward
      compatibility.
- [ ] `devtools::document()` (or the package's equivalent), vignette builds,
      examples, and `R CMD check` complete successfully.
- [ ] pkgdown reference and article output is regenerated from source.

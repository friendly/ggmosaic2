# Scratchpad: facet-specific product axes (issue #78)

## Reproduction and diagnosis

The example in `issues/issue78.R` reproduces the bug with ggplot2 4.0.3.
`StatMosaic$compute_panel()` already calculates a separate mosaic and separate
`product_scales()` result for each `PANEL`, so the rectangle geometry is correct.
The problem occurs after that calculation:

- `facet_grid(. ~ CYCLE)` gives both panels `SCALE_X = 1` and `SCALE_Y = 1`.
- Consequently, ggplot2 creates one `ScaleContinuousProduct` object and trains it
  with the axis metadata emitted by both panels.
- `ScaleContinuousProduct$train()` replaces its functional breaks and labels the
  first time it sees a computed scale. Later panels cannot replace those values,
  because they are no longer functions. Both facets therefore render the first
  facet's tick positions.
- This is not just an accidental conditional in `train()`: a fixed ggplot2 facet
  deliberately owns one position-scale object. A scale extension cannot return
  different break vectors from that one object at axis-rendering time because it
  is not told which panel is being rendered.

The diagnostic values make the failure easy to assert. The country break
positions should be approximately:

| panel | country break positions |
| --- | --- |
| Zyklus 1 | 0.2348, 0.7348, 1.0000 |
| Zyklus 2 | 0.1383, 0.4369, 0.7986 |

The age positions also differ between panels. This matters when facets are laid
out in columns: `facet_grid(scales = "free")` creates separate x scales per
column but still shares one y scale for the single row. Thus `free_x` or `free`
on the existing grid is only a partial general solution.

As an immediate workaround, this example is correct with
`facet_wrap(~ CYCLE, scales = "free", axes = "all")`: `facet_wrap()` assigns
both an x- and a y-scale clone to every panel. The package fix should preserve a
grid layout without requiring users to understand this implementation detail.

## Recommended implementation

Add a mosaic-specific grid facet, provisionally `facet_mosaic_grid()`, whose
public arguments mirror `ggplot2::facet_grid()` but whose position scales are
always panel-specific.

1. Add `R/facet-mosaic.R` with a small `FacetGrid` subclass. Its
   `compute_layout()` should call the parent method and then assign unique
   `SCALE_X` and `SCALE_Y` identifiers from `PANEL`. Retain the parent's
   `ROW`/`COL`, strip placement, margins, labeller, and fixed panel sizing.
   Product coordinates are normalized to the same range, so independent scale
   objects change axis metadata without changing the intended panel sizes.
2. Make `facet_mosaic_grid()` construct that facet and default to
   `axes = "all"`, `axis.labels = "all"`, so both directions can actually be
   shown for every panel. Document that every panel gets independent product
   axes even though its physical grid dimensions remain fixed.
3. Do not try to accumulate panel-indexed breaks in
   `ScaleContinuousProduct$train()`. The scale/guide API has no reliable panel
   identity at rendering time, and a counter based on call order would be
   stateful and fragile across rebuilds, saved plots, and ggplot2 releases.
4. Keep `StatMosaic$compute_panel()` and `product_scales()` as the source of axis
   metadata. Once ggplot2 supplies one cloned product scale per panel, their
   existing list-column handoff should train the matching clone. Check that a
   second mosaic-derived layer in the same panel (for example,
   `geom_mosaic_text()`) retrains with identical metadata without changing it.
5. Update `issues/issue78.R` to use the new facet and regenerate its reference
   image. Add a short faceting example to the geom/facet documentation and a
   NEWS entry. Mark #78 complete in `issues/TASKS.md` only after the regression
   checks pass.

This does require replacing `facet_grid()` with `facet_mosaic_grid()` in user
code. Transparently changing an already-added standard ggplot2 facet from a
geom or scale would require hooking the whole plot-build process, which is a
much riskier and more surprising API change.

## Regression checks

Follow the repository's current standalone-test convention with a new
`tests/facet-axes.R` (or move this into `testthat` if the package adopts it
first):

1. Build the issue #78 plot and assert that there are two x and two y panel
   scales, with distinct break vectors.
2. For each panel, assert that every primary break equals the midpoint of the
   corresponding outer rectangle used by `product_scales()`, and that the
   labels remain in factor-level order.
3. Assert the numeric country positions above, especially that Zyklus 2 does
   not reuse Zyklus 1's breaks.
4. Exercise facets in rows, facets in columns, and a two-dimensional grid. In
   every case, both scale IDs must be unique per `PANEL`; this catches the
   row/column sharing behavior of ordinary `facet_grid(scales = "free")`.
5. Inspect `ggplotGrob()` to confirm that axes requested with `axes = "all"`
   contain the expected labels for every panel, not merely correct values in
   the built scale objects.
6. Cover an absent factor level (Schweiz in Zyklus 1). Preserve the package's
   current empty-level policy rather than silently combining this bug fix with
   a change to factor dropping.
7. Confirm that a non-faceted mosaic, manual `scale_x_productlist()` breaks and
   labels, secondary axes, `coord_flip()`, and a mosaic plus
   `geom_mosaic_text()` continue to build unchanged.

## Lower-cost fallback

If adding a public facet subclass is out of scope for this release, document
`facet_wrap(..., scales = "free", axes = "all")` as the supported workaround
and add the same build-level regression around that usage. Merely recommending
`facet_grid(scales = "free")` should be avoided because it still shares y
scales across columns (and x scales across rows).

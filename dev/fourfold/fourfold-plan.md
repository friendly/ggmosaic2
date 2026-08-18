# Fourfold geom implementation plan

## Objective

Add a production-quality ggplot2 fourfold display to **ggmosaic2** that:

- reproduces the statistics and visual semantics of `vcd::fourfold()`;
- behaves as a normal ggplot2 layer;
- delegates strata layout to `facet_grid()` or `facet_wrap()`;
- remains readable in the RStudio plot pane and in raster and vector exports; and
- keeps the public API smaller than `vcd::fourfold()` by leaving plot composition
  to ggplot2.

The existing files `dev/fourfold/ggfourfold.R` and `dev/fourfold/verify-ggfourfold.R` are the
validated prototype and numerical/visual reference. They should be treated as
source material, not moved wholesale into `R/`.

## Agreed public API

### `geom_fourfold()`

The primary interface is a geom operating on long-form data:

```r
geom_fourfold(
  mapping = NULL,
  data = NULL,
  ...,
  std = c("margins", "ind.max", "all.max"),
  margin = c(1, 2),
  conf_level = 0.95,
  extended = TRUE,
  ticks = 0.15,
  p_adjust_method = p.adjust.methods,
  palette = fourfold_palette(),
  na.rm = FALSE,
  show.legend = FALSE,
  inherit.aes = TRUE
)
```

Required aesthetics:

- `x`: the two-level variable drawn left-to-right;
- `y`: the two-level variable drawn top-to-bottom; and
- `weight`: the cell frequency, defaulting to `1` when raw observations are
  supplied.

For compatibility with contingency-table presentation, the first `y` level is
drawn at the top and the second at the bottom. The first `x` level is drawn on
the left and the second on the right. Thus a vcd-like UCB display uses:

```r
ggplot(ucb, aes(x = Gender, y = Admit, weight = Freq)) +
  geom_fourfold() +
  facet_wrap(vars(Dept), ncol = 3, labeller = label_both) +
  labs(title = "Berkeley admissions") +
  theme_fourfold()
```

Standard ggplot2 layer arguments may be retained where required by `layer()`,
but should not become fourfold-specific controls. `stat_fourfold()` should be
internal initially; export it only if an independent use case emerges.

Do not expose these prototype or vcd device/layout arguments on the geom:

- `fontsize`, `main`, and `sub`;
- `space`, `mfrow`, and `mfcol`;
- `default_prefix`, `sep`, `varnames`;
- `newpage` and `return_grob`;
- `show_counts`, `show_labels`, `label_offset`, or `zero_correction`.

Titles use `labs()`, strata use facets and facet labellers, and typography and
spacing use `theme_fourfold()`. Counts and category labels are part of the
default fourfold display rather than optional modes. The zero-cell correction
must match vcd and is not a user-facing tuning parameter.

### `theme_fourfold()`

```r
theme_fourfold(base_size = 12, base_family = "", ...)
```

Follow the `theme_mosaic()` convention: `base_size` and `base_family` control
all display text, including cell counts and the labels drawn by the fourfold
geom. The theme should also provide:

- a square panel;
- blank ordinary axes, ticks, grid, and panel background;
- transparent facet strips styled like the vcd stratum headings;
- compact title-to-facet spacing;
- sufficient panel spacing and plot margins for labels; and
- user overrides through `...`, applied last.

Retain the prototype's responsive text behaviour: `base_size` supplies the
baseline, while the final rendered size responds to the physical panel size
with a readable lower bound. This is necessary because fixed point sizes looked
too small when the RStudio pane was enlarged, while unconstrained scaling
failed in smaller panes.

Use ggplot2's theme-derived geom defaults (`from_theme(fontsize)` and
`from_theme(family)`) to pass the theme baseline into `GeomFourfold`, then apply
the responsive sizing in its text grobs. This requires ggplot2 4.0; update the
minimum ggplot2 version in `DESCRIPTION` rather than introducing order-dependent
theme/layer mutation. Document this dependency change in `NEWS.md`.

### Palette

The six colours are intrinsic to the fourfold association encoding, so they
default in the geom rather than requiring a fill scale:

```r
fourfold_palette <- function() {
  c(
    "#99CCFF", "#6699CC",
    "#FFA0A0", "#A0A0FF",
    "#FF0000", "#000080"
  )
}
```

Use the argument name `palette`: `fill` conventionally denotes one fixed fill
aesthetic, while `colour` conventionally denotes outlines. Validate that a
custom palette supplies at least the six required colours. Keep outlines black
by default.

Do not add `scale_fill_fourfold()` initially. The geom should draw the semantic
colours directly, produce no fill legend, and leave room for a future computed
association aesthetic and scale if a genuine mapping/legend use case appears.

## Faceting contract

One facet panel represents exactly one 2-by-2 table. The geom must work
identically with standard ggplot2 faceting:

- `facet_grid(rows = vars(z))` for one stratum variable in a fixed row;
- `facet_grid(cols = vars(z))` for one stratum variable in a fixed column;
- `facet_grid(rows = vars(z1), cols = vars(z2))` for two stratum variables; and
- `facet_wrap(vars(z), ncol = ...)` when one variable needs to wrap, such as the
  2-by-3 UCB layout.

There is no custom fourfold facet. `facet_grid()` is fully supported for a
single stratum variable; `facet_wrap()` is only needed when its wrapping layout
is desired.

Facet strips supply stratum labels. Examples that aim to match vcd should use
`labeller = label_both`. Panel geometry is normalized, so there is no need for
`facet_mosaic_grid()` or panel-specific position scales.

Reject or clearly document unsupported attempts to draw multiple independent
2-by-2 tables in one panel. Do not silently overlap them.

## Data preparation and validation

Implement a small, independently testable preparation layer before drawing:

1. Evaluate `x`, `y`, `weight`, facet panel, and grouping columns using normal
   ggplot2 layer semantics.
2. Aggregate duplicate `x`/`y` combinations within each panel by summing
   `weight`.
3. Preserve factor levels; for character input, use the stable scale order
   established by ggplot2.
4. Require exactly two global levels for both `x` and `y` across participating
   panels.
5. Complete missing cells within a panel with zero counts.
6. Require finite, non-negative weights and a positive panel total.
7. Handle `NA` consistently with `na.rm`; errors and warnings should identify
   the affected panel where practical.
8. Retain original level labels for the four outer category labels.

Test the long-form preparation against equivalent 2-by-2 arrays so that data
ordering cannot silently transpose odds ratios or quadrant labels.

## Statistical implementation

Extract the proven calculations from `ggfourfold_data()` into focused internal
helpers. Keep numeric computation separate from grob construction.

For every panel:

1. Construct the table in the documented `y`-by-`x` order.
2. Calculate the odds ratio using the same orientation as vcd.
3. If any observed cell is zero, add 0.5 to all four cells for the odds ratio,
   log-odds standard error, and significance calculation, exactly as vcd does.
4. Implement all three vcd standardizations:
   - `std = "margins"` with the selected `margin`;
   - `std = "ind.max"`; and
   - `std = "all.max"`.
5. Compute Wald confidence limits on the log-odds scale at `conf_level`.
6. Convert each confidence limit back to a table with the observed fixed
   margins, then convert those cells to ring radii.
7. Compute the vcd log-odds significance test used by `extended = TRUE`.
8. Apply `p.adjust(..., method = p_adjust_method)` across all facet panels in
   the layer, not separately within each panel.

`std = "all.max"` also requires a layer-wide maximum. Override the appropriate
stat layer computation stage so the all-panel prepass happens after facet panel
assignment but before panel drawing. Do not implement these two operations as
independent `compute_panel()` calculations.

`conf_level = 0` suppresses confidence rings, matching vcd. Adjusted p-values
control only the extended colour emphasis; confidence intervals remain
unadjusted.

Numerical helpers should return a tidy intermediate structure containing at
least observed counts, standardized counts, odds ratio, log-odds standard
error, confidence limits, raw and adjusted p-values, colour class, quadrant
radii, and confidence-ring radii.

## Geometry and rendering

Implement `GeomFourfold` as one panel grob composed in normalized panel
coordinates. Using normalized coordinates prevents discrete x/y scales from
distorting the circles and makes standard facets reliable.

Each panel draws, in a stable z-order:

1. quadrant fills;
2. quadrant outlines;
3. confidence rings, when enabled;
4. horizontal and vertical dividers;
5. reference ticks and extended diagonal ticks;
6. the square frame;
7. four observed counts;
8. four outer category labels.

Port the verified prototype geometry rather than approximating it anew,
including:

- square-root radius encoding;
- standardization radii;
- confidence-ring construction;
- tick positions and lengths;
- vcd quadrant colour assignment;
- frame and line widths; and
- responsive label sizing and measured clearances.

Reserve padding inside each panel for labels rather than drawing them outside
the viewport. This avoids clipping in the RStudio plot pane, PNG devices, PDF,
and SVG without requiring `coord_cartesian(clip = "off")`. The circular display
area should remain square and centered within the padded panel.

Text roles should use relative multipliers from the theme-derived base size:

- counts and outer category labels at the base responsive size;
- facet strips at the heading multiplier; and
- plot titles through ordinary ggplot2 theme elements.

Avoid device-specific constants where possible. Where physical measurements
are necessary, express them through grid units and verify them at multiple DPI
values.

## Package files

Expected production changes:

- `R/geom-fourfold.R`: exported geom and `GeomFourfold`;
- `R/stat-fourfold.R`: internal stat plus data/statistical helpers;
- `R/theme-fourfold.R`: exported theme;
- `R/fourfold-palette.R`: exported palette helper, or colocate it with the geom
  if it remains small;
- `tests/testthat/test-stat-fourfold.R`: numerical and validation tests;
- `tests/testthat/test-geom-fourfold.R`: layer, facet, theme, and grob tests;
- `tests/testthat/test-theme-fourfold.R`: theme defaults and overrides;
- `man/`: roxygen-generated documentation;
- `NAMESPACE`: roxygen-generated exports and imports;
- `DESCRIPTION`: ggplot2 minimum version and any visual-test dependency;
- `NEWS.md`: new API and dependency note; and
- one vignette or article section showing long-form data, `facet_grid()`,
  `facet_wrap()`, palette customization, and export.

Do not export the current `ggfourfold()` array wrapper as part of the first API.
It can remain in `dev/` as a reference and may later become a convenience
wrapper if real usage warrants it.

## Verification plan

### Statistical tests

Carry forward and expand the assertions in `dev/fourfold/verify-ggfourfold.R`:

- odds ratios and orientation for known 2-by-2 tables;
- log-odds standard errors;
- zero-cell 0.5 correction;
- Wald confidence limits;
- reconstructed confidence tables preserving requested margins and target odds
  ratios;
- confidence-ring radii;
- `margins`, `ind.max`, and `all.max` standardization;
- raw and Holm-adjusted p-values across facets;
- custom p-adjustment methods;
- aggregation of duplicate rows;
- completion of absent cells;
- factor-level ordering;
- invalid level counts, weights, totals, palettes, margins, and confidence
  levels; and
- equivalence between long-form UCB data and `UCBAdmissions` arrays.

Compare numerical results directly with vcd using tolerances justified by the
underlying formulas. Do not use screenshot similarity as evidence of
statistical correctness.

### Layout and API tests

Build and draw plots for:

- an unfaceted table;
- `facet_grid()` with one row variable;
- `facet_grid()` with one column variable;
- two-variable `facet_grid()`;
- a 2-by-3 `facet_wrap()`;
- reordered factor levels;
- a custom palette;
- `theme_fourfold(base_size = ...)` at several sizes;
- titles, subtitles, captions, and `label_both`; and
- plots composed with additional ggplot2 layers where support is intended.

Assert that facet choice does not change panel statistics and that changing
`base_size` changes every fourfold text role coherently.

### Visual verification

Keep a scripted visual comparison against `vcd::fourfold()` for the UCB data
and at least one asymmetric and one zero-cell table. Compare geometry, quadrant
orientation, fills, counts, labels, ticks, confidence rings, and significance
emphasis.

The required device matrix is:

- RStudio-like plot pane at 1300-by-948 px and 192 DPI;
- a smaller, typical RStudio plot pane;
- PNG export at 1728-by-1224 px and 144 DPI;
- PNG export at 3600-by-2550 px and 300 DPI;
- PDF export; and
- SVG export.

For raster devices, retain automated grid measurements of text bounding boxes.
Require positive clearance between:

- neighbouring panel labels;
- row headings and adjacent labels;
- outer labels and the panel frame;
- titles and the first facet row; and
- all text and device boundaries.

Use a minimum four-pixel clearance at the RStudio reference size, with larger
clearance expected at export resolutions. Also inspect the rendered images
manually at their native size because collision metrics alone do not catch
poor visual balance.

Vector exports should be rendered back to raster for inspection and checked for
font substitution, clipping, line-width changes, and preservation of circular
geometry.

## Implementation sequence

1. **Freeze reference behaviour.** Preserve the current prototype outputs and
   record the vcd numeric and visual fixtures used by the verification script.
2. **Implement data preparation.** Convert long-form layer data into one
   validated 2-by-2 table per facet panel, with explicit orientation tests.
3. **Extract statistical helpers.** Port and unit-test odds ratios,
   standardization, confidence rings, significance tests, and layer-wide
   adjustments independently of ggplot rendering.
4. **Implement the stat.** Add facet-aware layer computation, including the
   global `all.max` and p-adjustment prepass.
5. **Implement the geom.** Port the verified grob geometry and responsive text,
   using normalized panel coordinates and the built-in default palette.
6. **Implement the theme and palette.** Add theme-derived text defaults,
   compact title spacing, facet-strip styling, safe panel gutters, and the
   palette helper. Raise the ggplot2 minimum version to 4.0.
7. **Exercise standard facets.** Verify `facet_grid()` and `facet_wrap()` across
   the supported layouts without adding a custom facet implementation.
8. **Run the complete device matrix.** Iterate on padding and responsive sizing
   until automated clearance checks and native-size inspection both pass.
9. **Integrate the package API.** Add roxygen documentation, examples,
   namespace entries, tests, NEWS, and a vignette/article example.
10. **Final regression pass.** Run package tests, `R CMD check`, the statistical
    comparison script, and all visual exports. Confirm existing mosaic geoms and
    `theme_mosaic()` are unchanged.

## Definition of done

The implementation is complete when:

- the public API consists initially of `geom_fourfold()`,
  `theme_fourfold()`, and `fourfold_palette()`;
- standard facets wholly control strata layout;
- all statistical comparisons with vcd pass, including cross-panel adjustment
  and zero cells;
- the default visual encoding matches vcd closely;
- typography is controlled through `theme_fourfold(base_size, base_family)`;
- labels do not collide or clip in the RStudio reference panes or supported
  export devices;
- PNG, PDF, and SVG exports preserve the intended geometry;
- documentation clearly explains orientation, faceting, standardization, and
  palette semantics; and
- package tests and `R CMD check` pass without regressions.

# Notes on `mosaicresid` (CRAN, v0.1.1, published 2026-11-20)

Author: Sam Butler. MIT license. GitHub: https://github.com/sbutler22/geom_mosaic.
About 800 lines. Imports ggplot2, dplyr, tibble, purrr, rlang. The README says it was
developed with substantial help from Claude.

Sources read: all help pages, README, and both vignettes (`getting-started` and
`comparison`). I also ran a few checks (script in the session scratchpad); the
results are below.

## What it does

A ggplot2-native version of `mosaicplot(shade = TRUE)` for **two-way tables only**.

```r
ggplot(Titanic) + geom_mosaic_resid(aes(x = Class, y = Survived))
```

Exports:

| Function | Role |
|---|---|
| `geom_mosaic_resid()` | All-in-one call. It returns a `mosaicresid_layers` list (rect layer + in-tile text layer + default fill scale), added via custom `ggplot_add` methods (S3 for ggplot2 < 4, S7 for 4.0+) |
| `stat_mosaic_residual()` / `StatMosaicResidual` | Tiles + `n`, `expected`, `residual`. The default geom is `rect` |
| `stat_mosaic_label()` / `StatMosaicLabel` | In-tile "x\ny" labels at tile centroids. Tiles smaller than `min_label_width` / `min_label_height` (0–1 units) are dropped |
| `compute_mosaic_residuals(data, x, y, weight, spacing, dir, type)` | A plain tibble of tile geometry + counts + expected + residuals, with no ggplot involved |
| `to_long_counts()` | Raw or aggregated data → long counts. NAs are dropped (like `table()`), unused levels are dropped, zero cells are kept |
| `scale_fill_mosaic_residual()` | A wrapper around `scale_fill_gradient2(firebrick / white / steelblue)` |
| `fortify.table` (S3, registered) | Makes `ggplot(<table>)` work by calling `as.data.frame()`. A `Freq` column is then used as the weight automatically |

Options: `spacing` (one gap fraction for all levels); `dir = c("v","h")`, the same as `mosaicplot(dir=)`;
`type = "pearson" | "deviance" | "FT"`, the same as `mosaicplot(type=)`; label size/colour;
and `scale_low/mid/high/midpoint` scale arguments passed through `geom_mosaic_resid()`.

The model is always two-way independence. More than two variables is ruled out on purpose (see
"Defending the one deliberate gap" in the comparison vignette).

## What I checked

- **Residuals are correct.** Pearson residuals for Hair × Eye match `chisq.test()$residuals`
  exactly (max diff 0).
- **Table input works.** `ggplot(HairEyeColor) + geom_mosaic_resid(aes(Hair, Eye))` collapses
  over `Sex` through the auto-`Freq` weight.
- **Faceting works.** `facet_wrap(~Sex)` fits a separate independence model in each panel,
  which is effectively a conditional-independence display.
- **Axes are bare 0–1 numbers.** Tiles are identified only by the in-tile labels. There are no
  category axis labels at all, not even for the outer variable.
- **The label thresholds don't stop overflow.** The two-line "Black\nGreen" labels still spill
  out of thin tiles at default settings (see the HairEyeColor × Sex facet plot). The thresholds
  are in npc-ish units and know nothing about the text's extent.
- **The fill can't be remapped.** `aes(fill = after_stat(n))` gives "Ignoring unknown
  aesthetics: fill". The fill is fixed to the residual, so the only change possible is swapping
  the scale.
- **The more-than-two-variable error is not as described.** Passing `x = c("Hair","Sex")` to
  `compute_mosaic_residuals()` gives `subscript out of bounds`, not the explicit error pointing
  to `loglin()` / `glm()` that the vignette describes.
- **No residual cutoffs or outline cues.** There are no Friendly-style shading levels (|r| > 2, 4)
  and no sign-coded borders. The legend is a plain colourbar.

## What its comparison vignette says about ggmosaic2

The `comparison` vignette compares mosaicresid against base `mosaicplot()` and ggmosaic2. It
says plainly that ggmosaic2 is "the more complete package" for production use. Most of its
table is fair, but several cells are inaccurate or outdated:

| Their claim | Actual (ggmosaic2 0.5.1) |
|---|---|
| Input: "raw data + `aes(x = product(...))`" (implying no pre-aggregated data) | `weight =` handles aggregated data; the `?geom_mosaic` examples use `weight = Freq`. **Fair point:** a bare `table` is *not* accepted, because `ggplot(HairEyeColor)` fails with no `fortify.table` |
| Residual types: "pearson only" | **Correct.** `R/loglinear.R` computes only Pearson residuals |
| Split direction: "divider (4 options)" | It also has `mosaic()`, `ddecker()` and arbitrary divider vectors |
| Labels: "`ggrepel`-based collision handling" | ggrepel is optional (`repel = TRUE`). The default is centred text, with `check_overlap` available |
| Extras: `facet_mosaic()` | The export is `facet_mosaic_grid()` |
| ~3,500 lines, 9 imports | Accurate |

It may be worth a friendly note to the author (GitHub issue) correcting the input, divider and
label rows.

## What ggmosaic2 could learn or borrow

In rough order of value / effort:

1. **More residual types (`residual_type = c("pearson", "deviance", "FT", "standardized")`).**
   This is the one real feature gap. `loglinear.R` already fits `glm(poisson)`, so deviance
   residuals are just `residuals(fit, "deviance")`. Adjusted/standardized residuals
   (`rstandard(fit, type = "pearson")`) are what vcd/vcdExtra recommend, and mosaicresid doesn't
   have them, so offering them would put ggmosaic2 ahead rather than just level. Freeman–Tukey
   is `sqrt(n) + sqrt(n+1) - sqrt(4e+1)`. The scale and legend title would need to say which
   residual type is shown.

2. **Accept `table` / `xtabs` objects directly.** This is their most convenient feature
   (`ggplot(Titanic) + ...`). Two options:
   - Auto-use a `Freq` column as `weight` when `weight` is unmapped and `Freq` exists (with a
     one-time message). This is low risk.
   - A `fortify.table` method. **Caution:** registering an S3 method on a ggplot2 generic for a
     base class is global, and if both packages register it, whichever loads last wins. (Here it
     happens to be harmless because both are just `as.data.frame()`.) It may be better to
     suggest it upstream to ggplot2, or to give ggmosaic2's own helper a distinct name.

3. **An exported "just the numbers" function.** `compute_mosaic_residuals()` is a nice teaching
   and debugging hook. ggmosaic2 users currently need `layer_data()`. A small exported wrapper,
   e.g. `mosaic_data(data, formula/vars, expected = , divider = )` returning
   tiles + `.n` + `.expected` + `.residual`, would make the loglinear machinery inspectable and
   testable without building a plot.

4. **Size-threshold label suppression in `geom_mosaic_text()`.** Add a `min_size` (or
   `min_width` / `min_height`) argument to drop labels for tiny tiles. This is simpler and more
   predictable than `check_overlap`. mosaicresid shows that npc thresholds alone are not enough,
   so a better version would compare the label's grob width/height with the tile in `draw_panel`.

5. **Tests against reference implementations.** ggmosaic2 has **no `tests/` directory**.
   mosaicresid's main credibility claim is that its residuals are "verified to floating-point
   precision against base R." ggmosaic2 should at least have testthat checks that:
   - its Pearson residuals for two-way independence equal `chisq.test()$residuals`;
   - n-way `expected =` models agree with `loglin(..., fit = TRUE)` / `vcdExtra` fits;
   - tile areas are proportional to counts.

6. **A `dir`-style shorthand for base-R users.** `dir = c("v","h")` maps directly to
   `divider = c("vspine","hspine")`. A doc line, or an alias in `mosaic()`, could help people
   moving from `mosaicplot()` / `vcd::mosaic()`.

7. **Document NA and zero-cell semantics** the way `to_long_counts()` does: NAs dropped like
   `table()`, zero cells kept as zero-height tiles with residuals still computed. Check that
   ggmosaic2 does the same with zeros (and doesn't drop them through `productplots`).

8. **Two-variable `aes(x =, y =)` sugar (low priority, debatable).** mosaicresid's main pitch is
   "no `product()` wrapper." ggmosaic2 could accept `aes(x = A, y = B)` as sugar for
   `x = product(B, A)` in the two-way case. That would make the comparison moot, but it adds API
   surface and may clash with the existing `y`/`conds` semantics. Their own vignette admits plain
   x/y doesn't generalize past two variables.

Not worth borrowing: the list-of-layers return value plus custom `ggplot_add` methods (it is
fragile across ggplot2 3.x/4.x, and they needed both S3 and S7 paths); the one-size `spacing`;
and the unlabelled 0–1 axes.

## Things ggmosaic2 already does better (useful for our own comparison text)

- n-way tables and arbitrary loglinear `expected =` models (formula or shortcut).
- A full divider vocabulary (spine/bar/ddecker/mosaic), plus offsets, `conds`, and
  `facet_mosaic_grid()`.
- Proper category axes through `scale_x/y_productlist`.
- A residual legend with fixed ±4 breaks, sign-coded outlines (solid blue / dashed red), and
  limits.
- `geom_mosaic_jitter()`, `geom_mosaic_text()` with display values, plotly support, and the
  Shiny app.

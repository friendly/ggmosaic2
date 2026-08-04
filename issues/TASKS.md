# ggmosaic2 — development tasks

Broken out from the cross-package working list in `C:\Dropbox\R\TASKS-all.md` (2026-07-30).
Update here as items are finished; sync back to the main list only if it's useful to see
ggmosaic2 status at a glance.

Scanned `issues/` (25 files — no `dev/` or `extra/` folder here) on 2026-07-30, cross-checked
against `R/`, `NEWS.md`, and `man/`. Unlike most other packages reviewed, almost everything
documented here is already shipped — this folder reads more like a development log than a
backlog. Gavin Klorfine (collaborator/author) is now working on a separate `GK-work` branch (not
yet merged to `master`), with his own open list in `issues/GK-ideas.md` there.

As these items are resolved, check them off as [X].

## Resolved / shipped

Verified against current `R/` source, not just the docs' own claims.

- [X] Loglinear model residual shading — the core feature motivating this fork. `expected`
  parameter on `geom_mosaic()`/`stat_mosaic()`, with `"independence"`/`"saturated"`/`"conditional"`
  shortcuts or a custom formula, Pearson residuals via `scale_fill_residual()`. Confirmed in
  `R/loglinear.R`, `R/scale-residual.R`, `R/calculate.R`.
  Docs: `PULL_REQUEST.md`, `README.md`, `loglinear-residual-shading-plan.md`,
  `implementation-summary.md`
  
- [X] `display_values`/`format_digits` on `geom_mosaic_text()` — show observed/expected/residual
  values in cells instead of just labels. Confirmed in `R/geom-mosaic-text.R`.
  Doc: `display-values-feature.md`
  
- [X] Text-aesthetics fix — `fontface`/`family`/`angle`/`hjust`/`vjust`/`lineheight` are now real
  controllable aesthetics on `geom_mosaic_text()` instead of hardcoded. Confirmed in
  `R/geom-mosaic-text.R` (`default_aes`, values pulled from data not literals).
  Doc: `text-aesthetics-fix.md`
  
- [X] ggplot2 4.0+ compatibility — `make_title()` signature fix in `R/scale-product.R`, namespace
  qualification (`ggmosaic::mosaic()`/`ggmosaic::ddecker()`) to avoid `vcd::mosaic()` collision,
  array-dimension handling fix in `R/divide.R`. Confirmed in source; `check-fixes.md` itself
  states `devtools::check()` passes clean.
  
- [X] `%>%` → `|>` and `unite_()` → `unite()` migration — confirmed zero remaining `%>%` or
  `unite_(` in `R/`.
  Doc: `shading-tests.md` (the `%>%` bug report), `check-fixes.md` (notes the `unite_()` item)
- [X] Loglinear-models and frequency-table-forms vignettes — both exist in `vignettes/` and are
  referenced from `NEWS.md` 0.4.1.
  Docs: `vignette-summary.md`, `loglin-vignette-additions.md`

- [X] Fixed issue [#82](https://github.com/haleyjeppson/ggmosaic/issues/78) from `haleyjeppson/ggmosaic`, where one couldn't use ggmosaic code without importing it into the current namespace.

## Open / not yet done

- [ ] `loglinear-residual-shading-plan.md`'s `residuals_type` option
  (`c("pearson", "deviance", "rstandard")`, matching `vcdExtra::mosaic.glm()`) — only Pearson
  residuals are implemented; the note in `PULL_REQUEST.md` flags the others as "could be added
  later."
  
- [ ] Deprecation warnings noted in `check-fixes.md`'s "Future Enhancements": `continuous_scale()`
  `scale_name`/`trans` args in `R/scale-product.R` (should be `transform`) — not yet addressed.
  
- [ ] No formal test suite (`tests/testthat/`) — `check-fixes.md` explicitly recommends adding
  tests for `divide_once()` edge cases, namespace conflicts, and ggplot2 version compatibility;
  none exist yet, only the manual scripts in `issues/`.
  
- [ ] Consider a `Conflicts`-style note in `DESCRIPTION` documenting the `vcd::mosaic()` /
  `ggmosaic::mosaic()` name collision (`check-fixes.md` recommendation).
  
- [ ] `vignette-outline-extended-topics.md` — a wishlist of 8 additional vignette topics
  (statistical testing, model diagnostics, real-world applications, etc.); none written yet beyond
  the outline itself.
  
- [ ] From Gavin's `issues/GK-ideas.md` on the `GK-work` branch (not yet merged):
  - [X] `rot_labels` argument for `R/theme-mosaic.R`
  - [X] `.gitignore` the knitted `.html` files under `issues/` (several present:
    `implementation-summary.html`, `loglinear-models-quick-reference.html`,
    `vignette-outline-extended-topics.html`)
  - [ ] `CLAUDE.md`/`AGENTS.md` for the repo (Gavin's note: write by hand rather than `/init`,
    or use `/init`'s output as a starting point)
  - [X] New package logo — already done (checked off on his list)

- [ ] Revise the `README.Rmd` file. 
  - [ ] Perhaps change the main example to a more standard CDA one
  - [ ] Illustrate residual shading, use of `geom_poiont()`
  - [ ] Edit or delete the out of date section "Version compatibility issues with ggplot2"
  
- [ ] Edit package citation

## Outstanding issues inherited from the original `ggmosaic`

Source: the open issues on the
[`haleyjeppson/ggmosaic` GitHub issues page](https://github.com/haleyjeppson/ggmosaic/issues),
reviewed 2026-08-01. Issues already addressed in `ggmosaic2` are omitted (along with an issue related to accessing it off of CRAN).

- [X] Make product-axis ticks and labels facet-specific
  ([#78](https://github.com/haleyjeppson/ggmosaic/issues/78)). The positions should be computed
  from each facet's proportions rather than reused from another panel. Implemented with
  `facet_mosaic_grid()`, which assigns separate x and y product scales to every panel.

- [ ] Repair user-supplied secondary axes on `scale_x_productlist()` and
  `scale_y_productlist()` ([#26](https://github.com/haleyjeppson/ggmosaic/issues/26)). The
  original reversed test was corrected, but the current code looks up ggplot2's removed internal
  `is.sec_axis()` and therefore still errors with ggplot2 4.0.3.

- [X] Support variables computed inside aesthetics
  ([#59](https://github.com/haleyjeppson/ggmosaic/issues/59)), such as
  `fill = factor(cyl)` or factor transformations inside `product()`. Mosaic layers now evaluate
  these expressions through safe internal variable names while retaining readable plot labels.

- [X] Respect user-specified factor ordering
  ([#77](https://github.com/haleyjeppson/ggmosaic/issues/77)), including reordering helpers such
  as `forcats::fct_inorder()` inside `product()`. This was resolved by the issue #59 aesthetic-
  mapping fix; precomputed ordered factors already retain their levels through the mosaic
  calculation.

- [ ] Allow `fill` to colour existing tiles without automatically becoming another partitioning
  variable ([#15](https://github.com/haleyjeppson/ggmosaic/issues/15)). Residual shading now has
  a dedicated solution, but arbitrary derived or external fill values can still introduce
  unintended subdivisions.

- [ ] Allow custom Plotly tooltip text
  ([#57](https://github.com/haleyjeppson/ggmosaic/issues/57)). The Plotly conversion currently
  hard-codes category labels and frequency instead of preserving a mapped `text` aesthetic.

- [ ] Permit different tile offsets for horizontal and vertical splits
  ([#28](https://github.com/haleyjeppson/ggmosaic/issues/28)); the current `offset` argument is a
  single value applied to both directions.

- [ ] Add a way to calculate and display differences in conditional probabilities
  ([#10](https://github.com/haleyjeppson/ggmosaic/issues/10)), or document a recommended workflow
  for deriving and plotting them.

## Reference/historical, not actionable

`PULL_REQUEST.md` and `README.md` are the original upstream PR description and this folder's own
index — useful context, not tasks.

`haireye-jitter.R`, `haireyecolor.R`, `vcd-comparison.R`, `side-by-side-comparison.R`,
`residual-shading-examples.R`, `quick-test.R`, `debug-labels.R`, `debug-model-fitting.R`,
`test-display-values.R`, `test-text-size.R`, `test-vignette-code.R` are worked examples/debug
scripts for the now-shipped features above — candidates for cleanup once nothing else needs them
for reference, not reviewed file-by-file for deletion yet.

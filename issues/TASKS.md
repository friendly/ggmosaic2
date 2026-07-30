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
  - [ ] `rot_labels` argument for `R/theme-mosaic.R`
  - [ ] `.gitignore` the knitted `.html` files under `issues/` (several present:
    `implementation-summary.html`, `loglinear-models-quick-reference.html`,
    `vignette-outline-extended-topics.html`)
  - [ ] `CLAUDE.md`/`AGENTS.md` for the repo (Gavin's note: write by hand rather than `/init`,
    or use `/init`'s output as a starting point)
  - [X] New package logo — already done (checked off on his list)

- [ ] Revise the `README.Rmd` file. 
  - [ ] Perhaps change the main example to a more standard CDA one
  - [ ] Illustrate residual shading, use of `geom_poiont()`
  - [ ] Edit or delete the out of date section "Version compatibility issues with ggplot2"

## Reference/historical, not actionable

`PULL_REQUEST.md` and `README.md` are the original upstream PR description and this folder's own
index — useful context, not tasks.

`haireye-jitter.R`, `haireyecolor.R`, `vcd-comparison.R`, `side-by-side-comparison.R`,
`residual-shading-examples.R`, `quick-test.R`, `debug-labels.R`, `debug-model-fitting.R`,
`test-display-values.R`, `test-text-size.R`, `test-vignette-code.R` are worked examples/debug
scripts for the now-shipped features above — candidates for cleanup once nothing else needs them
for reference, not reviewed file-by-file for deletion yet.

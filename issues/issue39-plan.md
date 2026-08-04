# Plan: keep aesthetic-only variables off product axes (issue #39)

## Reproduction and diagnosis

The example in `issues/issue39.md` still exposes the underlying problem, although
the current axis implementation no longer produces the exact screenshot from the
original package version. With the current branch and ggplot2 4.0.3:

- `fill = is_correct` is converted by `prepare_mosaic_mapping()` into the safe
  internal column `.mosaic_fill`.
- Because `is_correct` is not already in `product()`, that column is prepended to
  `mosaic_spec$marg`. This is intentional historical behaviour: an aesthetic-only
  `fill` or `alpha` variable becomes the innermost partition in the product
  formula.
- `StatMosaic$compute_panel()` passes the complete formula, including the fill
  partition, to `product_scales()`.
- `product_scales()` currently treats every formula column as axis-worthy. In the
  issue example, the bottom axis describes `predictions`, the left axis describes
  `actual`, and the automatic top secondary axis describes `is_correct`. Thus the
  fill variable still leaks into position-axis metadata even though the user did
  not put it in `x` or `conds`.

The fill partition must remain available to `prodcalc()` and the computed data so
that the rectangles and fill legend keep their existing semantics. Axis
eligibility is a separate concern and should be represented separately in the
mosaic specification.

There is also an ordering detail in the issue's expectation. Under the package's
current product/divider convention, `product(actual, predictions)` places
`predictions` on the primary x axis and `actual` on the primary y axis. The form
`product(predictions, actual)` places `actual` on x. This fix should remove
`is_correct` from the axes, but should not silently reverse the documented product
order.

This is deliberately narrower than upstream
[#15](https://github.com/haleyjeppson/ggmosaic/issues/15), which asks for arbitrary
fill values to colour already-existing tiles without becoming partitions. Solving
that request would require defining aggregation and conflict behaviour when a
tile contains multiple fill values. Issue #39 can be fixed without changing those
geometry semantics.

## Recommended implementation

1. Extend the object returned by `prepare_mosaic_mapping()` with an explicit list
   of axis variables, for example `axis = c(x_names, cond_names)`. Keep
   `marg = c(extra_names, x_names)` unchanged. A fill/alpha/colour expression
   that is also explicitly present in `product()` should refer to the matching
   x variable and therefore remain axis-eligible; only separately-added
   aesthetic variables should be excluded.
2. Add an `axis_vars` argument to `product_scales()`. Match it against
   `c(prs$marg, prs$cond)` and filter the horizontal/vertical divider indices
   before choosing primary and secondary labels. Continue using the original
   formula index and total depth when selecting the corresponding level of the
   `prodcalc()` result; otherwise label positions will be calculated from the
   wrong stage of the partition.
3. When a direction contains partitions but none of them are axis-eligible,
   return a blank product axis (empty name, breaks, and labels), not the fallback
   numeric `0`-to-`1` axis. Retain the numeric fallback only when there truly is
   no product split in that direction and that is the existing intended
   behaviour. This matters for common one-variable plots such as
   `x = product(Class), fill = Survived`, where the fill-only direction should
   not acquire category labels or an unexplained numeric axis.
4. Pass `mosaic_spec$axis` from both `StatMosaic$compute_panel()` and
   `StatMosaicJitter$compute_panel()` to `product_scales()`. Let a missing
   `axis_vars` value mean "all formula variables" so direct/internal calls using
   the legacy fallback specification remain backward compatible.
5. Leave the computed cell `label`, fill/alpha/colour propagation, residual
   shading, and legend construction unchanged. Cell labels describe complete
   tiles and may still include partition aesthetics; #39 concerns position-axis
   labels.
6. Document the distinction in `geom_mosaic()`/`stat_mosaic()` documentation:
   aesthetic-only variables may add an innermost partition, but automatic
   product axes label only variables explicitly mapped through `x` or `conds`.
   Include the confusion-matrix example with `product(predictions, actual)` if
   `actual` is intended to be horizontal. Mention
   `scale_x_productlist(sec.axis = NULL)` as the current workaround for
   suppressing the automatic top axis on older behaviour.
7. Add a NEWS entry and add #39 to `issues/TASKS.md` as resolved only after the
   regression checks pass. Do not mark #15 complete.

## Regression checks

Follow the repository's standalone-test convention with a focused file such as
`tests/product-axis-aesthetics.R`:

1. Reproduce the issue data and build the plot. Assert that no primary or
   secondary x/y axis name or label contains `is_correct`, `Correct prediction`,
   or `Incorrect prediction`.
2. Assert the remaining axes follow existing product order: with
   `product(actual, predictions)`, x labels are the `predictions` levels and y
   labels are the `actual` levels; with `product(predictions, actual)`, those
   roles are reversed.
3. Compare pre-fix and post-fix computed rectangle data (or assert the known
   18-row result with 9 positive-frequency cells) to prove the fill partition
   and mapped fill values were not removed while changing axis metadata.
4. Map a variable to both `product()` and `fill`; confirm it remains labelled on
   the appropriate position axis because it is an explicit product variable.
5. Cover one explicit x variable plus an aesthetic-only fill. The explicit
   variable must retain its categorical axis and the fill-only direction must
   have no categorical or numeric ticks.
6. Repeat the exclusion checks for aesthetic-only `alpha`, and for
   aesthetic-only `colour` in `geom_mosaic_jitter()`, since all are added by the
   shared mapping helper.
7. Exercise more than two explicit product variables so that legitimate inner
   variables still appear on the automatic top/right secondary axes while
   aesthetic-only variables do not. Also verify that
   `scale_*_productlist(sec.axis = NULL)` and a user-supplied secondary axis
   continue to override the automatic secondary axis.
8. Cover `conds`, transformed expressions such as `fill = factor(flag)`, custom
   divider vectors, `coord_flip()`, and a paired `geom_mosaic()` plus
   `geom_mosaic_text()` build. These cases protect the safe-name work from #59
   and the primary/secondary-axis work from #78.

Finally run all standalone scripts under `tests/` and `devtools::check()` so the
change is verified against package loading, generated documentation, examples,
and the current ggplot2 extension API.

## Acceptance criteria

- Variables mapped only to fill, alpha, or jitter colour do not appear on
  automatic product axes.
- Aesthetic variables explicitly included in `product()` or `conds` remain
  eligible for position-axis labels.
- Rectangle geometry, frequencies, cell labels, aesthetic values, and legends
  are unchanged by the axis fix.
- Existing product-variable ordering, manual scale labels, and secondary-axis
  controls remain unchanged.

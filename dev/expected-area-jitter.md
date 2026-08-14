# Expected-area mosaics with observed-count jitter: how vcd does it, and a sketch for ggmosaic2

See `dev/expected.md` for the original issue and Gavin's API discussion.
This is a design sketch only — nothing here should be implemented in `R/` yet.

## How vcd/vcdExtra do it

`vcd::mosaic()`/`strucplot()` and `vcdExtra::labeling_points()` solve this by
**decoupling the table used for geometry from the table used for
shading/counting**, rather than adding a parallel "expected mosaic" code path.

- `strucplot(type = c("observed", "expected"))`: when `type = "expected"`,
  it swaps which table gets passed as the `observed` argument to the core
  layout function (`struc_mosaic()`), while the residual/shading calculation
  *always* compares raw counts to the fitted model, regardless of `type`.
  (`vcd/R/strucplot.R:215-217`; documented in `?strucplot`.)
  
- `struc_mosaic()` never knows or cares whether the numbers it received are
  observed or expected — it just recursively splits rectangles proportional
  to whatever `observed` table it was handed (`vcd/R/mosaic.R:268-357`).
  
- `vcdExtra::labeling_points(value_type = c("observed", "expected"))` is a
  separate `labeling` callback, invoked *after* the rectangles are drawn. It
  independently looks up either the observed or expected table from the
  strucplot call and draws `round(count/scale)` jittered points per cell.
  It has no say in rectangle geometry — it only reads the already-computed
  panel viewports and drops points into them.

So structurally there are three independent pieces: 

(1) fit the model once,
(2) build rectangle geometry from *one* chosen table (observed or expected),
(3) drop points into the finished cells from *one* chosen table (almost
always observed — that's the whole point of the display). vcd keeps these
orthogonal by having (2) and (3) both pull from a shared per-cell table
lookup rather than each other.

## Sketch for ggmosaic2

The same orthogonality is the fix for the "layers must not disagree"
problem raised in `dev/expected.md`. Right now `geom_mosaic()` and
`geom_mosaic_jitter()` are two independent ggplot2 layers with two
independent `Stat`s, each free to reinvent the split — hence options 1-4
in the issue trying to force them to agree via repetition, inheritance, or
a mega-constructor.

Proposed shape, closest to issue option 4 but reframed around a shared
layout rather than a shared constructor:

1. **One Stat computes the mosaic tree once.** `StatMosaic` already fits
   the loglinear model when `expected = ` is given (for shading) and
   already computes the recursive rectangle split (for tile geometry).
   
   So, give it an `area = c("observed", "expected")` argument that selects
   *which* table (`x` or the model's fitted values) drives the split —
   directly mirroring vcd's `type` swap. Shading residuals are unaffected,
   exactly as in vcd.

2. **`geom_mosaic_jitter()` reads the same tree instead of building its
   own.** Rather than re-deriving cell boundaries from its own copy of the
   data, `StatMosaicJitter` would look up the rectangle geometry already
   computed by the preceding `StatMosaic` layer (analogous to
   `labeling_points()` reading strucplot's panel viewports) and scatter
   `n = observed count` points inside each cell it finds. It needs no
   `area` argument of its own — geometry always comes from the mosaic
   layer; only *point count* is a table choice, and that's `"observed"` by
   construction, so no argument is needed there either (unlike vcdExtra,
   which exposes `value_type` because it's a general-purpose labeling
   function reusable outside this case).

3. **Coordination mechanism.** The open question is *how* layer 2 finds
   layer 1's tree without ggplot2's normal layer independence getting in
   the way — candidates:
   
   - A cached environment/key on the built plot (e.g. a hash of the
     `product()` spec + `expected` + `area`) that `StatMosaic` writes and
     `StatMosaicJitter` reads at draw time. Fragile if specs don't match
     exactly, but requires no new user-facing API beyond `area =`.
     
   - `geom_mosaic(jitter = TRUE, ...)` (closest to issue option 4): fold
     point-drawing into the mosaic geom itself as an optional grob, so
     there is only ever one Stat and no cross-layer lookup problem at all.
     Simplest to reason about; costs a few new `jitter_*` parameters on
     `geom_mosaic()` and probably deprecates `geom_mosaic_jitter()` as a
     thin back-compat wrapper.
     
   - A small exported helper, e.g. `mosaic_layout(data, formula, expected =,
     area = "expected")`, that precomputes the rectangle tree once and can
     be passed explicitly into *both* `geom_mosaic(layout = )` and
     `geom_mosaic_jitter(layout = )`. Most explicit and least magical, at
     the cost of one more thing to teach in the README/vignette.

   Leaning toward the `geom_mosaic(jitter = TRUE)` route (bullet 2) as the
   default recommendation — it removes the "two layers must agree" problem
   entirely rather than coordinating around it, matching how vcd users
   never had two separate `mosaic()` calls to keep in sync either.

4. **API surface, sketched (pseudocode, not for `R/` yet):**

   ```r
   # Observed-area mosaic, no points (today's default)
   geom_mosaic(aes(weight = Freq, x = product(Sex, Eye, Hair)))

   # Expected-area mosaic, still no points
   geom_mosaic(aes(weight = Freq, x = product(Sex, Eye, Hair)),
               expected = "independence", area = "expected")

   # Expected-area mosaic with one observed-count point per cell
   # (this is Gavin's request / the vcd Fig 6 (Friendly 1995) reproduction)
   geom_mosaic(aes(weight = Freq, x = product(Sex, Eye, Hair)),
               expected = "independence", area = "expected",
               jitter = TRUE, jitter_mapping = aes(colour = Hair))
   ```

## Open items before any implementation

- Confirm `area = "expected"` requires `expected` to be non-NULL (mirrors
  vcd's own constraint; already noted in `issues/expected.md`).
  --> Not clear exactly what this means, but REQUIRE non-NULL seems sensible
  
- Decide the fate of `geom_mosaic_jitter()` as a standalone geom once
  `jitter = TRUE` exists on `geom_mosaic()` — deprecate vs. keep as a
  documented lower-level escape hatch. --> KEEP FOR NOW
  
- Zero cells / small expected counts: vcd's `struc_mosaic()` and
  `labeling_points()` both have existing handling for these (worth reading
  before reinventing) — `vcd/R/mosaic.R` and the installed
  `vcdExtra::labeling_points` source are the reference points.
  --> This should be considered, but not for now.

## Implementation plan

  - Do this in `dev/` for now, copying / editing files from R/.
  - Test using HEC HairEye example in `dev/HEC-jitter.R`

### Mechanism for `area = "expected"`

`productplots::margin()` is a plain weighted aggregation — it sums whatever
`.wt` column it's handed, grouped by the requested variables. So the vcd
trick ("marginalize whichever full table you picked") works here for free:
fit the loglinear model on the **finest cross-classification** of all mosaic
variables (one fitted count per full combination — `fit_loglinear_model()`
already effectively computes this, just too late in the current pipeline),
then feed *that* table's `.expected` column through the same `margin()` /
`divide()` call currently used for observed `.wt`. Every recursive split
inherits self-consistent margins automatically, regardless of whether the
model is independence / conditional / custom / saturated — no per-level
consistency math needed.

Concretely, `prodcalc()` needs reordering: compute the finest-cell table and
fit the model *before* building `wt` (today the model is fit after `divide()`
has already run), then branch on `area`:

```r
data_for_wt <- if (area == "expected") rename(finest_table, .wt = .expected) else data
wt <- margin(data_for_wt, vars$marg, vars$cond)   # same divide() call as today from here on
```

Observed `.n` (for point counts and residuals) still comes from the finest
table regardless of `area`, so shading and point-count logic are untouched.

### Phases

1. **`dev/calculate.R`** — copy of `prodcalc()` / `fit_loglinear_model()`
   reordered as above, adding `area = c("observed", "expected")`, erroring if
   `area == "expected"` and `expected` is `NULL`.

2. **`dev/stat-mosaic.r`** — copy of `StatMosaic` threading `area` through
   to the dev `prodcalc`.

3. **`dev/geom-mosaic.r`** — copy of `geom_mosaic()` / `GeomMosaic` adding
   `jitter`, `jitter_mapping`, `jitter_size`, `jitter_alpha`, `seed`. Rather
   than a shared cache/environment between two stats, fold point-generation
   into `GeomMosaic$draw_panel()` itself: when `jitter = TRUE`, it reads
   `.n` off the *same* per-cell rows already used to draw the rects, does
   the runif-scatter (porting the logic straight from
   `GeomMosaicJitter$draw_panel`), and draws a `grobTree()` of `GeomRect` +
   `GeomPoint`. Since both come from literally the same data frame in the
   same draw call, the two-stats-disagreeing problem can't happen by
   construction — this is a deviation from the three coordination
   mechanisms floated above, simpler than any of them.

4. **`dev/stat-mosaic-jitter.r`** — copy of `StatMosaicJitter` /
   `stat_mosaic_jitter()`, also threading `expected` / `area` through to the
   dev `prodcalc` (in scope for this round, unlike the original "defer"
   note above — `geom_mosaic_jitter()` gets expected-area support alongside
   `geom_mosaic(jitter = TRUE)`, not just the latter).

5. **`dev/HEC-jitter.R`** — extend with an `area = "expected", jitter = TRUE`
   case on HairEyeColor (both via `geom_mosaic(jitter = TRUE)` and via the
   two-layer `geom_mosaic() + geom_mosaic_jitter()` form), and a side-by-side
   `vcd::mosaic(HairEyeColor, expected = ~Hair+Eye, type = "expected")` (vcd
   and vcdExtra are already installed locally) as a sanity check that areas
   and point counts match.

6. Once validated, port from `dev/` into `R/` for real (new commits, updated
   roxygen docs/examples for `area`, `jitter`, `jitter_mapping`,
   `jitter_size`, `jitter_alpha`, `seed` on both `geom_mosaic()` and
   `geom_mosaic_jitter()`).


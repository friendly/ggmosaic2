# Expected-area mosaics with observed-count jitter: how vcd does it, and a sketch for ggmosaic2

See `issues/expected.md` for the original issue and Gavin's API discussion.
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

So structurally there are three independent pieces: (1) fit the model once,
(2) build rectangle geometry from *one* chosen table (observed or expected),
(3) drop points into the finished cells from *one* chosen table (almost
always observed — that's the whole point of the display). vcd keeps these
orthogonal by having (2) and (3) both pull from a shared per-cell table
lookup rather than each other.

## Sketch for ggmosaic2

The same orthogonality is the fix for the "layers must not disagree"
problem raised in `issues/expected.md`. Right now `geom_mosaic()` and
`geom_mosaic_jitter()` are two independent ggplot2 layers with two
independent `Stat`s, each free to reinvent the split — hence options 1-4
in the issue trying to force them to agree via repetition, inheritance, or
a mega-constructor.

Proposed shape, closest to issue option 4 but reframed around a shared
layout rather than a shared constructor:

1. **One Stat computes the mosaic tree once.** `StatMosaic` already fits
   the loglinear model when `expected = ` is given (for shading) and
   already computes the recursive rectangle split (for tile geometry).
   Give it an `area = c("observed", "expected")` argument that selects
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
- Decide the fate of `geom_mosaic_jitter()` as a standalone geom once
  `jitter = TRUE` exists on `geom_mosaic()` — deprecate vs. keep as a
  documented lower-level escape hatch.
- Zero cells / small expected counts: vcd's `struc_mosaic()` and
  `labeling_points()` both have existing handling for these (worth reading
  before reinventing) — `vcd/R/mosaic.R` and the installed
  `vcdExtra::labeling_points` source are the reference points.

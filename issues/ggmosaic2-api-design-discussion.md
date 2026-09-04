# Why a plot-local mosaic specification is the best fit for ggmosaic2

## Recommendation in brief

The preferred public API is a plot-local component such as
`mosaic_settings()`, resolved by mosaic layers at plot-build time:

```r
HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(
    x = product(Sex, Eye, Hair),
    weight = Freq
  )) +
  mosaic_settings(
    expected = "independence",
    offset = 0.02
  ) +
  geom_mosaic() +
  geom_mosaic_text(
    display_values = "expected",
    colour = "black"
  ) +
  scale_fill_residual(limits = c(-4, 4)) +
  theme_mosaic(rot_labels = 30)
```

The resolution order should be:

1. an explicitly supplied layer argument, including an explicit
   `expected = NULL`;
2. the plot's `mosaic_settings()` value;
3. the existing ggmosaic2 default.

This approach is preferable because the settings describe one mosaic display,
not a user session, visual theme, coordinate system, or arbitrary relationship
between two adjacent layers. It gives sibling layers a common specification
while preserving normal ggplot2 layer overrides.

Configuration sharing and computation sharing should remain separate design
problems. `mosaic_settings()` establishes consistent semantics. A private,
build-scoped cache can subsequently reuse an identical aggregation, layout, or
model fit without changing the public API.

## Discussion #121: global `options()` and custom theme elements

Source: [Best practices for global `options()` (or now custom `theme()` elements) in extensions?](https://github.com/ggplot2-extenders/ggplot-extension-club/discussions/121)

### Ideas raised

Discussion #121 considers several ways to change defaults consistently across
layers and plots:

- global R options;
- validated setter functions wrapping those options;
- custom theme elements;
- preset or re-defaulted layer constructors;
- project-local wrapper functions created with lambdas, `purrr::partial()`, or
  `ggplot2::make_constructor()`.

### Why global options are not the primary solution

Global options address a broader problem than ggmosaic2 has. They change
defaults across plots and potentially across downstream packages. The current
ggmosaic2 problem is narrower: several layers in one plot must agree on the
statistical model and layout.

The `expected` argument changes fitted values and residuals. It is therefore a
statistical decision, not merely a convenience such as a message verbosity
level. A session-wide option could silently alter a plot created inside another
function or package. It would also make the complete plot specification
impossible to read from the plot expression alone.

A validated setter would improve input checking but would not remove the
global-state problem. It would additionally require reset and temporary-scope
semantics and tests for state leakage.

### Why theme elements are not the primary solution

Themes conventionally describe non-data presentation. `divider` and `offset`
have visual consequences, but they determine cell geometry; `expected`
determines a statistical model. Putting these values in a theme would mix
presentation with computation and make `theme_mosaic()` responsible for much
more than appearance.

Themes are also normally reusable across unrelated plots. A theme carrying a
model such as `~ Hair + Eye + Sex` would be data-specific and could become
invalid when applied to another dataset.

### Why presets and partial constructors are not enough

Presets are useful for a few common configurations, and user-defined wrappers
remain a good advanced technique. They do not provide a single source of truth
for different layer families. A user would still need matching wrappers for
`geom_mosaic()`, `geom_mosaic_text()`, and `geom_mosaic_jitter()`, and continuous
settings such as `offset` do not naturally form a small preset catalogue.

They also cannot ensure that a tile layer and a text layer in the same plot
received the same specification. They merely make repetition shorter.

### What ggmosaic2 should take from #121

ggmosaic2 should adopt #121's emphasis on validation and explicit overrides,
but scope the state to one plot:

```r
mosaic_settings(expected = "independence", offset = 0.02)
```

The constructor should validate values when the component is created. There
should be no package-level setter and no automatic consultation of global
options. Users who intentionally want project-wide defaults can still define a
small wrapper around `mosaic_settings()` in their own code.

## Discussion #117: layer interdependence

Source: [layer interdependence](https://github.com/ggplot2-extenders/ggplot-extension-club/discussions/117)

### Ideas raised

Discussion #117 separates two related needs:

1. retain a common specification across layers;
2. borrow or reuse a computation performed for another layer.

The mechanisms discussed include:

- storing configuration or intermediate state in a coordinate object;
- using a package-level environment as a communication channel;
- caching computations and clearing the cache in `Stat$finish_layer()`;
- introducing an operator that explicitly connects two layers;
- returning several coordinated components from one constructor;
- using a ggraph-style plot constructor that computes a shared layout;
- adding an explicit plot component such as `specification()`.

### Why a coordinate object is not the right owner

A coordinate system controls how already-computed positions are transformed
and rendered. Mosaic `expected`, `divider`, and `offset` are inputs to the
statistical and layout computation itself. Storing them in a coord would use
the coord as an unrelated transport container.

It would also create unnecessary conflicts with legitimate user choices such
as `coord_flip()` or another coordinate extension. ggmosaic2 does not need a
new coordinate system to express its shared configuration.

### Why a package-level environment is not the right public mechanism

A package environment makes communication implicit and session-global. It
creates risks around stale state, errors during plot building, rebuilding the
same plot, nested builds, and two plots being constructed in succession.

A mutable environment can be appropriate for a private cache only when it is
owned by one plot/build, keyed by every input that affects the result, and
cleared deterministically. It should not be the source of the user's mosaic
specification.

### Why a special layer-connecting operator is unnecessary

An operator such as

```r
geom_mosaic(...) > geom_mosaic_text(...)
```

would make computation flow explicit, but it would introduce a second layer
composition grammar alongside ggplot2's `+`. It also implies adjacency and a
producer-consumer direction even though the actual concept is that both layers
belong to the same mosaic display.

The relationship should survive intervening scales, themes, or annotations and
should not depend on which sibling layer appears first. A plot-level component
models that relationship more accurately.

### Why a compound geom is not sufficient

A convenience geom could draw tiles and labels from one computation, but it
would reduce normal ggplot2 flexibility. Users may want only tiles, only text,
different mappings, different legend participation, a jitter overlay, or
additional annotations between the layers.

A compound geom could be added later as sugar, but it should not be the only
way to obtain consistent layers.

### Why a ggraph-style plot constructor is more machinery than needed

A dedicated constructor such as `ggmosaic(data, mapping, ...)` could own and
precompute a layout, similar to the role of `ggraph()`. That pattern is most
valuable when the input is a distinct data structure and all layers depend on
a transformed representation of it.

ggmosaic2 currently works with ordinary data frames and the standard
`ggplot()` composition model. Introducing a second plot constructor would
fragment the API and would still have to defer work until final mappings and
facets were known. A plot component supplies the needed ownership without
replacing `ggplot()`.

### Why the explicit `specification()` idea is the closest fit

The `specification()` form proposed in #117 maps directly onto ggmosaic2:

```r
ggplot(data, aes(...)) +
  mosaic_settings(...) +
  geom_mosaic() +
  geom_mosaic_text(...)
```

It is visible, plot-local, independent of layer order, and compatible with the
usual `+` grammar. It also provides a natural owner for a private per-plot build
context if computation caching is added later.

### What ggmosaic2 should take from #117

ggmosaic2 should explicitly preserve the distinction between specification and
cache:

- `mosaic_settings()` shares parameters and defines override semantics;
- a private build context may reuse computations only when all relevant inputs
  match;
- layers must continue to work independently when no settings component or
  reusable computation is present.

## Comparison of the alternatives

| Alternative | Scope | Visible in plot code | Order-independent | Fits statistical parameters | Can later support safe reuse | Main drawback |
|---|---|---:|---:|---:|---:|---|
| Global `options()` | Session | No | Yes | Technically | Indirectly | Hidden global statistical state |
| Custom theme elements | Plot/session theme | Yes | Yes | Poorly | Indirectly | Mixes model/layout computation with appearance |
| Preset or partial geoms | Individual constructors | Yes | Not applicable | Partly | No | Must duplicate presets across layer families |
| Coord storage | Plot coordinate system | Partly | Yes | Poorly | Possibly | Coord is an unrelated state carrier |
| Package environment | Session | No | Fragile | Technically | Yes | Leakage and stale-state risks |
| Special connecting operator | Adjacent layers | Yes | No | Yes | Yes | New grammar and producer-order semantics |
| Compound geom | One layer | Yes | Yes | Yes | Yes | Restricts independent layer composition |
| ggraph-style constructor | Whole plot | Yes | Yes | Yes | Yes | Replaces standard `ggplot()` for limited benefit |
| Sibling-layer inspection | Nearby layers | No | No | Yes | Possibly | Ambiguous and silently order-dependent |
| `mosaic_settings()` + build-time Layer | One plot | Yes | Yes | Yes | Yes | Requires a maintained custom Layer subclass |

## Implementation boundaries

The first implementation should establish correctness, not caching:

1. add and validate `mosaic_settings()`;
2. store its supplied fields in namespaced plot metadata;
3. create a custom mosaic Layer whose `setup_layer()` resolves the final
   mapping and shared settings;
4. preserve explicit layer overrides by recording `missing()` status in each
   constructor;
5. make the geom and stat interfaces symmetric, including `expected` support
   in `stat_mosaic_text()`;
6. verify legacy plots are unchanged when no settings component is used.

After semantic equivalence is established, refactor the common computation and
add a build-scoped cache. The cache key must include the panel data, evaluated
mosaic variables, weights, model specification, missing-value handling,
divider, and offset. A mismatch must cause an independent computation rather
than unsafe reuse.

This staging matters: users should depend on the plot specification and its
override rules, never on whether an internal cache happens to obtain a hit.

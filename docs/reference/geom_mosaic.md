# Mosaic plots.

A mosaic plot is a convenient graphical summary of the conditional
distributions in a contingency table and is composed of spines in
alternating directions.

## Usage

``` r
geom_mosaic(
  mapping = NULL,
  data = NULL,
  stat = "mosaic",
  position = "identity",
  na.rm = FALSE,
  divider = mosaic(),
  offset = 0.01,
  show.legend = NA,
  inherit.aes = FALSE,
  expected = NULL,
  ...
)

stat_mosaic_text(
  mapping = NULL,
  data = NULL,
  geom = "Text",
  position = "identity",
  na.rm = FALSE,
  divider = mosaic(),
  show.legend = NA,
  inherit.aes = TRUE,
  offset = 0.01,
  ...
)

stat_mosaic(
  mapping = NULL,
  data = NULL,
  geom = "mosaic",
  position = "identity",
  na.rm = FALSE,
  divider = mosaic(),
  show.legend = NA,
  inherit.aes = TRUE,
  offset = 0.01,
  expected = NULL,
  ...
)
```

## Arguments

- mapping:

  Set of aesthetic mappings created by
  [`aes()`](https://ggplot2.tidyverse.org/reference/aes.html). If
  specified and `inherit.aes = TRUE` (the default), it is combined with
  the default mapping at the top level of the plot. You must supply
  `mapping` if there is no plot mapping.

- data:

  The data to be displayed in this layer. There are three options:

  If `NULL`, the default, the data is inherited from the plot data as
  specified in the call to
  [`ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html).

  A `data.frame`, or other object, will override the plot data. All
  objects will be fortified to produce a data frame. See
  [`fortify()`](https://ggplot2.tidyverse.org/reference/fortify.html)
  for which variables will be created.

  A `function` will be called with a single argument, the plot data. The
  return value must be a `data.frame`, and will be used as the layer
  data. A `function` can be created from a `formula` (e.g.
  `~ head(.x, 10)`).

- stat:

  The statistical transformation to use on the data for this layer. When
  using a `geom_*()` function to construct a layer, the `stat` argument
  can be used to override the default coupling between geoms and stats.
  The `stat` argument accepts the following:

  - A `Stat` ggproto subclass, for example `StatCount`.

  - A string naming the stat. To give the stat as a string, strip the
    function name of the `stat_` prefix. For example, to use
    [`stat_count()`](https://ggplot2.tidyverse.org/reference/geom_bar.html),
    give the stat as `"count"`.

  - For more information and other ways to specify the stat, see the
    [layer
    stat](https://ggplot2.tidyverse.org/reference/layer_stats.html)
    documentation.

- position:

  A position adjustment to use on the data for this layer. This can be
  used in various ways, including to prevent overplotting and improving
  the display. The `position` argument accepts the following:

  - The result of calling a position function, such as
    [`position_jitter()`](https://ggplot2.tidyverse.org/reference/position_jitter.html).
    This method allows for passing extra arguments to the position.

  - A string naming the position adjustment. To give the position as a
    string, strip the function name of the `position_` prefix. For
    example, to use
    [`position_jitter()`](https://ggplot2.tidyverse.org/reference/position_jitter.html),
    give the position as `"jitter"`.

  - For more information and other ways to specify the position, see the
    [layer
    position](https://ggplot2.tidyverse.org/reference/layer_positions.html)
    documentation.

- na.rm:

  If `FALSE` (the default), removes missing values with a warning. If
  `TRUE` silently removes missing values.

- divider:

  Divider function. The default divider function is mosaic() which will
  use spines in alternating directions. The four options for
  partitioning:

  - `vspine` Vertical spine partition: width constant, height varies.

  - `hspine` Horizontal spine partition: height constant, width varies.

  - `vbar` Vertical bar partition: height constant, width varies.

  - `hbar` Horizontal bar partition: width constant, height varies.

- offset:

  Set the fixed gap at the deepest split. Gaps increase by a factor of
  1.5 toward the outermost split.

- show.legend:

  logical. Should this layer be included in the legends? `NA`, the
  default, includes if any aesthetics are mapped. `FALSE` never
  includes, and `TRUE` always includes. It can also be a named logical
  vector to finely select the aesthetics to display. To include legend
  keys for all levels, even when no data exists, use `TRUE`. If `NA`,
  all levels are shown in legend, but unobserved levels are omitted.

- inherit.aes:

  If `FALSE`, overrides the default aesthetics, rather than combining
  with them. This is most useful for helper functions that define both
  data and aesthetics and shouldn't inherit behaviour from the default
  plot specification, e.g.
  [`annotation_borders()`](https://ggplot2.tidyverse.org/reference/annotation_borders.html).

- expected:

  Optional loglinear model specification for residual shading. Positive
  residuals receive a solid dark blue outline and negative residuals a
  dashed dark red outline by default. Set `colour = NA` to remove the
  outlines from both the cells and the residual legend. See details in
  [`prodcalc`](https://friendly.github.io/ggmosaic2/reference/prodcalc.md).

- ...:

  other arguments passed on to `layer`. These are often aesthetics, used
  to set an aesthetic to a fixed value, like `color = 'red'` or
  `size = 3`. They may also be parameters to the paired geom/stat.

- geom:

  The geometric object to use to display the data for this layer. When
  using a `stat_*()` function to construct a layer, the `geom` argument
  can be used to override the default coupling between stats and geoms.
  The `geom` argument accepts the following:

  - A `Geom` ggproto subclass, for example `GeomPoint`.

  - A string naming the geom. To give the geom as a string, strip the
    function name of the `geom_` prefix. For example, to use
    [`geom_point()`](https://ggplot2.tidyverse.org/reference/geom_point.html),
    give the geom as `"point"`.

  - For more information and other ways to specify the geom, see the
    [layer
    geom](https://ggplot2.tidyverse.org/reference/layer_geoms.html)
    documentation.

## Details

Variables mapped only to `fill` or `alpha` retain their historical role
as innermost mosaic partitions, but they are not shown on the automatic
product axes. Position axes label only variables explicitly mapped
through `x` or `conds`. If an aesthetic variable is also included in
[`product()`](https://friendly.github.io/ggmosaic2/reference/product.md),
it remains eligible for an axis label.

Product variables are ordered from innermost to outermost. With the
default mosaic divider, reversing two variables swaps their horizontal
and vertical roles; for example, `product(predictions, actual)` places
`actual` on the primary x axis.

## Computed variables

- x:

  location of center of the rectangle

- y:

  location of center of the rectangle

&nbsp;

- xmin:

  location of bottom left corner

- xmax:

  location of bottom right corner

- ymin:

  location of top left corner

- ymax:

  location of top right corner

## Examples

``` r

data(titanic)

ggplot(data = titanic) +
  geom_mosaic(aes(x = product(Class), fill = Survived))

# good practice: use the 'dependent' variable (or most important variable)
# as fill variable

# if there is only one variable inside `product()`,
# `product()` can be omitted
ggplot(data = titanic) +
  geom_mosaic(aes(x = Class, fill = Survived))


ggplot(data = titanic) +
  geom_mosaic(aes(x = product(Class, Age), fill = Survived))


ggplot(data = titanic) +
  geom_mosaic(aes(x = product(Class), conds = product(Age), fill = Survived))


# if there is only one variable inside `product()`,
# `product()` can be omitted
ggplot(data = titanic) +
  geom_mosaic(aes(x = Class, conds = Age, fill = Survived))


ggplot(data = titanic) +
  geom_mosaic(aes(x = product(Survived, Class), fill = Age))


# Variables can be transformed directly inside mosaic aesthetics
ggplot(data = mtcars) +
  geom_mosaic(aes(x = product(factor(gear)), fill = factor(cyl)))


# A fill-only variable colours and partitions the tiles without appearing on
# a position axis. Reverse the product order to put `actual` on the x axis.
set.seed(19790801)
predictions <- sample(iris$Species)
confusion <- as.data.frame(table(actual = iris$Species, predictions))
confusion$is_correct <- ifelse(
  confusion$actual == confusion$predictions,
  "Correct prediction", "Incorrect prediction"
)
ggplot(confusion) +
  geom_mosaic(aes(
    weight = Freq,
    x = product(predictions, actual),
    fill = is_correct
  ))


# Just excluded for timing. Examples are included in testing to make sure they work
if (FALSE) { # \dontrun{
data(happy)

ggplot(data = happy) + geom_mosaic(aes(x = product(happy)), divider="hbar")

ggplot(data = happy) + geom_mosaic(aes(x = product(happy))) +
  coord_flip()

# weighting is important
ggplot(data = happy) +
  geom_mosaic(aes(weight=wtssall, x=product(happy)))

ggplot(data = happy) + geom_mosaic(aes(weight=wtssall, x=product(health), fill=happy)) +
  theme(axis.text.x=element_text(angle=35))

ggplot(data = happy) +
  geom_mosaic(aes(weight=wtssall, x=product(health), fill=happy), na.rm=TRUE)

ggplot(data = happy) +
  geom_mosaic(aes(weight=wtssall, x=product(health, sex, degree), fill=happy),
  na.rm=TRUE)

# here is where a bit more control over the spacing of the bars is helpful:
# set labels manually:
ggplot(data = happy) +
  geom_mosaic(aes(weight=wtssall, x=product(age), fill=happy), na.rm=TRUE, offset=0) +
  scale_x_productlist("Age", labels=c(17+1:72))

# thin out labels manually:
labels <- c(17+1:72)
labels[labels %% 5 != 0] <- ""
ggplot(data = happy) +
  geom_mosaic(aes(weight=wtssall, x=product(age), fill=happy), na.rm=TRUE, offset=0) +
  scale_x_productlist("Age", labels=labels)

ggplot(data = happy) +
  geom_mosaic(aes(weight=wtssall, x=product(age), fill=happy, conds = product(sex)),
  divider=mosaic("v"), na.rm=TRUE, offset=0.001) +
  scale_x_productlist("Age", labels=labels)

ggplot(data = happy) +
  geom_mosaic(aes(weight=wtssall, x=product(age), fill=happy), na.rm=TRUE, offset = 0) +
  facet_grid(sex~.) +
  scale_x_productlist("Age", labels=labels)

ggplot(data = happy) +
  geom_mosaic(aes(weight = wtssall, x = product(happy, finrela, health)),
  divider=mosaic("h"))

ggplot(data = happy) +
  geom_mosaic(aes(weight = wtssall, x = product(happy, finrela, health)), offset=.005)

# Spine example
ggplot(data = happy) +
 geom_mosaic(aes(weight = wtssall, x = product(health), fill = health)) +
 facet_grid(happy~.)

# Residual shading with independence model
ggplot(data = titanic) +
  geom_mosaic(aes(x = product(Class, Sex)), expected = "independence") +
  scale_fill_residual()

# Custom model formula
ggplot(data = titanic) +
  geom_mosaic(aes(x = product(Class, Sex, Survived)),
              expected = ~ Class + Sex) +
  scale_fill_residual()
} # } # end of don't run
```

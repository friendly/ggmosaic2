# Determining scales for mosaics

Determining scales for mosaics

## Usage

``` r
scale_x_productlist(
  name = ggplot2::waiver(),
  breaks = product_breaks(),
  minor_breaks = NULL,
  labels = product_labels(),
  limits = NULL,
  expand = ggplot2::waiver(),
  oob = scales::censor,
  na.value = NA_real_,
  transform = "identity",
  position = "bottom",
  sec.axis = ggplot2::waiver()
)

scale_y_productlist(
  name = ggplot2::waiver(),
  breaks = product_breaks(),
  minor_breaks = NULL,
  labels = product_labels(),
  limits = NULL,
  expand = ggplot2::waiver(),
  oob = scales::censor,
  na.value = NA_real_,
  transform = "identity",
  position = "left",
  sec.axis = ggplot2::waiver()
)

ScaleContinuousProduct
```

## Arguments

- name:

  set to pseudo waiver function `product_names` by default.

- breaks:

  One of:

  - `NULL` for no breaks

  - [`waiver()`](https://ggplot2.tidyverse.org/reference/waiver.html)
    for the default breaks computed by the [transformation
    object](https://scales.r-lib.org/reference/new_transform.html)

  - A numeric vector of positions

  - A function that takes the limits as input and returns breaks as
    output (e.g., a function returned by
    [`scales::extended_breaks()`](https://scales.r-lib.org/reference/breaks_extended.html)).
    Note that for position scales, limits are provided after scale
    expansion. Also accepts rlang
    [lambda](https://rlang.r-lib.org/reference/as_function.html)
    function notation.

- minor_breaks:

  One of:

  - `NULL` for no minor breaks

  - [`waiver()`](https://ggplot2.tidyverse.org/reference/waiver.html)
    for the default breaks (none for discrete, one minor break between
    each major break for continuous)

  - A numeric vector of positions

  - A function that given the limits returns a vector of minor breaks.
    Also accepts rlang
    [lambda](https://rlang.r-lib.org/reference/as_function.html)
    function notation. When the function has two arguments, it will be
    given the limits and major break positions.

- labels:

  One of the options below. Please note that when `labels` is a vector,
  it is highly recommended to also set the `breaks` argument as a vector
  to protect against unintended mismatches.

  - `NULL` for no labels

  - [`waiver()`](https://ggplot2.tidyverse.org/reference/waiver.html)
    for the default labels computed by the transformation object

  - A character vector giving labels (must be same length as `breaks`)

  - An expression vector (must be the same length as breaks). See
    ?plotmath for details.

  - A function that takes the breaks as input and returns labels as
    output. Also accepts rlang
    [lambda](https://rlang.r-lib.org/reference/as_function.html)
    function notation.

- limits:

  One of:

  - `NULL` to use the default scale range

  - A numeric vector of length two providing limits of the scale. Use
    `NA` to refer to the existing minimum or maximum

  - A function that accepts the existing (automatic) limits and returns
    new limits. Also accepts rlang
    [lambda](https://rlang.r-lib.org/reference/as_function.html)
    function notation. Note that setting limits on positional scales
    will **remove** data outside of the limits. If the purpose is to
    zoom, use the limit argument in the coordinate system (see
    [`coord_cartesian()`](https://ggplot2.tidyverse.org/reference/coord_cartesian.html)).

- expand:

  For position scales, a vector of range expansion constants used to add
  some padding around the data to ensure that they are placed some
  distance away from the axes. Use the convenience function
  [`expansion()`](https://ggplot2.tidyverse.org/reference/expansion.html)
  to generate the values for the `expand` argument. The defaults are to
  expand the scale by 5% on each side for continuous variables, and by
  0.6 units on each side for discrete variables.

- oob:

  One of:

  - Function that handles limits outside of the scale limits (out of
    bounds). Also accepts rlang
    [lambda](https://rlang.r-lib.org/reference/as_function.html)
    function notation.

  - The default
    ([`scales::censor()`](https://scales.r-lib.org/reference/oob.html))
    replaces out of bounds values with `NA`.

  - [`scales::squish()`](https://scales.r-lib.org/reference/oob.html)
    for squishing out of bounds values into range.

  - [`scales::squish_infinite()`](https://scales.r-lib.org/reference/oob.html)
    for squishing infinite values into range.

- na.value:

  Missing values will be replaced with this value.

- transform:

  For continuous scales, the name of a transformation object or the
  object itself. Built-in transformations include "asn", "atanh",
  "boxcox", "date", "exp", "hms", "identity", "log", "log10", "log1p",
  "log2", "logit", "modulus", "probability", "probit", "pseudo_log",
  "reciprocal", "reverse", "sqrt" and "time".

  A transformation object bundles together a transform, its inverse, and
  methods for generating breaks and labels. Transformation objects are
  defined in the scales package, and are called `transform_<name>`. If
  transformations require arguments, you can call them from the scales
  package, e.g.
  [`scales::transform_boxcox(p = 2)`](https://scales.r-lib.org/reference/transform_boxcox.html).
  You can create your own transformation with
  [`scales::new_transform()`](https://scales.r-lib.org/reference/new_transform.html).

- position:

  For position scales, The position of the axis. `left` or `right` for y
  axes, `top` or `bottom` for x axes.

- sec.axis:

  specify a secondary axis. By default, category labels for the inner
  variables of the mosaic are displayed on the opposite (top or right)
  side whenever more than one variable is split along a direction. Set
  to `NULL` to suppress these labels, or supply a
  [`sec_axis`](https://ggplot2.tidyverse.org/reference/sec_axis.html)
  for full control.

## Value

A `ggplot2` position scale that can be added to a plot.

## Examples

``` r
data(titanic)
ggplot(data = titanic, aes(x = product(Class, Sex))) +
  geom_mosaic() +
  scale_x_productlist("Passenger class / Sex")
```

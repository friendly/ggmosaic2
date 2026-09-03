#' Mosaic plots.
#'
#' @export
#'
#' @description
#' A mosaic plot is a convenient graphical summary of the conditional distributions
#' in a contingency table and is composed of spines in alternating directions.
#'
#' @details
#' Variables mapped only to `fill` or `alpha` retain their historical
#' role as innermost mosaic partitions, but they are not shown on the automatic
#' product axes. Position axes label only variables explicitly mapped through
#' `x` or `conds`. If an aesthetic variable is also included in `product()`, it
#' remains eligible for an axis label.
#'
#' Product variables are ordered from innermost to outermost. With the default
#' mosaic divider, reversing two variables swaps their horizontal and vertical
#' roles; for example, `product(predictions, actual)` places `actual`
#' on the primary x axis.
#'
#'
#' @inheritParams ggplot2::layer
#' @param divider Divider function. The default divider function is mosaic() which will use spines in alternating directions. The four options for partitioning:
#' \itemize{
#' \item \code{vspine} Vertical spine partition: width constant, height varies.
#' \item \code{hspine}  Horizontal spine partition: height constant, width varies.
#' \item \code{vbar} Vertical bar partition: height constant, width varies.
#' \item \code{hbar}  Horizontal bar partition: width constant, height varies.
#' }
#' @param offset Set the fixed gap at the deepest split. Gaps increase by a
#'   factor of 1.5 toward the outermost split.
#' @param na.rm If \code{FALSE} (the default), removes missing values with a warning. If \code{TRUE} silently removes missing values.
#' @param expected Optional specification for loglinear model residual shading.
#'   Can be a formula (e.g., \code{~ Var1 + Var2}), a character shortcut
#'   ("independence", "saturated", "conditional"), or NULL (default, no model).
#'   When omitted, the value can be inherited from \code{\link{mosaic_settings}}.
#'   When specified, Pearson residuals are calculated and automatically mapped to fill
#'   (unless fill aesthetic is explicitly set). Use with \code{\link{scale_fill_residual}}
#'   for a diverging color scale. Positive residuals receive a solid dark blue
#'   outline and negative residuals a dashed dark red outline by default.
#'   Residuals within numerical tolerance of zero receive a solid black
#'   outline. Set \code{colour = NA} to remove the outlines from both the cells
#'   and the residual legend.
#' @param ... other arguments passed on to \code{layer}. These are often aesthetics, used to set an aesthetic to a fixed value, like \code{color = 'red'} or \code{size = 3}. They may also be parameters to the paired geom/stat.
#' @examples
#'
#' data(titanic)
#'
#' ggplot(data = titanic, aes(x = product(Class), fill = Survived)) +
#'   geom_mosaic()
#' # good practice: use the 'dependent' variable (or most important variable)
#' # as fill variable
#'
#' # if there is only one variable inside `product()`,
#' # `product()` can be omitted
#' ggplot(data = titanic, aes(x = Class, fill = Survived)) +
#'   geom_mosaic()
#'
#' ggplot(data = titanic,
#'        aes(x = product(Class, Age), fill = Survived)) +
#'   geom_mosaic()
#'
#' ggplot(data = titanic,
#'        aes(x = product(Class), conds = product(Age), fill = Survived)) +
#'   geom_mosaic()
#'
#' # if there is only one variable inside `product()`,
#' # `product()` can be omitted
#' ggplot(data = titanic, aes(x = Class, conds = Age, fill = Survived)) +
#'   geom_mosaic()
#'
#' ggplot(data = titanic,
#'        aes(x = product(Survived, Class), fill = Age)) +
#'   geom_mosaic()
#'
#' # Variables can be transformed directly inside mosaic aesthetics
#' ggplot(data = mtcars,
#'        aes(x = product(factor(gear)), fill = factor(cyl))) +
#'   geom_mosaic()
#'
#' # A fill-only variable colours and partitions the tiles without appearing on
#' # a position axis. Reverse the product order to put `actual` on the x axis.
#' set.seed(19790801)
#' predictions <- sample(iris$Species)
#' confusion <- as.data.frame(table(actual = iris$Species, predictions))
#' confusion$is_correct <- ifelse(
#'   confusion$actual == confusion$predictions,
#'   "Correct prediction", "Incorrect prediction"
#' )
#' ggplot(confusion, aes(
#'     weight = Freq,
#'     x = product(predictions, actual),
#'     fill = is_correct
#'   )) +
#'   geom_mosaic()
#'
#' # Just excluded for timing. Examples are included in testing to make sure they work
#' \dontrun{
#' data(happy)
#'
#' ggplot(data = happy, aes(x = product(happy))) +
#'   geom_mosaic(divider = "hbar")
#'
#' ggplot(data = happy, aes(x = product(happy))) +
#'   geom_mosaic() +
#'   coord_flip()
#'
#' # weighting is important
#' ggplot(data = happy, aes(weight = wtssall, x = product(happy))) +
#'   geom_mosaic()
#'
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(health), fill = happy)) +
#'   geom_mosaic() +
#'   theme(axis.text.x=element_text(angle=35))
#'
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(health), fill = happy)) +
#'   geom_mosaic(na.rm = TRUE)
#'
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(health, sex, degree), fill = happy)) +
#'   geom_mosaic(na.rm = TRUE)
#'
#' # here is where a bit more control over the spacing of the bars is helpful:
#' # set labels manually:
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(age), fill = happy)) +
#'   geom_mosaic(na.rm = TRUE, offset = 0) +
#'   scale_x_productlist("Age", labels=c(17+1:72))
#'
#' # thin out labels manually:
#' labels <- c(17+1:72)
#' labels[labels %% 5 != 0] <- ""
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(age), fill = happy)) +
#'   geom_mosaic(na.rm = TRUE, offset = 0) +
#'   scale_x_productlist("Age", labels=labels)
#'
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(age), fill = happy,
#'            conds = product(sex))) +
#'   geom_mosaic(divider = mosaic("v"), na.rm = TRUE, offset = 0.001) +
#'   scale_x_productlist("Age", labels=labels)
#'
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(age), fill = happy)) +
#'   geom_mosaic(na.rm = TRUE, offset = 0) +
#'   facet_grid(sex~.) +
#'   scale_x_productlist("Age", labels=labels)
#'
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(happy, finrela, health))) +
#'   geom_mosaic(divider = mosaic("h"))
#'
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(happy, finrela, health))) +
#'   geom_mosaic(offset = .005)
#'
#' # Spine example
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(health), fill = health)) +
#'  geom_mosaic() +
#'  facet_grid(happy~.)
#'
#' # Residual shading with independence model
#' ggplot(data = titanic, aes(x = product(Class, Sex))) +
#'   geom_mosaic(expected = "independence") +
#'   scale_fill_residual()
#'
#' # Custom model formula
#' ggplot(data = titanic, aes(x = product(Class, Sex, Survived))) +
#'   geom_mosaic(expected = ~ Class + Sex) +
#'   scale_fill_residual()
#' } # end of don't run

geom_mosaic <- function(mapping = NULL, data = NULL, stat = "mosaic",
                        position = "identity", na.rm = FALSE,  divider = mosaic(), offset = 0.01,
                        show.legend = NA, inherit.aes = TRUE, expected = NULL, ...)
{
  divider_missing <- missing(divider)
  offset_missing <- missing(offset)
  expected_missing <- missing(expected)

  mosaic_layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomMosaic,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    aesthetics = c("fill", "alpha"),
    params = list(
      na.rm = na.rm,
      divider = if (divider_missing) .mosaic_inherit_setting else divider,
      offset = if (offset_missing) .mosaic_inherit_setting else offset,
      expected = if (expected_missing) .mosaic_inherit_setting else expected,
      ...
    ),
    setting_defaults = list(
      divider = mosaic(),
      offset = 0.01,
      expected = NULL
    )
  )
}

#' Geom proto
#'
#' @format NULL
#' @usage NULL
#' @export
#' @importFrom grid grobTree
GeomMosaic <- ggplot2::ggproto(
  "GeomMosaic", ggplot2::Geom,
  setup_data = function(data, params) {
    #cat("setup_data in GeomMosaic\n")
    #browser()
    data
  },
  required_aes = c("xmin", "xmax", "ymin", "ymax"),
  default_aes = ggplot2::aes(width = 0.75, linetype = "solid", fontsize=5,
                             shape = 19, colour = NA,
                             size = .1, fill = "grey55", alpha = .8, stroke = 0.1,
                             linewidth=.1, weight = 1, x = NULL, y = NULL, conds = NULL),

  draw_panel = function(data, panel_scales, coord) {
    #cat("draw_panel in GeomMosaic\n")
    #browser()
    if (all(is.na(data$colour)) && !".residual" %in% names(data))
      data$colour <- scales::alpha(data$fill, data$alpha) # regard alpha in colour determination

    GeomRect$draw_panel(subset(data, level==max(data$level)), panel_scales, coord)
  },

  check_aesthetics = function(x, n) {
    #browser()
    ns <- vapply(x, length, numeric(1))
    good <- ns == 1L | ns == n


    if (all(good)) {
      return()
    }

    stop(
      "Aesthetics must be either length 1 or the same as the data (", n, "): ",
      paste(names(!good), collapse = ", "),
      call. = FALSE
    )
  },

  draw_key = ggplot2::draw_key_polygon
)

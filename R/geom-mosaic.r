#' Mosaic plots.
#'
#' @export
#'
#' @description
#' A mosaic plot is a convenient graphical summary of the conditional distributions
#' in a contingency table and is composed of spines in alternating directions.
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
#'   When specified, Pearson residuals are calculated and automatically mapped to fill
#'   (unless fill aesthetic is explicitly set). Use with \code{\link{scale_fill_residual}}
#'   for a diverging color scale. Positive residuals receive a solid dark blue
#'   outline and negative residuals a dashed dark red outline by default. Set
#'   \code{colour = NA} to remove the cell outlines while retaining the
#'   residual legend's sign key.
#' @param ... other arguments passed on to \code{layer}. These are often aesthetics, used to set an aesthetic to a fixed value, like \code{color = 'red'} or \code{size = 3}. They may also be parameters to the paired geom/stat.
#' @examples
#'
#' data(titanic)
#'
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = product(Class), fill = Survived))
#' # good practice: use the 'dependent' variable (or most important variable)
#' # as fill variable
#'
#' # if there is only one variable inside `product()`,
#' # `product()` can be omitted
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = Class, fill = Survived))
#'
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = product(Class, Age), fill = Survived))
#'
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = product(Class), conds = product(Age), fill = Survived))
#'
#' # if there is only one variable inside `product()`,
#' # `product()` can be omitted
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = Class, conds = Age, fill = Survived))
#'
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = product(Survived, Class), fill = Age))
#'
#' # Variables can be transformed directly inside mosaic aesthetics
#' ggplot(data = mtcars) +
#'   geom_mosaic(aes(x = product(factor(gear)), fill = factor(cyl)))
#'
#' # Just excluded for timing. Examples are included in testing to make sure they work
#' \dontrun{
#' data(happy)
#'
#' ggplot(data = happy) + geom_mosaic(aes(x = product(happy)), divider="hbar")
#'
#' ggplot(data = happy) + geom_mosaic(aes(x = product(happy))) +
#'   coord_flip()
#'
#' # weighting is important
#' ggplot(data = happy) +
#'   geom_mosaic(aes(weight=wtssall, x=product(happy)))
#'
#' ggplot(data = happy) + geom_mosaic(aes(weight=wtssall, x=product(health), fill=happy)) +
#'   theme(axis.text.x=element_text(angle=35))
#'
#' ggplot(data = happy) +
#'   geom_mosaic(aes(weight=wtssall, x=product(health), fill=happy), na.rm=TRUE)
#'
#' ggplot(data = happy) +
#'   geom_mosaic(aes(weight=wtssall, x=product(health, sex, degree), fill=happy),
#'   na.rm=TRUE)
#'
#' # here is where a bit more control over the spacing of the bars is helpful:
#' # set labels manually:
#' ggplot(data = happy) +
#'   geom_mosaic(aes(weight=wtssall, x=product(age), fill=happy), na.rm=TRUE, offset=0) +
#'   scale_x_productlist("Age", labels=c(17+1:72))
#'
#' # thin out labels manually:
#' labels <- c(17+1:72)
#' labels[labels %% 5 != 0] <- ""
#' ggplot(data = happy) +
#'   geom_mosaic(aes(weight=wtssall, x=product(age), fill=happy), na.rm=TRUE, offset=0) +
#'   scale_x_productlist("Age", labels=labels)
#'
#' ggplot(data = happy) +
#'   geom_mosaic(aes(weight=wtssall, x=product(age), fill=happy, conds = product(sex)),
#'   divider=mosaic("v"), na.rm=TRUE, offset=0.001) +
#'   scale_x_productlist("Age", labels=labels)
#'
#' ggplot(data = happy) +
#'   geom_mosaic(aes(weight=wtssall, x=product(age), fill=happy), na.rm=TRUE, offset = 0) +
#'   facet_grid(sex~.) +
#'   scale_x_productlist("Age", labels=labels)
#'
#' ggplot(data = happy) +
#'   geom_mosaic(aes(weight = wtssall, x = product(happy, finrela, health)),
#'   divider=mosaic("h"))
#'
#' ggplot(data = happy) +
#'   geom_mosaic(aes(weight = wtssall, x = product(happy, finrela, health)), offset=.005)
#'
#' # Spine example
#' ggplot(data = happy) +
#'  geom_mosaic(aes(weight = wtssall, x = product(health), fill = health)) +
#'  facet_grid(happy~.)
#'
#' # Residual shading with independence model
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = product(Class, Sex)), expected = "independence") +
#'   scale_fill_residual()
#'
#' # Custom model formula
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = product(Class, Sex, Survived)),
#'               expected = ~ Class + Sex) +
#'   scale_fill_residual()
#' } # end of don't run

geom_mosaic <- function(mapping = NULL, data = NULL, stat = "mosaic",
                        position = "identity", na.rm = FALSE,  divider = mosaic(), offset = 0.01,
                        show.legend = NA, inherit.aes = FALSE, expected = NULL, ...)
{
  prepared <- prepare_mosaic_mapping(mapping, c("fill", "alpha"))
  mapping <- prepared$mapping

  add_mosaic_scale_environment(ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomMosaic,
    position = position,
    show.legend = show.legend,
    check.aes = FALSE,
    inherit.aes = FALSE, # only FALSE to turn the warning off
    params = list(
      na.rm = na.rm,
      divider = divider,
      offset = offset,
      expected = expected,
      mosaic_spec = prepared$spec,
      ...
    )
  ))
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
                             size = .1, fill = "grey30", alpha = .8, stroke = 0.1,
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

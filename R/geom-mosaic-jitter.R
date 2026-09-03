#' Jittered dots in Mosaic plots.
#'
#' @author Gavin Klorfine
#' @export
#'
#' @description
#' A mosaic plat with jittered dots
#'
#' @details
#' Variables mapped only to `fill`, `alpha`, or `colour` remain
#' available to the mosaic calculation and point aesthetics, but are not shown
#' on automatic product axes. Position axes label only variables explicitly
#' mapped through `x` or `conds`.
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
#' @param drop_level Generate points for the max - 1 level
#' @param seed Random seed passed to \code{\link[base]{set.seed}}. Defaults to
#'   \code{NA}, which means that \code{set.seed} will not be called.
#' @param na.rm If \code{FALSE} (the default), removes missing values with a warning. If \code{TRUE} silently removes missing values.
#' @param ... other arguments passed on to \code{layer}. These are often aesthetics, used to set an aesthetic to a fixed value, like \code{color = 'red'} or \code{size = 3}. They may also be parameters to the paired geom/stat.
#' @examples
#' data(titanic)
#'
#' ggplot(data = titanic, aes(x = product(Class))) +
#'   geom_mosaic(aes(fill = Survived), alpha = 0.3) +
#'   geom_mosaic_jitter(aes(color = Survived))
#'
#' ggplot(data = titanic, aes(x = product(Class))) +
#'   geom_mosaic(alpha = 0.1) +
#'   geom_mosaic_jitter(aes(color = Survived), drop_level = TRUE)
#'
#' ggplot(data = titanic, aes(x = product(Class, Sex))) +
#'   geom_mosaic(alpha = 0.3, aes(fill = Survived),
#'               divider = c("vspine", "hspine", "hspine")) +
#'   geom_mosaic_jitter(aes(color = Survived),
#'               divider = c("vspine", "hspine", "hspine"))
#'
#'  ggplot(data = titanic,
#'         aes(x = product(Class), conds = product(Sex), fill = Survived)) +
#'   geom_mosaic(alpha = 0.3,
#'               divider = c("vspine", "hspine", "hspine")) +
#'   geom_mosaic_jitter(
#'               divider = c("vspine", "hspine", "hspine"))
geom_mosaic_jitter <- function(mapping = NULL, data = NULL, stat = "mosaic_jitter",
                               position = "identity", na.rm = FALSE,  divider = mosaic(),
                               offset = 0.01, drop_level = FALSE, seed = NA,
                               show.legend = NA, inherit.aes = TRUE, ...)
{
  divider_missing <- missing(divider)
  offset_missing <- missing(offset)

  mosaic_layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomMosaicJitter,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    aesthetics = c("fill", "alpha", "colour"),
    params = list(
      na.rm = na.rm,
      divider = if (divider_missing) .mosaic_inherit_setting else divider,
      offset = if (offset_missing) .mosaic_inherit_setting else offset,
      drop_level = drop_level,
      seed = seed,
      ...
    ),
    setting_defaults = list(
      divider = mosaic(),
      offset = 0.01
    )
  )
}

#' Geom proto
#'
#' @format NULL
#' @usage NULL
#' @export
#' @importFrom grid grobTree
#' @importFrom tidyr nest unnest
#' @importFrom dplyr mutate select
GeomMosaicJitter <- ggplot2::ggproto(
  "GeomMosaicJitter", ggplot2::Geom,
  setup_data = function(data, params) {
    #cat("setup_data in GeomMosaic\n")
    #browser()
    data
  },
  # required_aes = c("xmin", "xmax", "ymin", "ymax"),
  # default_aes = ggplot2::aes(width = 0.1, linetype = "solid", fontsize=5,
  #                            shape = 19, colour = NA,
  #                            size = 1, fill = "grey30", alpha = 1, stroke = 0.1,
  #                            linewidth=.1, weight = 1, x = NULL, y = NULL, conds = NULL),
  required_aes = c("x", "y"),
  non_missing_aes = c("size", "shape", "colour"),
  default_aes = aes(
    shape = 19, colour = "grey30", size = 1, fill = NA,
    alpha = NA, stroke = 1, linewidth=.1, weight = 1
  ),

  draw_panel = function(data, panel_scales, coord) {
    #cat("draw_panel in GeomMosaic\n")
    # browser()
    # if (all(is.na(data$colour)))
    #   data$colour <- scales::alpha(data$fill, data$alpha) # regard alpha in colour determination

    # adjust the point placement for the size of the points.
    # .pt is defined in ggplot2 as 72.27 / 25.4
    dx <- grid::convertX(unit(.pt, "points"), "npc", valueOnly = TRUE)
    dy <- grid::convertY(unit(.pt, "points"), "npc", valueOnly = TRUE)
    # check out stroke and .stroke
    # mapping shape?
    #browser()
    # scale x and y coordinates to the correct place between (xmin+dx, xmax-dx) and
    # (ymin+dy, ymax-dy)
    scale_01_to_xy <- function(value, min_val, max_val) {
      # assumes that value is between 0 and 1
      value*(max_val-min_val) + min_val
    }
    data <- mutate(data,
      # could give some bit of space between any outline of a point and the
      # end of the interval
      x = scale_01_to_xy(x, xmin+1*(size)*dx, xmax-1*(size)*dx),
      y = scale_01_to_xy(y, ymin+1*(size)*dy, ymax-1*(size)*dy)
    )

    # points <- tidyr::unnest(points, coords)

    # sub$fill <- NA
    # sub$size <- sub$size/10

      ggplot2:::ggname("geom_mosaic_jitter", grobTree(
      #GeomRect$draw_panel(sub, panel_scales, coord),
      GeomPoint$draw_panel(data, panel_scales, coord)
    ))
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

  draw_key = ggplot2::draw_key_point
)

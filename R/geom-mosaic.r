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
#'   When specified, Pearson residuals are calculated and automatically mapped to fill
#'   (unless fill aesthetic is explicitly set). Use with \code{\link{scale_fill_residual}}
#'   for a diverging color scale. Positive residuals receive a solid dark blue
#'   outline and negative residuals a dashed dark red outline by default. Set
#'   \code{colour = NA} to remove the outlines from both the cells and the
#'   residual legend.
#' @param area Values used to construct mosaic rectangles: \code{"observed"}
#'   (the default) or fitted \code{"expected"} counts. Expected-area mosaics
#'   require a non-\code{NULL} \code{expected} model specification.
#' @param jitter If \code{TRUE}, draw one jittered point per unit of observed
#'   count inside each mosaic cell. Point counts are rounded to whole numbers.
#' @param jitter_mapping An optional \code{aes()} mapping for the jittered
#'   points. The supported aesthetics are \code{colour}, \code{shape},
#'   \code{size}, and \code{stroke}. Mapped variables must also occur in
#'   \code{x}, \code{conds}, \code{fill}, or \code{alpha}, ensuring that each
#'   mosaic cell has one point-aesthetic value.
#' @param jitter_size,jitter_alpha Fixed size and alpha used for jittered
#'   points unless the corresponding aesthetic is mapped.
#' @param seed Random seed for point placement. A numeric seed makes placement
#'   reproducible. The default, \code{NA}, generates a fresh placement.
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
#' # A fill-only variable colours and partitions the tiles without appearing on
#' # a position axis. Reverse the product order to put `actual` on the x axis.
#' set.seed(19790801)
#' predictions <- sample(iris$Species)
#' confusion <- as.data.frame(table(actual = iris$Species, predictions))
#' confusion$is_correct <- ifelse(
#'   confusion$actual == confusion$predictions,
#'   "Correct prediction", "Incorrect prediction"
#' )
#' ggplot(confusion) +
#'   geom_mosaic(aes(
#'     weight = Freq,
#'     x = product(predictions, actual),
#'     fill = is_correct
#'   ))
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
#' # Expected areas make observed point density proportional to observed / fitted
#' ggplot(data = titanic) +
#'   geom_mosaic(
#'     aes(weight = Freq, x = product(Class, Sex)),
#'     expected = "independence", area = "expected", jitter = TRUE,
#'     jitter_mapping = aes(colour = Sex), seed = 1
#'   ) +
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
                        show.legend = NA, inherit.aes = FALSE, expected = NULL,
                        area = c("observed", "expected"), jitter = FALSE,
                        jitter_mapping = NULL, jitter_size = 1,
                        jitter_alpha = 0.8, seed = NA, ...)
{
  area <- match.arg(area)
  if (!isTRUE(jitter) && !is.null(jitter_mapping)) {
    stop("`jitter_mapping` can only be used when `jitter = TRUE`.", call. = FALSE)
  }

  prepared <- prepare_mosaic_mapping(mapping, c("fill", "alpha"))
  integrated <- prepare_integrated_jitter_mapping(
    prepared$mapping, jitter_mapping, prepared$spec
  )
  mapping <- integrated$mapping
  mosaic_spec <- integrated$spec

  dots <- list(...)
  tile_colour <- NULL
  if (isTRUE(jitter)) {
    if ("colour" %in% names(dots)) {
      tile_colour <- dots$colour
      dots$colour <- NULL
    } else if ("color" %in% names(dots)) {
      tile_colour <- dots$color
      dots$color <- NULL
    }
  }

  add_mosaic_scale_environment(ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomMosaic,
    position = position,
    show.legend = show.legend,
    check.aes = FALSE,
    inherit.aes = FALSE, # only FALSE to turn the warning off
    params = c(list(
      na.rm = na.rm,
      divider = divider,
      offset = offset,
      expected = expected,
      area = area,
      jitter = jitter,
      jitter_size = jitter_size,
      jitter_alpha = jitter_alpha,
      seed = seed,
      tile_colour = tile_colour,
      jitter_aesthetics = names(mosaic_spec$jitter_aesthetics),
      mosaic_spec = mosaic_spec
    ), dots)
  ))
}

integrated_mosaic_jitter_data <- function(data, seed = NA) {
  counts <- round(data$.n)
  counts[!is.finite(counts) | counts < 1] <- 0
  indices <- rep.int(seq_len(nrow(data)), counts)
  if (!length(indices)) {
    points <- data[FALSE, , drop = FALSE]
    points$x <- numeric()
    points$y <- numeric()
    return(points)
  }

  if (!is.null(seed) && length(seed) == 1L && is.na(seed)) {
    seed <- sample.int(.Machine$integer.max, 1L)
  }
  coordinates <- with_seed_null(seed, list(
    x = stats::runif(length(indices)),
    y = stats::runif(length(indices))
  ))

  points <- data[indices, , drop = FALSE]
  rownames(points) <- NULL
  points$x <- coordinates$x
  points$y <- coordinates$y
  points
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

  draw_panel = function(data, panel_scales, coord, jitter = FALSE,
                        jitter_size = 1, jitter_alpha = 0.8, seed = NA,
                        tile_colour = NULL, jitter_aesthetics = character()) {
    #cat("draw_panel in GeomMosaic\n")
    #browser()
    data <- subset(data, level == max(data$level))
    tile_data <- data

    if (!is.null(tile_colour)) {
      tile_data$colour <- tile_colour
    } else if (isTRUE(jitter) && "colour" %in% jitter_aesthetics &&
               ".mosaic_tile_colour" %in% names(tile_data)) {
      tile_data$colour <- tile_data$.mosaic_tile_colour
    } else if (isTRUE(jitter) && "colour" %in% jitter_aesthetics) {
      tile_data$colour <- scales::alpha(tile_data$fill, tile_data$alpha)
    } else if (all(is.na(tile_data$colour)) && !".residual" %in% names(tile_data)) {
      # Regard alpha in colour determination, preserving the historical tile
      # outline when integrated jitter is not using the colour aesthetic.
      tile_data$colour <- scales::alpha(tile_data$fill, tile_data$alpha)
    }

    rect_grob <- GeomRect$draw_panel(tile_data, panel_scales, coord)
    if (!isTRUE(jitter)) {
      return(rect_grob)
    }

    points <- integrated_mosaic_jitter_data(data, seed = seed)
    if (!nrow(points)) {
      return(rect_grob)
    }

    if (!"colour" %in% jitter_aesthetics) points$colour <- "grey30"
    if (!"shape" %in% jitter_aesthetics) points$shape <- 19
    if (!"size" %in% jitter_aesthetics) points$size <- jitter_size
    if (!"stroke" %in% jitter_aesthetics) points$stroke <- 0.5
    points$alpha <- jitter_alpha
    points$fill <- NA

    dx <- grid::convertX(grid::unit(.pt, "points"), "npc", valueOnly = TRUE)
    dy <- grid::convertY(grid::unit(.pt, "points"), "npc", valueOnly = TRUE)
    x_min <- points$xmin + points$size * dx
    x_max <- points$xmax - points$size * dx
    y_min <- points$ymin + points$size * dy
    y_max <- points$ymax - points$size * dy
    x_mid <- (points$xmin + points$xmax) / 2
    y_mid <- (points$ymin + points$ymax) / 2
    collapsed_x <- x_min > x_max
    collapsed_y <- y_min > y_max
    x_min[collapsed_x] <- x_mid[collapsed_x]
    x_max[collapsed_x] <- x_mid[collapsed_x]
    y_min[collapsed_y] <- y_mid[collapsed_y]
    y_max[collapsed_y] <- y_mid[collapsed_y]
    points$x <- points$x * (x_max - x_min) + x_min
    points$y <- points$y * (y_max - y_min) + y_min

    ggplot2:::ggname(
      "geom_mosaic",
      grid::grobTree(
        rect_grob,
        GeomPoint$draw_panel(points, panel_scales, coord)
      )
    )
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

  draw_key = function(data, params, size) {
    if (!isTRUE(params$jitter)) {
      return(ggplot2::draw_key_polygon(data, params, size))
    }

    tile_data <- data
    if (!is.null(params$tile_colour)) {
      tile_data$colour <- params$tile_colour
    } else if ("colour" %in% params$jitter_aesthetics) {
      tile_data$colour <- NA
    }
    point_data <- data
    if (!"colour" %in% params$jitter_aesthetics) point_data$colour <- "grey30"
    if (!"shape" %in% params$jitter_aesthetics) point_data$shape <- 19
    if (!"size" %in% params$jitter_aesthetics) point_data$size <- params$jitter_size
    if (!"stroke" %in% params$jitter_aesthetics) point_data$stroke <- 0.5
    point_data$alpha <- params$jitter_alpha
    point_data$fill <- NA

    grid::grobTree(
      ggplot2::draw_key_polygon(tile_data, params, size),
      ggplot2::draw_key_point(point_data, params, size)
    )
  }
)

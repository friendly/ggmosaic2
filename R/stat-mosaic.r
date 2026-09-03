#' @rdname geom_mosaic
#' @inheritParams ggplot2::stat_identity
#' @section Computed variables:
#' \describe{
#' \item{xmin}{location of bottom left corner}
#' \item{xmax}{location of bottom right corner}
#' \item{ymin}{location of top left corner}
#' \item{ymax}{location of top right corner}
#' }
#' @export
stat_mosaic <- function(mapping = NULL, data = NULL, geom = "mosaic",
                        position = "identity", na.rm = FALSE,  divider = mosaic(),
                        show.legend = NA, inherit.aes = TRUE, offset = 0.01,
                        expected = NULL, ...)
{
  divider_missing <- missing(divider)
  offset_missing <- missing(offset)
  expected_missing <- missing(expected)

  mosaic_layer(
    data = data,
    mapping = mapping,
    stat = StatMosaic,
    geom = geom,
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


# Default outlines for residual-shaded cells, determined by residual sign.
# Treat values within the usual floating-point comparison tolerance as zero so
# numerical noise from otherwise exact fits does not receive a signed outline.
residual_outline_aesthetics <- function(
    residual, tolerance = sqrt(.Machine$double.eps)) {
  positive <- !is.na(residual) & residual > tolerance
  negative <- !is.na(residual) & residual < -tolerance

  colour <- rep("black", length(residual))
  colour[positive] <- "darkblue"
  colour[negative] <- "darkred"

  linetype <- rep("solid", length(residual))
  linetype[negative] <- "dashed"

  list(colour = colour, linetype = linetype)
}


#' Geom proto
#'
#' @format NULL
#' @usage NULL
#' @export
StatMosaic <- ggplot2::ggproto(
  "StatMosaic", ggplot2::Stat,
  #required_aes = c("x"),
  non_missing_aes = "weight",

  setup_params = function(data, params) {
    #cat("setup_params from StatMosaic\n")
    #browser()
    # if (!is.null(data$y)) {
    #   stop("stat_mosaic() must not be used with a y aesthetic.", call. = FALSE)
    # }
    params
  },

  setup_data = function(data, params) {
    #cat("setup_data from StatMosaic\n")
    #browser()

    data
  },

  compute_panel = function(self, data, scales, na.rm=FALSE, divider, offset,
                           expected = NULL, mosaic_spec = NULL) {
#    cat("compute_panel from StatMosaic\n")
#       browser()

    if (is.null(mosaic_spec)) {
      mosaic_spec <- list(
        marg = names(data)[grep("x__", names(data))],
        cond = names(data)[grep("conds[0-9]+__", names(data))],
        labels = NULL,
        aesthetics = list()
      )
    }
    vars <- mosaic_spec$marg
    conds <- mosaic_spec$cond
    formula <- mosaic_formula(mosaic_spec)

    df <- data
    if (!in_data(df, "weight")) {
      df$weight <- 1
    }


    res <- prodcalc(df, formula=formula,
                    divider = divider, cascade=0, scale_max = TRUE,
                    na.rm = na.rm, offset = offset, expected = expected,
                    variable_labels = mosaic_spec$labels)


    # need to set x variable - I'd rather set the scales here.
    prs <- parse_product_formula(formula)
    p <- length(c(prs$marg, prs$cond))
    if (is.function(divider)) divider <- divider(p)

    # compute position scales, including vcd-style category labels on the
    # top/right for inner variables (needs all levels of res)
    sc <- product_scales(
      res, formula, divider,
      labels = mosaic_spec$labels,
      axis_vars = mosaic_spec$axis
    )
    scx <- sc$x
    scy <- sc$y


    # res is data frame that has xmin, xmax, ymin, ymax
    res <- dplyr::rename(res, xmin=l, xmax=r, ymin=b, ymax=t)
    res <- subset(res, level==max(res$level))

    # export the variables with the data - terrible hack
    # res$x <- list(scale=scx)
    # if (!is.null(scales$y)) {
    #   # only set the y scale if it is a product scale, otherwise leave it alone
    #   if ("ScaleContinuousProduct" %in% class(scales$y))
    #     res$y <- list(scale=scy)
    # }
    # XXXX add label for res
    cols <- c(prs$marg, prs$cond)


    if (length(cols) > 1) {
      df <- res[,cols]
      df <- tidyr::unite(df, "label", cols, sep="\n")

      res$label <- df$label
    } else res$label <- as.character(res[,cols])
    #   browser()

    res$x <- list(scale=scx)
    if (!is.null(scales$y)) {
      # only set the y scale if it is a product scale, otherwise leave it alone
      if ("ScaleContinuousProduct" %in% class(scales$y))
        res$y <- list(scale=scy)
    }

    # merge res with data:
    # is there a fill variable?
    mapped_fill <- mosaic_spec$aesthetics$fill
    if (!is.null(mapped_fill) && mapped_fill %in% names(res)) {
      res$fill <- res[[mapped_fill]]
    }
    mapped_alpha <- mosaic_spec$aesthetics$alpha
    if (!is.null(mapped_alpha) && mapped_alpha %in% names(res)) {
      res$alpha <- res[[mapped_alpha]]
    }

    # Handle residual-based coloring when expected is specified
    if (!is.null(expected) && ".residual" %in% names(res)) {
      # Auto-map residuals to fill only if user hasn't specified fill
      if (is.null(mapped_fill)) {
        res$fill <- res$.residual
      }

      outline <- residual_outline_aesthetics(res$.residual)
      if (!"colour" %in% names(data)) {
        res$colour <- outline$colour
      }
      if (!"linetype" %in% names(data)) {
        res$linetype <- outline$linetype
      }
      if (!"linewidth" %in% names(data)) {
        res$linewidth <- 0.4
      }
      # Always pass residual column through for manual mapping
    }

    res$group <- 1 # unique(data$group) # ignore group variable
    res$PANEL <- unique(data$PANEL)
    res
  }
)

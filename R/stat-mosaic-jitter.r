#' @rdname geom_mosaic_jitter
#' @inheritParams ggplot2::stat_identity
#' @section Computed variables:
#' \describe{
#' \item{xmin}{location of bottom left corner}
#' \item{xmax}{location of bottom right corner}
#' \item{ymin}{location of top left corner}
#' \item{ymax}{location of top right corner}
#' }
#' @export
stat_mosaic_jitter <- function(mapping = NULL, data = NULL, geom = "mosaic_jitter",
                               position = "identity", na.rm = FALSE,  divider = mosaic(),
                               show.legend = NA, inherit.aes = TRUE, offset = 0.01,
                               drop_level = FALSE, seed = NA, ...)
{
  mosaic_layer(
    data = data,
    mapping = mapping,
    stat = StatMosaicJitter,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    aesthetics = c("fill", "alpha", "colour"),
    params = list(
      na.rm = na.rm,
      divider = divider,
      offset = offset,
      drop_level = drop_level,
      seed = seed,
      ...
    )
  )
}


#' Geom proto
#'
#' @format NULL
#' @usage NULL
#' @export
StatMosaicJitter <- ggplot2::ggproto(
  "StatMosaicJitter", ggplot2::Stat,
  #required_aes = c("x"),
  non_missing_aes = c("weight", "size", "shape", "colour"),
  default_aes = aes(
    shape = 19, colour = "black", size = 1.5, fill = NA,
    alpha = NA, stroke = 0.5
  ),

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

  compute_panel = function(self, data, scales, na.rm=FALSE, drop_level=FALSE,
                           seed = NA, divider, offset, mosaic_spec = NULL) {
    #cat("compute_panel from StatMosaic\n")
    #browser()

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
                    na.rm = na.rm, offset = offset)

    # browser()

    # consider 2nd weight for points
    if (in_data(df, "weight2")) {
      formula2 <- mosaic_formula(mosaic_spec, response = "weight2")
      res2 <- prodcalc(df, formula = formula2, divider = divider,
                       cascade = 0, scale_max = TRUE, na.rm = na.rm, offset = offset)
      res$.n2 <- res2$.n
    }


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
    # res <- subset(res, level==max(res$level))

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


    res$x <- list(scale=scx)
    if (!is.null(scales$y)) {
      # only set the y scale if it is a product scale, otherwise leave it alone
      if ("ScaleContinuousProduct" %in% class(scales$y))
        res$y <- list(scale=scy)
    }

    # merge res with data:
    # is there a fill/alpha/color variable?
    for (aesthetic in c("fill", "alpha", "colour")) {
      variable <- mosaic_spec$aesthetics[[aesthetic]]
      if (!is.null(variable) && variable %in% names(res)) {
        res[[aesthetic]] <- res[[variable]]
      }
    }

    res$group <- 1 # unique(data$group) # ignore group variable
    res$PANEL <- unique(data$PANEL)
    # browser()

    # generate points
    # consider 2nd weight for point
    if (in_data(res, ".n2")) {
      res$.n <- res$.n2
    }

    sub <- subset(res, level==max(res$level))
    if(drop_level) {
      ll <- subset(res, level==max(res$level)-1)
      sub <- dplyr::left_join(
        select(sub, -(xmin:ymax)),
        select(ll, all_of(vars), xmin:ymax, -contains("col"))
      )
    }


# create a set of uniformly spread points between 0 and 1 once, when the plot is created.
# the transformation to the correct scale happens in compute panel.

    # altered from ggrepel:
    # Make reproducible if desired.
    if (!is.null(seed) && is.na(seed)) {
      seed <- sample.int(.Machine$integer.max, 1L)
    }

    points <- subset(sub, sub$.n>=1)
    points <- tidyr::nest(points, data = -label)
    points <- with_seed_null(seed,
      dplyr::mutate(
        points,
        coords = purrr::map(data, .f = function(d) {
          data.frame(
            x = runif(d$.n, min = 0, max = 1),
            y = runif(d$.n, min = 0, max = 1),
            dplyr::select(d, -x, -y)
          )
        })
      ))

    points <- tidyr::unnest(points, coords)
    # browser()

    points
  }
)

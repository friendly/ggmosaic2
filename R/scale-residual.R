#' Diverging color scale for Pearson residuals
#'
#' Provides a red-white-blue color scale centered at 0 for visualizing
#' Pearson residuals from loglinear models. Designed for use with
#' \code{geom_mosaic()} when \code{expected} parameter is specified.
#'
#' @param ... Arguments passed to \code{\link[ggplot2]{scale_fill_gradient2}}
#' @param low Color for negative residuals (default: "darkred")
#' @param mid Color for zero residuals (default: "white")
#' @param high Color for positive residuals (default: "darkblue")
#' @param midpoint Center point for color scale (default: 0)
#' @param limits Range used for the color gradient. Values beyond supplied
#'   limits receive the corresponding endpoint color.
#' @param name Legend title
#'
#' @details The default legend always labels -4, 0, and 4. It also labels
#'   supplied limits and the observed minimum and maximum when those differ
#'   from the limits. The legend extends to every labelled value, with solid
#'   endpoint color beyond supplied limits. Positive residuals have a solid
#'   dark blue outline, negative residuals have a dashed dark red outline,
#'   and an unoutlined midpoint band (white by default) separates them at
#'   zero. Black ticks are drawn outside the color bar, which stretches with
#'   the mosaic panel. Nearby vertical labels are separated, and a thin elbow
#'   connects each displaced label to its exact tick. The neighbouring label
#'   uses a longer straight tick so nearby text shares a common alignment.
#'   Automatically generated numeric labels are rounded to one decimal place.
#'   The legend can be hidden normally with
#'   `theme(legend.position = "none")`.
#' @export
#' @examples
#' data(titanic)
#'
#' # Independence model with residual shading
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = product(Class, Sex)), expected = "independence") +
#'   scale_fill_residual()
#'
#' # Custom colors
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = product(Class, Sex)), expected = "independence") +
#'   scale_fill_residual(low = "red", high = "blue")
#'
#' # Custom limits to highlight strong deviations
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = product(Class, Sex, Survived)),
#'               expected = ~ Class + Sex) +
#'   scale_fill_residual(limits = c(-4, 4))
scale_fill_residual <- function(...,
                                low = "darkred",
                                mid = "white",
                                high = "darkblue",
                                midpoint = 0,
                                limits = NULL,
                                name = "Pearson\nResidual") {
  dots <- rlang::list2(...)
  if (!"oob" %in% names(dots)) {
    dots$oob <- scales::squish
  }

  scale <- rlang::exec(
    ggplot2::scale_fill_gradient2,
    !!!dots,
    low = low,
    mid = mid,
    high = high,
    midpoint = midpoint,
    limits = limits,
    name = name
  )

  if (identical(scale$guide, "colourbar")) {
    scale$guide <- guide_residual()
  }

  scale
}

# Construct the internal guide separately so explicit guide arguments supplied
# through scale_fill_residual() continue to take precedence.
guide_residual <- function() {
  guide <- ggplot2::guide_colourbar(
    theme = ggplot2::theme(
      legend.ticks = ggplot2::element_line(colour = "black", linewidth = 0.4),
      legend.text = ggplot2::element_text(
        margin = ggplot2::margin(5, 5, 5, 5)
      ),
      legend.title.position = "top"
    )
  )

  ggplot2::ggproto(
    NULL,
    GuideResidual,
    available_aes = guide$available_aes,
    params = guide$params
  )
}

# Values shown by the residual legend. Combining before sorting naturally
# removes labels when an observed extreme coincides with a supplied limit or
# with one of the fixed reference values.
residual_legend_breaks <- function(scale) {
  observed <- scale$range$range
  observed <- observed[is.finite(observed)]
  if (length(observed) > 0) {
    observed <- range(observed)
  }

  supplied <- numeric()
  if (!is.null(scale$limits)) {
    supplied <- scale$get_limits()
    supplied <- supplied[is.finite(supplied)]
  }

  sort(unique(c(-4, 0, 4, supplied, observed)))
}

residual_legend_labels <- function(scale, breaks) {
  labels <- scale$get_labels(breaks)

  # Keep custom labels untouched. For the default numeric labels, make the
  # positive sign explicit to match the two signed halves of the guide and
  # show a consistent tenths digit.
  if (inherits(scale$labels, "waiver")) {
    labels <- formatC(breaks, format = "f", digits = 1)
    positive <- breaks > 0
    labels[positive] <- paste0("+", labels[positive])
  }

  labels
}

residual_legend_colours <- function(scale, values, alpha = NA) {
  limits <- scale$get_limits()
  values <- scales::squish(values, range = limits)
  scales::alpha(scale$map(values), alpha)
}

spread_residual_legend_labels <- function(position, min_gap) {
  if (length(position) < 2) {
    return(position)
  }

  ordering <- order(position)
  spread <- position[ordering]
  for (index in 2:length(spread)) {
    spread[index] <- max(spread[index], spread[index - 1] + min_gap)
  }

  if (spread[length(spread)] > 1) {
    spread[length(spread)] <- 1
    for (index in (length(spread) - 1):1) {
      spread[index] <- min(spread[index], spread[index + 1] - min_gap)
    }
  }

  if (spread[1] < 0) {
    spread[1] <- 0
    for (index in 2:length(spread)) {
      spread[index] <- max(spread[index], spread[index - 1] + min_gap)
    }
  }

  result <- position
  result[ordering] <- spread
  result
}

residual_legend_label_positions <- function(position, direction) {
  min_gap <- if (identical(direction, "horizontal")) 0.14 else 0.075
  spread_residual_legend_labels(position, min_gap)
}

residual_legend_long_ticks <- function(position, direction) {
  label_position <- residual_legend_label_positions(position, direction)
  moved <- abs(label_position - position) > sqrt(.Machine$double.eps)
  min_gap <- if (identical(direction, "horizontal")) 0.14 else 0.075
  vapply(seq_along(position), function(index) {
    !moved[index] && any(moved & abs(position[index] - position) < min_gap)
  }, logical(1))
}

GuideResidual <- ggplot2::ggproto(
  "GuideResidual",
  ggplot2::GuideColourbar,

  setup_elements = function(params, elements, theme) {
    if (identical(params$direction, "horizontal") && is.null(theme$legend.key.width)) {
      theme$legend.key.width <- grid::unit(1, "null")
    }
    if (identical(params$direction, "vertical") && is.null(theme$legend.key.height)) {
      theme$legend.key.height <- grid::unit(1, "null")
    }

    ggplot2::GuideColourbar$setup_elements(
      params = params,
      elements = elements,
      theme = theme
    )
  },

  process_layers = function(self, params, layers, data = NULL, theme = NULL) {
    # Residual fill is added by StatMosaic rather than appearing in the user's
    # aesthetic mapping, so ggplot2's ordinary mapped-aesthetic check cannot
    # see it. Retain the guide when such a layer contributes residual data,
    # while still respecting show.legend = FALSE.
    include <- vapply(seq_along(layers), function(index) {
      show <- layers[[index]]$show.legend
      hidden <- isFALSE(show) ||
        (!is.null(names(show)) && "fill" %in% names(show) && isFALSE(show[["fill"]]))
      has_residuals <- !is.null(data[[index]]) && ".residual" %in% names(data[[index]])
      !hidden && has_residuals
    }, logical(1))

    processed <- ggplot2::GuideColourbar$process_layers(
      params = params,
      layers = layers,
      data = data,
      theme = theme
    )
    if (!is.null(processed)) {
      return(processed)
    }

    if (any(include)) params else NULL
  },

  extract_key = function(scale, aesthetic, ...) {
    if (scale$is_discrete()) {
      return(NULL)
    }

    breaks <- residual_legend_breaks(scale)
    if (length(breaks) == 0) {
      return(NULL)
    }

    key <- data.frame(residual_legend_colours(scale, breaks))
    names(key) <- aesthetic
    key$.value <- breaks
    key$.label <- residual_legend_labels(scale, breaks)
    key
  },

  extract_decor = function(scale, aesthetic, nbin = 300,
                           reverse = FALSE, alpha = NA, ...) {
    limits <- range(residual_legend_breaks(scale))
    values <- seq(limits[1], limits[2], length.out = nbin)
    decor <- data.frame(
      colour = residual_legend_colours(scale, values, alpha),
      value = values
    )

    if (reverse) {
      decor <- decor[nrow(decor):1, , drop = FALSE]
    }

    decor
  },

  extract_params = function(scale, params, title = ggplot2::waiver(), ...) {
    params <- ggplot2::GuideColourbar$extract_params(
      scale = scale,
      params = params,
      title = title,
      ...
    )

    endpoints <- params$decor$value[c(1, nrow(params$decor))]
    params$zero <- scales::rescale(0, from = endpoints)
    params$zero_colour <- residual_legend_colours(scale, 0)
    params$positive_at_high_end <- endpoints[2] > endpoints[1]
    params
  },

  build_ticks = function(key, elements, params, position = params$position) {
    tick_index <- seq_along(key$.value)
    if (!params$draw_lim[1]) {
      tick_index <- tick_index[-1]
    }
    if (!params$draw_lim[2]) {
      tick_index <- tick_index[-length(tick_index)]
    }
    tick_position <- key$.value[tick_index]
    if (length(tick_position) == 0 || inherits(elements$ticks, "element_blank")) {
      return(grid::zeroGrob())
    }

    label_position <- residual_legend_label_positions(
      key$.value,
      params$direction
    )[tick_index]
    moved <- abs(label_position - tick_position) > sqrt(.Machine$double.eps)
    long_tick <- residual_legend_long_ticks(
      key$.value,
      params$direction
    )[tick_index]
    side <- elements$text_position
    count <- length(tick_position)

    if (identical(params$direction, "horizontal")) {
      edge <- if (identical(side, "top")) 1 else 0
      x <- grid::unit(rep(tick_position, each = 2), "npc")
      direction <- if (identical(side, "top")) 1 else -1
      tick_length <- grid::unit(ifelse(long_tick, 0.45, 0.15), "cm")
      y <- do.call(grid::unit.c, lapply(seq_len(count), function(index) {
        grid::unit.c(
          grid::unit(edge, "npc"),
          grid::unit(edge, "npc") + direction * tick_length[index]
        )
      }))
    } else {
      edge <- if (identical(side, "left")) 0 else 1
      direction <- if (identical(side, "left")) -1 else 1
      tick_length <- grid::unit(ifelse(long_tick, 0.45, 0.15), "cm")
      x <- do.call(grid::unit.c, lapply(seq_len(count), function(index) {
        grid::unit.c(
          grid::unit(edge, "npc"),
          grid::unit(edge, "npc") + direction * tick_length[index]
        )
      }))
      y <- grid::unit(rep(tick_position, each = 2), "npc")
    }

    ticks <- ggplot2::element_grob(
      elements$ticks,
      x = x,
      y = y,
      id.lengths = rep(2, count)
    )

    if (!any(moved)) {
      return(ticks)
    }

    tick_position <- tick_position[moved]
    label_position <- label_position[moved]
    leader_count <- length(tick_position)
    if (identical(params$direction, "horizontal")) {
      x <- grid::unit(
        as.vector(rbind(tick_position, tick_position, label_position, label_position)),
        "npc"
      )
      y <- rep(
        grid::unit(edge, "npc") + direction * grid::unit(c(0.15, 0.30, 0.30, 0.45), "cm"),
        leader_count
      )
    } else {
      x <- rep(
        grid::unit(edge, "npc") + direction * grid::unit(c(0.15, 0.30, 0.30, 0.45), "cm"),
        leader_count
      )
      y <- grid::unit(
        as.vector(rbind(tick_position, tick_position, label_position, label_position)),
        "npc"
      )
    }

    leaders <- ggplot2::element_grob(
      elements$ticks,
      x = x,
      y = y,
      id.lengths = rep(4, leader_count)
    )
    grid::grobTree(ticks, leaders)
  },

  build_labels = function(key, elements, params) {
    label_position <- residual_legend_label_positions(
      key$.value,
      params$direction
    )
    moved <- abs(label_position - key$.value) > sqrt(.Machine$double.eps)
    long_tick <- residual_legend_long_ticks(key$.value, params$direction)
    offset <- grid::unit(ifelse(moved | long_tick, 0.60, 0.20), "cm")

    if (identical(params$direction, "horizontal")) {
      side <- elements$text_position
      x <- grid::unit(label_position, "npc")
      offset <- grid::unit(ifelse(long_tick | moved, 0.60, 0.20), "cm")
      y <- if (identical(side, "top")) {
        grid::unit(0, "npc") + offset
      } else {
        grid::unit(1, "npc") - offset
      }
      hjust <- 0.5
      vjust <- if (identical(side, "top")) 0 else 1
    } else {
      side <- elements$text_position
      direction <- if (identical(side, "left")) -1 else 1
      x <- direction * offset
      y <- grid::unit(label_position, "npc")
      hjust <- if (identical(side, "left")) 1 else 0
      vjust <- 0.5
    }

    list(labels = ggplot2::element_grob(
      elements$text,
      label = key$.label,
      x = x,
      y = y,
      hjust = hjust,
      vjust = vjust
    ))
  },

  build_decor = function(decor, grobs, elements, params) {
    result <- ggplot2::GuideColourbar$build_decor(
      decor = decor,
      grobs = grobs,
      elements = elements,
      params = params
    )

    zero <- params$zero
    positive_at_high_end <- params$positive_at_high_end
    zero_gap <- 0.012
    below_zero <- max(0, zero - zero_gap / 2)
    above_zero <- min(1, zero + zero_gap / 2)

    if (identical(params$direction, "horizontal")) {
      positive_x <- if (positive_at_high_end) c(above_zero, 1, 1, above_zero) else c(below_zero, 0, 0, below_zero)
      negative_x <- if (positive_at_high_end) c(below_zero, 0, 0, below_zero) else c(above_zero, 1, 1, above_zero)
      positive_y <- negative_y <- c(0, 0, 1, 1)
      zero_band <- grid::rectGrob(
        x = grid::unit(zero, "npc"),
        y = grid::unit(0.5, "npc"),
        width = grid::unit(zero_gap, "npc"),
        height = grid::unit(1, "npc"),
        gp = grid::gpar(col = NA, fill = params$zero_colour)
      )
    } else {
      positive_y <- if (positive_at_high_end) c(above_zero, 1, 1, above_zero) else c(below_zero, 0, 0, below_zero)
      negative_y <- if (positive_at_high_end) c(below_zero, 0, 0, below_zero) else c(above_zero, 1, 1, above_zero)
      positive_x <- negative_x <- c(0, 0, 1, 1)
      zero_band <- grid::rectGrob(
        x = grid::unit(0.5, "npc"),
        y = grid::unit(zero, "npc"),
        width = grid::unit(1, "npc"),
        height = grid::unit(zero_gap, "npc"),
        gp = grid::gpar(col = NA, fill = params$zero_colour)
      )
    }

    outline <- grid::grobTree(
      grid::polylineGrob(
        x = grid::unit(positive_x, "npc"),
        y = grid::unit(positive_y, "npc"),
        gp = grid::gpar(col = "darkblue", lwd = 1, lty = "solid")
      ),
      grid::polylineGrob(
        x = grid::unit(negative_x, "npc"),
        y = grid::unit(negative_y, "npc"),
        gp = grid::gpar(col = "darkred", lwd = 1, lty = "dashed")
      )
    )

    result$frame <- grid::grobTree(result$frame, zero_band, outline)
    result
  }
)

#' @rdname scale_fill_residual
#' @export
scale_fill_residuals <- scale_fill_residual  # Alias for plural form

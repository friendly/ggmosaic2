#' Facet mosaic plots with panel-specific axes
#'
#' `facet_mosaic_grid()` lays panels out like [ggplot2::facet_grid()], but gives
#' every panel its own x and y position scales. Mosaic category breaks depend on
#' the proportions calculated inside a panel, so sharing a position scale can
#' place one panel's ticks and labels on another panel's mosaic.
#'
#' Panel widths and heights remain fixed. By default, axes and their labels are
#' drawn for every panel so that each panel's category positions are visible.
#' The panel-specific label positions are retained with [theme_mosaic()]; that
#' theme intentionally hides the tick marks themselves.
#'
#' @inheritParams ggplot2::facet_grid
#'
#' @return A `Facet` object that can be added to a ggplot.
#' @export
#'
#' @examples
#' facet_data <- expand.grid(
#'   period = factor(c("Before", "After")),
#'   group = factor(c("A", "B")),
#'   response = factor(c("No", "Yes"))
#' )
#' facet_data$n <- c(30, 10, 20, 40, 10, 35, 40, 15)
#'
#' ggplot(facet_data,
#'        aes(weight = n, x = product(response, group), fill = response)) +
#'   geom_mosaic() +
#'   facet_mosaic_grid(cols = vars(period))
facet_mosaic_grid <- function(rows = NULL, cols = NULL, space = "fixed",
                              shrink = TRUE, labeller = "label_value",
                              as.table = TRUE, switch = NULL, drop = TRUE,
                              margins = FALSE, axes = "all",
                              axis.labels = "all") {
  facet <- ggplot2::facet_grid(
    rows = rows,
    cols = cols,
    scales = "fixed",
    space = space,
    shrink = shrink,
    labeller = labeller,
    as.table = as.table,
    switch = switch,
    drop = drop,
    margins = margins,
    axes = axes,
    axis.labels = axis.labels
  )

  ggplot2::ggproto(
    NULL,
    FacetMosaicGrid,
    shrink = facet$shrink,
    params = facet$params
  )
}


# FacetGrid normally shares x scales within columns and y scales within rows.
# Mosaic axes describe panel-specific proportions, so use PANEL for both scale
# identifiers while retaining FacetGrid's physical layout and drawing methods.
FacetMosaicGrid <- ggplot2::ggproto(
  "FacetMosaicGrid",
  ggplot2::FacetGrid,
  compute_layout = function(self, data, params) {
    layout <- ggplot2::ggproto_parent(
      ggplot2::FacetGrid,
      self
    )$compute_layout(data, params)

    panel_scale <- as.integer(layout$PANEL)
    layout$SCALE_X <- panel_scale
    layout$SCALE_Y <- panel_scale
    layout
  },
  attach_axes = function(table, layout, ranges, coord, theme, params) {
    draw_axes <- params$draw_axes %||% list(x = FALSE, y = FALSE)
    axis_labels <- params$axis_labels %||% list(x = TRUE, y = TRUE)
    dimensions <- c(max(layout$ROW), max(layout$COL))

    censor_labels <- getFromNamespace("censor_labels", "ggplot2")
    render_axes <- getFromNamespace("render_axes", "ggplot2")
    weave_axes <- getFromNamespace("weave_axes", "ggplot2")
    zero_grob <- getFromNamespace("zeroGrob", "ggplot2")

    # FacetGrid renders one x axis per column and one y axis per row. Here both
    # directions vary per panel, so render every panel range before arranging
    # the resulting axis grobs in the physical grid.
    ranges <- censor_labels(ranges, layout, axis_labels)
    axes <- render_axes(ranges, ranges, coord, theme, transpose = TRUE)

    axis_matrix <- function(grobs) {
      result <- matrix(
        rep(list(zero_grob()), prod(dimensions)),
        nrow = dimensions[1],
        ncol = dimensions[2]
      )
      result[cbind(layout$ROW, layout$COL)] <-
        grobs[as.integer(layout$PANEL)]
      result
    }

    blank_interior <- function(axis, side) {
      keep <- switch(
        side,
        top = layout$ROW == ave(layout$ROW, layout$COL, FUN = min),
        bottom = layout$ROW == ave(layout$ROW, layout$COL, FUN = max),
        left = layout$COL == ave(layout$COL, layout$ROW, FUN = min),
        right = layout$COL == ave(layout$COL, layout$ROW, FUN = max)
      )
      keep_matrix <- matrix(FALSE, dimensions[1], dimensions[2])
      keep_matrix[cbind(layout$ROW, layout$COL)] <- keep
      axis[!keep_matrix] <- rep(list(zero_grob()), sum(!keep_matrix))
      axis
    }

    x_axes <- lapply(axes$x, axis_matrix)
    y_axes <- lapply(axes$y, axis_matrix)

    if (!draw_axes$x) {
      x_axes$top <- blank_interior(x_axes$top, "top")
      x_axes$bottom <- blank_interior(x_axes$bottom, "bottom")
    }
    if (!draw_axes$y) {
      y_axes$left <- blank_interior(y_axes$left, "left")
      y_axes$right <- blank_interior(y_axes$right, "right")
    }

    table <- weave_axes(table, x_axes)
    weave_axes(table, y_axes)
  }
)

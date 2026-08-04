library(ggmosaic2)

facet_data <- expand.grid(
  response = factor(c("No", "Yes"), levels = c("No", "Yes")),
  segment = factor(c("A", "B", "C"), levels = c("A", "B", "C")),
  column = factor(c("Before", "After"), levels = c("Before", "After")),
  row = factor(c("North", "South"), levels = c("North", "South"))
)

segment_totals <- c(
  "North:Before:A" = 60, "North:Before:B" = 30, "North:Before:C" = 10,
  "North:After:A" = 15, "North:After:B" = 35, "North:After:C" = 50,
  "South:Before:A" = 45, "South:Before:B" = 45, "South:Before:C" = 10,
  "South:After:A" = 25, "South:After:B" = 20, "South:After:C" = 55
)
yes_shares <- c(
  "North:Before:A" = 0.20, "North:Before:B" = 0.45, "North:Before:C" = 0.70,
  "North:After:A" = 0.65, "North:After:B" = 0.30, "North:After:C" = 0.55,
  "South:Before:A" = 0.35, "South:Before:B" = 0.75, "South:Before:C" = 0.25,
  "South:After:A" = 0.80, "South:After:B" = 0.40, "South:After:C" = 0.60
)

profile <- paste(facet_data$row, facet_data$column, facet_data$segment, sep = ":")
total <- unname(segment_totals[profile])
yes <- round(total * unname(yes_shares[profile]))
facet_data$n <- ifelse(facet_data$response == "Yes", yes, total - yes)

facet_plot <- ggplot(facet_data) +
  geom_mosaic(
    aes(weight = n, x = product(response, segment), fill = response)
  ) +
  facet_mosaic_grid(rows = vars(row), cols = vars(column))

facet_build <- ggplot_build(facet_plot)
facet_layout <- facet_build$layout$layout
panel_count <- nrow(facet_layout)

stopifnot(
  panel_count == 4L,
  identical(facet_layout$SCALE_X, seq_len(panel_count)),
  identical(facet_layout$SCALE_Y, seq_len(panel_count)),
  length(facet_build$layout$panel_scales_x) == panel_count,
  length(facet_build$layout$panel_scales_y) == panel_count
)

# Faceting in only one direction must still allocate both scales per panel;
# ordinary facet_grid() would share one of these directions.
for (facet in list(
  facet_mosaic_grid(rows = vars(row)),
  facet_mosaic_grid(cols = vars(column))
)) {
  one_direction_build <- ggplot_build(
    ggplot(facet_data) +
      geom_mosaic(
        aes(weight = n, x = product(response, segment), fill = response)
      ) +
      facet
  )
  one_direction_layout <- one_direction_build$layout$layout
  one_direction_count <- nrow(one_direction_layout)
  stopifnot(
    identical(one_direction_layout$SCALE_X, seq_len(one_direction_count)),
    identical(one_direction_layout$SCALE_Y, seq_len(one_direction_count))
  )
}

# Every break must be the midpoint of the corresponding outer rectangle in
# that panel. Horizontal labels describe segment; vertical labels describe the
# response rectangles touching the left edge.
for (panel in seq_len(panel_count)) {
  panel_data <- facet_build$data[[1]][facet_build$data[[1]]$PANEL == panel, ]

  x_rectangles <- unique(panel_data[c("x__segment", "xmin", "xmax")])
  x_positions <- (x_rectangles$xmin + x_rectangles$xmax) / 2
  x_order <- order(x_positions)
  x_scale <- facet_build$layout$panel_scales_x[[panel]]

  y_rectangles <- panel_data[panel_data$xmin < 1e-6, ]
  response_column <- grep("response$", names(y_rectangles), value = TRUE)[1]
  y_rectangles <- unique(y_rectangles[c(response_column, "ymin", "ymax")])
  y_positions <- (y_rectangles$ymin + y_rectangles$ymax) / 2
  y_order <- order(y_positions)
  y_scale <- facet_build$layout$panel_scales_y[[panel]]

  stopifnot(
    isTRUE(all.equal(x_scale$breaks, x_positions[x_order])),
    identical(x_scale$labels, as.character(x_rectangles$x__segment[x_order])),
    isTRUE(all.equal(y_scale$breaks, y_positions[y_order])),
    identical(
      y_scale$labels,
      as.character(y_rectangles[[response_column]][y_order])
    )
  )
}

x_breaks <- lapply(facet_build$layout$panel_scales_x, `[[`, "breaks")
y_breaks <- lapply(facet_build$layout$panel_scales_y, `[[`, "breaks")
stopifnot(
  length(unique(vapply(
    x_breaks, function(x) paste(x, collapse = ","), character(1)
  ))) == panel_count,
  length(unique(vapply(
    y_breaks, function(x) paste(x, collapse = ","), character(1)
  ))) == panel_count
)

# A factor level with zero panel-local width must not create an orphaned tick
# at the panel boundary. Other panels that contain the level still label it.
missing_level_data <- facet_data[
  !(facet_data$row == "North" & facet_data$column == "Before" &
      facet_data$segment == "C"),
]
missing_level_plot <- ggplot(missing_level_data) +
  geom_mosaic(
    aes(weight = n, x = product(response, segment), fill = response)
  ) +
  facet_mosaic_grid(rows = vars(row), cols = vars(column))
missing_level_build <- ggplot_build(missing_level_plot)
stopifnot(
  identical(
    missing_level_build$layout$panel_scales_x[[1]]$labels,
    c("A", "B")
  ),
  identical(
    missing_level_build$layout$panel_scales_x[[2]]$labels,
    c("A", "B", "C")
  )
)

# The default axes = "all" must result in a rendered bottom and left axis for
# every panel, with the appropriate category labels in every axis grob.
collect_text_labels <- function(grob) {
  labels <- if (inherits(grob, "text")) as.character(grob$label) else character()
  if (!is.null(grob$grobs)) {
    labels <- c(labels, unlist(lapply(grob$grobs, collect_text_labels)))
  }
  if (!is.null(grob$children)) {
    labels <- c(labels, unlist(lapply(grob$children, collect_text_labels)))
  }
  labels
}

collect_text_grobs <- function(grob) {
  result <- if (inherits(grob, "text")) list(grob) else list()
  if (!is.null(grob$grobs)) {
    result <- c(
      result,
      unlist(lapply(grob$grobs, collect_text_grobs), recursive = FALSE)
    )
  }
  if (!is.null(grob$children)) {
    result <- c(
      result,
      unlist(lapply(grob$children, collect_text_grobs), recursive = FALSE)
    )
  }
  result
}

axis_label_positions <- function(gtable, axis_name, labels, direction) {
  axis_index <- which(gtable$layout$name == axis_name)
  stopifnot(length(axis_index) == 1L)
  text_grobs <- collect_text_grobs(gtable$grobs[[axis_index]])
  label_grobs <- Filter(
    function(grob) identical(as.character(grob$label), labels),
    text_grobs
  )
  stopifnot(length(label_grobs) == 1L)
  position <- if (direction == "x") label_grobs[[1]]$x else label_grobs[[1]]$y
  as.numeric(position)
}

facet_grob <- ggplotGrob(facet_plot)
bottom_index <- grep("^axis-b-", facet_grob$layout$name)
left_index <- grep("^axis-l-", facet_grob$layout$name)
bottom_labels <- lapply(facet_grob$grobs[bottom_index], collect_text_labels)
left_labels <- lapply(facet_grob$grobs[left_index], collect_text_labels)

stopifnot(
  length(bottom_index) == panel_count,
  length(left_index) == panel_count,
  all(vapply(
    bottom_labels,
    function(labels) all(levels(facet_data$segment) %in% labels),
    logical(1)
  )),
  all(vapply(
    left_labels,
    function(labels) all(levels(facet_data$response) %in% labels),
    logical(1)
  ))
)

# Check the coordinates of the rendered labels, not only the scale metadata.
# FacetGrid's default renderer reuses x axes by column and y axes by row, which
# is the rendering bug this facet must override. theme_mosaic() blanks ticks,
# so label coordinates are the stable assertion for both themes.
for (themed_plot in list(facet_plot, facet_plot + theme_mosaic())) {
  themed_build <- ggplot_build(themed_plot)
  themed_grob <- ggplotGrob(themed_plot)

  for (panel in seq_len(panel_count)) {
    panel_row <- facet_layout$ROW[panel]
    panel_col <- facet_layout$COL[panel]
    x_labels <- themed_build$layout$panel_scales_x[[panel]]$labels
    y_labels <- themed_build$layout$panel_scales_y[[panel]]$labels

    rendered_x <- axis_label_positions(
      themed_grob,
      paste0("axis-b-", panel_col, "-", panel_row),
      x_labels,
      "x"
    )
    rendered_y <- axis_label_positions(
      themed_grob,
      paste0("axis-l-", panel_row, "-", panel_col),
      y_labels,
      "y"
    )

    expected_x <- themed_build$layout$panel_params[[panel]]$x$break_positions()
    expected_y <- themed_build$layout$panel_params[[panel]]$y$break_positions()
    stopifnot(
      isTRUE(all.equal(rendered_x, expected_x, tolerance = 1e-10)),
      isTRUE(all.equal(rendered_y, expected_y, tolerance = 1e-10))
    )
  }
}

# Multiple mosaic-derived layers train a panel scale with identical metadata.
text_plot <- facet_plot +
  geom_mosaic_text(
    aes(weight = n, x = product(response, segment)),
    size = 2
  )
text_build <- ggplot_build(text_plot)

stopifnot(
  length(text_build$data) == 2L,
  length(text_build$layout$panel_scales_x) == panel_count,
  length(text_build$layout$panel_scales_y) == panel_count
)

# Coordinate flipping and manual product-scale labels continue to build.
stopifnot(inherits(ggplotGrob(facet_plot + coord_flip()), "gtable"))
stopifnot(inherits(ggplotGrob(
  facet_plot +
    facet_mosaic_grid(
      rows = vars(row), cols = vars(column), axes = "margins"
    )
), "gtable"))

manual_plot <- ggplot(facet_data[facet_data$row == "North", ]) +
  geom_mosaic(aes(weight = n, x = product(response, segment))) +
  scale_x_productlist(
    breaks = c(0.2, 0.5, 0.8),
    labels = c("first", "second", "third")
  ) +
  facet_mosaic_grid(cols = vars(column))
manual_build <- ggplot_build(manual_plot)
stopifnot(all(vapply(
  manual_build$layout$panel_scales_x,
  function(scale) identical(scale$labels, c("first", "second", "third")),
  logical(1)
)))

# Residual shading keeps its computed values and sign-dependent outlines while
# using a separate pair of product scales in each facet.
residual_data <- as.data.frame(HairEyeColor)
residual_plot <- ggplot(residual_data) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye)),
    expected = "independence"
  ) +
  scale_fill_residual() +
  facet_mosaic_grid(cols = vars(Sex))
residual_build <- ggplot_build(residual_plot)
residual_layer <- residual_build$data[[1]]

stopifnot(
  length(residual_build$layout$panel_scales_x) == 2L,
  length(residual_build$layout$panel_scales_y) == 2L,
  any(residual_layer$.residual > 0),
  any(residual_layer$.residual < 0),
  all(residual_layer$colour[residual_layer$.residual > 0] == "darkblue"),
  all(residual_layer$linetype[residual_layer$.residual < 0] == "dashed")
)

library(ggmosaic2)

limited_scale <- scale_fill_residual(limits = c(-3, 5))
limited_scale$train(c(-6, -1, 2, 8))

limited_breaks <- ggmosaic2:::residual_legend_breaks(limited_scale)
limited_labels <- ggmosaic2:::residual_legend_labels(limited_scale, limited_breaks)
limited_guide <- limited_scale$guide$train(scale = limited_scale, aesthetic = "fill")

stopifnot(
  inherits(limited_scale$guide, "GuideResidual"),
  identical(limited_breaks, c(-6, -4, -3, 0, 4, 5, 8)),
  identical(
    limited_labels,
    c("-6.0", "-4.0", "-3.0", "0.0", "+4.0", "+5.0", "+8.0")
  ),
  identical(range(limited_guide$decor$value), c(-6, 8)),
  all(limited_guide$decor$colour[limited_guide$decor$value < -3] == limited_scale$map(-3)),
  all(limited_guide$decor$colour[limited_guide$decor$value > 5] == limited_scale$map(5)),
  identical(limited_scale$map(-6), limited_scale$map(-3)),
  identical(limited_scale$map(8), limited_scale$map(5)),
  identical(limited_scale$guide$params$theme$legend.ticks$colour, "black")
)

automatic_scale <- scale_fill_residual()
automatic_scale$train(c(-6, 8))
stopifnot(
  identical(
    ggmosaic2:::residual_legend_breaks(automatic_scale),
    c(-6, -4, 0, 4, 8)
  )
)

coincident_scale <- scale_fill_residual(limits = c(-4, 4))
coincident_scale$train(c(-4, 4))
stopifnot(
  identical(
    ggmosaic2:::residual_legend_breaks(coincident_scale),
    c(-4, 0, 4)
  )
)

custom_oob <- scale_fill_residual(
  limits = c(-3, 5),
  oob = scales::oob_censor
)
custom_oob$train(c(-6, 8))
stopifnot(
  identical(custom_oob$map(-6), "grey50"),
  identical(custom_oob$map(8), "grey50")
)

no_guide_scale <- scale_fill_residual(guide = "none")
stopifnot(identical(no_guide_scale$guide, "none"))

legend_data <- as.data.frame(HairEyeColor)
legend_plot <- ggplot(legend_data) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye, Sex)),
    expected = "independence"
  ) +
  scale_fill_residual(limits = c(-3, 5))

legend_build <- ggplot_build(legend_plot)
legend_scale <- legend_build$plot$scales$get_scales("fill")
legend_guide <- legend_scale$guide$train(scale = legend_scale, aesthetic = "fill")
visible_gtable <- ggplotGrob(legend_plot)
visible_guides <- grep("guide-box", visible_gtable$layout$name)
stopifnot(
  any(vapply(
    visible_gtable$grobs[visible_guides],
    function(grob) inherits(grob, "gtable"),
    logical(1)
  ))
)

collect_grobs <- function(grob) {
  result <- list(grob)
  if (!is.null(grob$grobs)) {
    result <- c(
      result,
      unlist(lapply(grob$grobs, collect_grobs), recursive = FALSE)
    )
  }
  if (!is.null(grob$children)) {
    result <- c(
      result,
      unlist(lapply(grob$children, collect_grobs), recursive = FALSE)
    )
  }
  result
}

visible_guide <- visible_gtable$grobs[
  visible_guides[vapply(
    visible_gtable$grobs[visible_guides],
    function(grob) inherits(grob, "gtable"),
    logical(1)
  )]
][[1]]
guide_grobs <- collect_grobs(visible_guide)
guide_lines <- Filter(function(grob) inherits(grob, "polyline"), guide_grobs)
guide_rects <- Filter(function(grob) inherits(grob, "rect"), guide_grobs)
line_colours <- vapply(guide_lines, function(grob) grob$gp$col, character(1))
line_types <- vapply(
  guide_lines,
  function(grob) if (is.null(grob$gp$lty)) "" else as.character(grob$gp$lty),
  character(1)
)
blue_outline <- guide_lines[[which(line_colours == "darkblue")[1]]]
red_outline <- guide_lines[[which(line_colours == "darkred")[1]]]
white_band <- vapply(guide_rects, function(grob) {
  identical(grob$gp$fill, "#FFFFFFFF") && is.na(grob$gp$col)
}, logical(1))
guide_tables <- Filter(function(grob) inherits(grob, "gtable"), guide_grobs)
has_stretching_height <- vapply(guide_tables, function(grob) {
  any(grid::unitType(grob$heights) == "null")
}, logical(1))
label_positions <- ggmosaic2:::residual_legend_label_positions(
  legend_guide$key$.value,
  "vertical"
)
labels_moved <- abs(label_positions - legend_guide$key$.value) >
  sqrt(.Machine$double.eps)
vertical_long_ticks <- ggmosaic2:::residual_legend_long_ticks(
  legend_guide$key$.value,
  "vertical"
)
guide_text <- Filter(function(grob) inherits(grob, "text"), guide_grobs)
numeric_labels <- guide_text[[which(vapply(
  guide_text,
  function(grob) length(grob$label) == nrow(legend_guide$key),
  logical(1)
))[1]]]
black_lines <- guide_lines[line_colours == "black"]
black_ticks <- black_lines[[which(vapply(
  black_lines,
  function(grob) length(grob$x) == 2 * nrow(legend_guide$key),
  logical(1)
))[1]]]
black_leaders <- black_lines[[which(vapply(
  black_lines,
  function(grob) length(grob$x) == 4 * sum(labels_moved),
  logical(1)
))[1]]]
minimum <- which.min(legend_guide$key$.value)
minus_four <- which(legend_guide$key$.label == "-4.0")
leader_label_positions <- as.numeric(black_leaders$y)[
  seq(4, length(black_leaders$y), by = 4)
]
vertical_tick_ends <- format(black_ticks$x)[
  seq(2, length(black_ticks$x), by = 2)
]

stopifnot(
  any(line_colours == "darkblue" & line_types == "solid"),
  any(line_colours == "darkred" & line_types == "dashed"),
  max(as.numeric(red_outline$y)) < min(as.numeric(blue_outline$y)),
  any(white_band),
  length(black_ticks$x) == 2 * nrow(legend_guide$key),
  length(black_leaders$x) == 4 * sum(labels_moved),
  sum(line_colours == "black") == 2,
  labels_moved[minus_four],
  !labels_moved[minimum],
  !vertical_long_ticks[minus_four],
  vertical_long_ticks[minimum],
  isTRUE(all.equal(as.numeric(numeric_labels$y), label_positions)),
  isTRUE(all.equal(leader_label_positions, label_positions[labels_moved])),
  grepl("0.15cm", vertical_tick_ends[minus_four], fixed = TRUE),
  grepl("0.45cm", vertical_tick_ends[minimum], fixed = TRUE),
  format(numeric_labels$x)[minus_four] == "0.6cm",
  format(numeric_labels$x)[minimum] == "0.6cm",
  identical(
    format(numeric_labels$x)[minus_four],
    format(numeric_labels$x)[minimum]
  ),
  any(has_stretching_height)
)

no_outline_plot <- ggplot(legend_data) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye, Sex)),
    expected = "independence",
    color = NA
  ) +
  scale_fill_residual()
no_outline_build <- ggplot_build(no_outline_plot)
no_outline_gtable <- ggplotGrob(no_outline_plot)
no_outline_guides <- grep("guide-box", no_outline_gtable$layout$name)
no_outline_guide <- no_outline_gtable$grobs[
  no_outline_guides[vapply(
    no_outline_gtable$grobs[no_outline_guides],
    function(grob) inherits(grob, "gtable"),
    logical(1)
  )]
][[1]]
no_outline_lines <- Filter(
  function(grob) inherits(grob, "polyline"),
  collect_grobs(no_outline_guide)
)
no_outline_line_colours <- vapply(
  no_outline_lines,
  function(grob) grob$gp$col,
  character(1)
)

stopifnot(
  all(is.na(no_outline_build$data[[1]]$colour)),
  all(c("darkblue", "darkred") %in% no_outline_line_colours),
  any(no_outline_line_colours == "black")
)

hidden_gtable <- ggplotGrob(
  legend_plot + theme(legend.position = "none")
)
hidden_guides <- grep("guide-box", hidden_gtable$layout$name)
stopifnot(
  all(vapply(
    hidden_gtable$grobs[hidden_guides],
    function(grob) inherits(grob, "zeroGrob"),
    logical(1)
  ))
)

layer_hidden_gtable <- ggplotGrob(
  ggplot(legend_data) +
    geom_mosaic(
      aes(weight = Freq, x = product(Hair, Eye, Sex)),
      expected = "independence",
      show.legend = FALSE
    ) +
    scale_fill_residual()
)
layer_hidden_guides <- grep("guide-box", layer_hidden_gtable$layout$name)
stopifnot(
  all(vapply(
    layer_hidden_gtable$grobs[layer_hidden_guides],
    function(grob) inherits(grob, "zeroGrob"),
    logical(1)
  ))
)

# A horizontal guide keeps the elbow for a displaced label and gives its
# stationary neighbour a longer straight tick and a farther label row.
bottom_gtable <- ggplotGrob(
  legend_plot + theme(legend.position = "bottom")
)
bottom_guides <- grep("guide-box", bottom_gtable$layout$name)
bottom_guide <- bottom_gtable$grobs[
  bottom_guides[vapply(
    bottom_gtable$grobs[bottom_guides],
    function(grob) inherits(grob, "gtable"),
    logical(1)
  )]
][[1]]
bottom_grobs <- collect_grobs(bottom_guide)
bottom_lines <- Filter(function(grob) inherits(grob, "polyline"), bottom_grobs)
bottom_black_lines <- bottom_lines[vapply(
  bottom_lines,
  function(grob) identical(grob$gp$col, "black"),
  logical(1)
)]
bottom_ticks <- bottom_black_lines[[which(vapply(
  bottom_black_lines,
  function(grob) length(grob$x) == 2 * nrow(legend_guide$key),
  logical(1)
))[1]]]
bottom_text <- Filter(function(grob) inherits(grob, "text"), bottom_grobs)
bottom_numeric_labels <- bottom_text[[which(vapply(
  bottom_text,
  function(grob) length(grob$label) == nrow(legend_guide$key),
  logical(1)
))[1]]]
horizontal_positions <- ggmosaic2:::residual_legend_label_positions(
  legend_guide$key$.value,
  "horizontal"
)
horizontal_moved <- abs(horizontal_positions - legend_guide$key$.value) >
  sqrt(.Machine$double.eps)
bottom_leaders <- bottom_black_lines[[which(vapply(
  bottom_black_lines,
  function(grob) length(grob$x) == 4 * sum(horizontal_moved),
  logical(1)
))[1]]]
horizontal_long_ticks <- ggmosaic2:::residual_legend_long_ticks(
  legend_guide$key$.value,
  "horizontal"
)
bottom_tick_ends <- format(bottom_ticks$y)[
  seq(2, length(bottom_ticks$y), by = 2)
]

stopifnot(
  horizontal_moved[minus_four],
  !horizontal_moved[minimum],
  !horizontal_long_ticks[minus_four],
  horizontal_long_ticks[minimum],
  isTRUE(all.equal(
    as.numeric(bottom_numeric_labels$x),
    horizontal_positions
  )),
  length(bottom_leaders$x) == 4 * sum(horizontal_moved),
  grepl("0.15cm", bottom_tick_ends[minus_four], fixed = TRUE),
  grepl("0.45cm", bottom_tick_ends[minimum], fixed = TRUE),
  grepl("0.6cm", format(bottom_numeric_labels$y)[minus_four], fixed = TRUE),
  grepl("0.6cm", format(bottom_numeric_labels$y)[minimum], fixed = TRUE),
  identical(
    format(bottom_numeric_labels$y)[minus_four],
    format(bottom_numeric_labels$y)[minimum]
  )
)

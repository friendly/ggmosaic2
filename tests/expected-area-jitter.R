library(ggmosaic2)

hec <- as.data.frame(HairEyeColor)

# With no gaps, expected-area rectangles occupy exactly the fitted share of
# the unit square while observed counts and residuals remain unchanged.
expected_result <- prodcalc(
  hec,
  Freq ~ Hair + Eye + Sex,
  expected = "independence",
  area = "expected",
  offset = 0
)
expected_cells <- subset(expected_result, level == max(level))
expected_cell_area <- with(expected_cells, (r - l) * (t - b))

observed_result <- prodcalc(
  hec,
  Freq ~ Hair + Eye + Sex,
  expected = "independence",
  area = "observed",
  offset = 0
)
observed_cells <- subset(observed_result, level == max(level))

stopifnot(
  isTRUE(all.equal(
    expected_cell_area,
    expected_cells$.expected / sum(expected_cells$.expected),
    tolerance = 1e-8
  )),
  identical(expected_cells$.n, observed_cells$.n),
  isTRUE(all.equal(expected_cells$.expected, observed_cells$.expected)),
  isTRUE(all.equal(expected_cells$.residual, observed_cells$.residual)),
  !isTRUE(all.equal(
    expected_cells[c("l", "r", "b", "t")],
    observed_cells[c("l", "r", "b", "t")]
  ))
)

# The observed-area default remains equivalent to an explicit selection.
default_result <- prodcalc(hec, Freq ~ Hair + Eye + Sex, offset = 0)
explicit_observed <- prodcalc(
  hec, Freq ~ Hair + Eye + Sex, area = "observed", offset = 0
)
stopifnot(isTRUE(all.equal(default_result, explicit_observed)))

missing_model_error <- tryCatch(
  prodcalc(hec, Freq ~ Hair + Eye, area = "expected"),
  error = conditionMessage
)
stopifnot(grepl("requires a non-NULL `expected`", missing_model_error, fixed = TRUE))

# The preferred API is one layer whose computed cell data contains observed
# counts, fitted counts, and expected-area geometry.
integrated_plot <- ggplot(hec) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye, Sex)),
    expected = "independence",
    area = "expected",
    offset = 0,
    jitter = TRUE,
    jitter_mapping = aes(colour = Hair),
    jitter_size = 2,
    jitter_alpha = 0.8,
    seed = 123
  ) +
  scale_fill_residual()
integrated_build <- ggplot_build(integrated_plot)
integrated_cells <- integrated_build$data[[1]]
stopifnot(
  length(integrated_plot$layers) == 1L,
  nrow(integrated_cells) == nrow(hec),
  all(c(".n", ".expected", ".residual") %in% names(integrated_cells)),
  length(unique(integrated_cells$colour)) == length(unique(hec$Hair))
)

# Rendering produces exactly the observed total, even though expected counts
# determined the rectangles.
collect_expected_grobs <- function(grob) {
  result <- list(grob)
  if (!is.null(grob$grobs)) {
    result <- c(
      result,
      unlist(lapply(grob$grobs, collect_expected_grobs), recursive = FALSE)
    )
  }
  if (!is.null(grob$children)) {
    result <- c(
      result,
      unlist(lapply(grob$children, collect_expected_grobs), recursive = FALSE)
    )
  }
  result
}

integrated_grobs <- collect_expected_grobs(ggplotGrob(integrated_plot))
point_grobs <- Filter(function(grob) inherits(grob, "points"), integrated_grobs)
point_counts <- vapply(point_grobs, function(grob) length(grob$x), integer(1))
stopifnot(sum(hec$Freq) %in% point_counts)

# The compatibility jitter layer accepts the same model/layout arguments and
# derives the same cell boundaries when users deliberately choose two layers.
compatibility_plot <- ggplot(hec) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye, Sex)),
    expected = "independence", area = "expected", offset = 0
  ) +
  geom_mosaic_jitter(
    aes(weight = Freq, x = product(Hair, Eye, Sex), colour = Hair),
    expected = "independence", area = "expected", offset = 0, seed = 123
  )
compatibility_build <- ggplot_build(compatibility_plot)
tile_geometry <- compatibility_build$data[[1]][
  c("label", "xmin", "xmax", "ymin", "ymax")
]
point_geometry <- unique(compatibility_build$data[[2]][
  c("label", "xmin", "xmax", "ymin", "ymax")
])
tile_geometry <- tile_geometry[order(tile_geometry$label), ]
point_geometry <- point_geometry[order(point_geometry$label), ]
rownames(tile_geometry) <- NULL
rownames(point_geometry) <- NULL
stopifnot(
  isTRUE(all.equal(tile_geometry, point_geometry)),
  nrow(compatibility_build$data[[2]]) == sum(hec$Freq)
)

# Point mappings cannot silently add a new partition to the integrated layout.
invalid_mapping <- tryCatch(
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye)),
    jitter = TRUE,
    jitter_mapping = aes(colour = Sex)
  ),
  error = conditionMessage
)
stopifnot(grepl("must also appear", invalid_mapping, fixed = TRUE))

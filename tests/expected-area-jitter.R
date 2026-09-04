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

# Shared settings coordinate two independent layers. Expected counts determine
# both layouts, while observed counts determine the number of points.
expected_jitter_plot <- ggplot(
  hec,
  aes(weight = Freq, x = product(Hair, Eye, Sex))
) +
  mosaic_settings(expected = "independence", area = "expected", offset = 0) +
  geom_mosaic() +
  geom_mosaic_jitter(aes(colour = Hair), seed = 123)
expected_jitter_build <- ggplot_build(expected_jitter_plot)
tile_geometry <- expected_jitter_build$data[[1]][
  c("label", "xmin", "xmax", "ymin", "ymax")
]
point_geometry <- unique(expected_jitter_build$data[[2]][
  c("label", "xmin", "xmax", "ymin", "ymax")
])
tile_geometry <- tile_geometry[order(tile_geometry$label), ]
point_geometry <- point_geometry[order(point_geometry$label), ]
rownames(tile_geometry) <- NULL
rownames(point_geometry) <- NULL
stopifnot(
  isTRUE(all.equal(tile_geometry, point_geometry)),
  nrow(expected_jitter_build$data[[2]]) == sum(hec$Freq),
  identical(unique(expected_jitter_build$data[[1]]$fill), "grey55"),
  all(c(".expected", ".residual") %in%
        names(expected_jitter_build$data[[1]])),
  all(c(".expected", ".residual") %in%
        names(expected_jitter_build$data[[2]]))
)

# Adding the residual scale changes fill, not geometry or point counts.
shaded_build <- ggplot_build(expected_jitter_plot + scale_fill_residual())
stopifnot(
  length(unique(shaded_build$data[[1]]$fill)) > 1L,
  isTRUE(all.equal(
    expected_jitter_build$data[[1]][c("xmin", "xmax", "ymin", "ymax")],
    shaded_build$data[[1]][c("xmin", "xmax", "ymin", "ymax")]
  )),
  nrow(shaded_build$data[[2]]) == sum(hec$Freq)
)

# A model setting is ignored by observed-area jitter, avoiding an unnecessary
# fit. The same setting is consumed when area is expected.
observed_jitter <- ggplot_build(
  ggplot(hec, aes(weight = Freq, x = product(Hair, Eye, Sex))) +
    mosaic_settings(expected = "independence") +
    geom_mosaic_jitter(seed = 123)
)
stopifnot(
  !".expected" %in% names(observed_jitter$data[[1]]),
  !".residual" %in% names(observed_jitter$data[[1]])
)

# weight2 controls point counts without changing expected-area geometry.
hec$PointFreq <- hec$Freq / 2
weight2_build <- ggplot_build(
  ggplot(
    hec,
    aes(
      weight = Freq,
      weight2 = PointFreq,
      x = product(Hair, Eye, Sex)
    )
  ) +
    mosaic_settings(expected = "independence", area = "expected", offset = 0) +
    geom_mosaic_jitter(seed = 123)
)
stopifnot(nrow(weight2_build$data[[1]]) == sum(round(hec$PointFreq)))

# A zero observed cell can retain positive expected area while contributing no
# points, provided its row and column margins remain estimable.
sparse <- expand.grid(A = c("a", "b"), B = c("x", "y"))
sparse$Freq <- c(0, 4, 3, 2)
sparse_result <- prodcalc(
  sparse,
  Freq ~ A + B,
  expected = "independence",
  area = "expected",
  offset = 0
)
sparse_cells <- subset(sparse_result, level == max(level))
zero_cell <- sparse_cells[sparse_cells$.n == 0, ]
stopifnot(
  nrow(zero_cell) == 1L,
  zero_cell$.expected > 0,
  (zero_cell$r - zero_cell$l) * (zero_cell$t - zero_cell$b) > 0
)
sparse_jitter <- ggplot_build(
  ggplot(sparse, aes(weight = Freq, x = product(A, B))) +
    mosaic_settings(expected = "independence", area = "expected", offset = 0) +
    geom_mosaic_jitter(seed = 123)
)
stopifnot(nrow(sparse_jitter$data[[1]]) == sum(sparse$Freq))

# The rejected integrated-jitter API is not part of geom_mosaic().
stopifnot(!any(c(
  "jitter", "jitter_mapping", "jitter_size", "jitter_alpha", "seed"
) %in% names(formals(geom_mosaic))))

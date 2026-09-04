library(ggmosaic2)

hec <- as.data.frame(HairEyeColor)
base <- ggplot(
  hec,
  aes(weight = Freq, x = product(Hair, Eye, Sex))
)

# Fitting a model computes residuals but leaves tile fill neutral.
neutral <- ggplot_build(
  base +
    mosaic_settings(expected = "independence") +
    geom_mosaic()
)
stopifnot(
  all(c(".expected", ".residual") %in% names(neutral$data[[1]])),
  identical(unique(neutral$data[[1]]$fill), "grey55"),
  all(is.na(neutral$data[[1]]$colour)),
  is.null(neutral$plot$scales$get_scales("fill")),
  !"residual_fill" %in% names(formals(geom_mosaic))
)

# The explicit residual scale activates the computed fill mapping.
shaded <- ggplot_build(
  base +
    mosaic_settings(expected = "independence") +
    geom_mosaic() +
    scale_fill_residual()
)
stopifnot(
  length(unique(shaded$data[[1]]$fill)) > 1L,
  all(shaded$data[[1]]$colour[shaded$data[[1]]$.residual > 0] == "darkblue"),
  all(shaded$data[[1]]$colour[shaded$data[[1]]$.residual < 0] == "darkred"),
  !is.null(shaded$plot$scales$get_scales("fill"))
)

# An explicit residual mapping is accepted and remains compatible with the
# specialized scale.
explicit_residual <- ggplot_build(
  base +
    geom_mosaic(
      aes(fill = after_stat(.residual)),
      expected = "independence"
    ) +
    scale_fill_residual()
)
stopifnot(length(unique(explicit_residual$data[[1]]$fill)) > 1L)

expected_mapping_error <- paste(
  "`scale_fill_residual()` cannot be used with the explicit fill mapping",
  "in `geom_mosaic()`. Remove `aes(fill = ...)` to shade by residuals, or",
  "remove `scale_fill_residual()` to retain the mapped fill.",
  sep = "\n"
)

mapping_conflicts <- list(
  base +
    aes(fill = Hair) +
    geom_mosaic(expected = "independence") +
    scale_fill_residual(),
  base +
    geom_mosaic(aes(fill = Hair), expected = "independence") +
    scale_fill_residual(),
  base +
    geom_mosaic(aes(fill = as.numeric(Hair)), expected = "independence") +
    scale_fill_residual()
)
for (plot in mapping_conflicts) {
  message <- tryCatch(ggplot_build(plot), error = conditionMessage)
  stopifnot(grepl(expected_mapping_error, message, fixed = TRUE))
}

# Without the residual scale, an ordinary fill mapping retains its historical
# structural and styling role.
ordinary_fill <- ggplot_build(
  base + geom_mosaic(aes(fill = Hair), expected = "independence")
)
stopifnot(length(unique(ordinary_fill$data[[1]]$fill)) > 1L)

fixed_message <- tryCatch(
  ggplot_build(
    base +
      geom_mosaic(expected = "independence", fill = "grey90") +
      scale_fill_residual()
  ),
  error = conditionMessage
)
stopifnot(grepl(
  "`scale_fill_residual()` cannot be used with a fixed fill",
  fixed_message,
  fixed = TRUE
))

# Every residual-shaded mosaic layer in a plot must use residual-compatible
# fill semantics.
multiple_layer_message <- tryCatch(
  ggplot_build(
    base +
      geom_mosaic(expected = "independence") +
      geom_mosaic(aes(fill = Hair), expected = "independence") +
      scale_fill_residual()
  ),
  error = conditionMessage
)
stopifnot(grepl(expected_mapping_error, multiple_layer_message, fixed = TRUE))

# Asking for the computed residual explicitly still requires a fitted model.
missing_model_message <- tryCatch(
  ggplot_build(
    base + geom_mosaic(aes(fill = after_stat(.residual)))
  ),
  error = conditionMessage
)
stopifnot(grepl(
  "requires a non-NULL effective `expected` model",
  missing_model_message,
  fixed = TRUE
))

missing_scale_model_message <- tryCatch(
  ggplot_build(base + geom_mosaic() + scale_fill_residual()),
  error = conditionMessage
)
stopifnot(grepl(
  "`scale_fill_residual()` requires a non-NULL effective `expected` model",
  missing_scale_model_message,
  fixed = TRUE
))

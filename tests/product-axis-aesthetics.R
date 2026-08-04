library(ggmosaic2)

build_without_warnings <- function(plot) {
  plot_warnings <- character()
  built <- withCallingHandlers(
    ggplot_build(plot),
    warning = function(warning) {
      plot_warnings <<- c(plot_warnings, conditionMessage(warning))
      invokeRestart("muffleWarning")
    }
  )
  stopifnot(length(plot_warnings) == 0L)
  built
}

axis_text <- function(build) {
  value_text <- function(value) {
    if (is.null(value) || inherits(value, "waiver") || !is.atomic(value)) {
      return(character())
    }
    as.character(value)
  }

  result <- character()
  for (direction in c("x", "y")) {
    scale <- build$layout[[paste0("panel_scales_", direction)]][[1]]
    result <- c(
      result,
      value_text(scale$product_name),
      value_text(scale$name),
      value_text(scale$labels),
      value_text(scale$secondary.axis$name),
      value_text(scale$secondary.axis$labels)
    )
  }
  result
}

stopifnot_absent <- function(values, patterns) {
  stopifnot(!any(vapply(
    patterns,
    function(pattern) any(grepl(pattern, values, fixed = TRUE)),
    logical(1)
  )))
}

# Issue #39: fill participates in the product calculation, but a variable that
# is mapped only to fill must not appear on a position axis.
set.seed(19790801)
actual <- iris$Species
predictions <- sample(iris$Species)
confusion <- as.data.frame(table(actual, predictions))
confusion$is_correct <- ifelse(
  confusion$actual == confusion$predictions,
  "Correct prediction",
  "Incorrect prediction"
)

issue_plot <- ggplot(confusion) +
  geom_mosaic(
    aes(
      weight = Freq,
      x = product(actual, predictions),
      fill = is_correct
    )
  )
issue_build <- build_without_warnings(issue_plot)
issue_axes <- axis_text(issue_build)

stopifnot_absent(
  issue_axes,
  c("is_correct", "Correct prediction", "Incorrect prediction")
)
stopifnot(
  identical(
    issue_build$layout$panel_scales_x[[1]]$labels,
    levels(confusion$predictions)
  ),
  identical(
    issue_build$layout$panel_scales_y[[1]]$labels,
    levels(confusion$actual)
  )
)

# Axis filtering must not remove the historical fill partition or its mapped
# values. The issue table has two possible fill levels in each of nine cells,
# with exactly one positive-frequency level per cell.
issue_data <- issue_build$data[[1]]
stopifnot(
  nrow(issue_data) == 18L,
  sum(issue_data$.n > 0) == 9L,
  setequal(
    unique(issue_data$.mosaic_fill),
    c("Correct prediction", "Incorrect prediction")
  ),
  length(unique(issue_data$fill)) == 2L
)

# Reversing product order changes which explicit variable is horizontal; the
# fill-only variable remains absent from both axes.
swapped_build <- build_without_warnings(
  ggplot(confusion) +
    geom_mosaic(
      aes(
        weight = Freq,
        x = product(predictions, actual),
        fill = is_correct
      )
    )
)
stopifnot(
  identical(
    swapped_build$layout$panel_scales_x[[1]]$labels,
    levels(confusion$actual)
  ),
  identical(
    swapped_build$layout$panel_scales_y[[1]]$labels,
    levels(confusion$predictions)
  )
)
stopifnot_absent(
  axis_text(swapped_build),
  c("is_correct", "Correct prediction", "Incorrect prediction")
)

# If the fill expression is also explicitly present in product(), it remains
# eligible for a position axis.
explicit_fill_build <- build_without_warnings(
  ggplot(confusion) +
    geom_mosaic(
      aes(
        weight = Freq,
        x = product(is_correct, actual),
        fill = is_correct
      )
    )
)
stopifnot(
  "is_correct" %in% axis_text(explicit_fill_build),
  all(c("Correct prediction", "Incorrect prediction") %in%
        axis_text(explicit_fill_build))
)

# A direction split only by an aesthetic-only variable is blank, rather than
# displaying fill categories or fallback 0-to-1 ticks.
one_axis_build <- build_without_warnings(
  ggplot(confusion) +
    geom_mosaic(
      aes(weight = Freq, x = product(actual), fill = is_correct)
    )
)
stopifnot(
  identical(
    one_axis_build$layout$panel_scales_x[[1]]$labels,
    levels(confusion$actual)
  ),
  length(one_axis_build$layout$panel_scales_y[[1]]$breaks) == 0L,
  length(one_axis_build$layout$panel_scales_y[[1]]$labels) == 0L
)

# Transformed fill and alpha expressions use safe internal columns, remain in
# the tile calculation, and stay off the product axes.
transformed_fill_build <- build_without_warnings(
  ggplot(confusion) +
    geom_mosaic(
      aes(
        weight = Freq,
        x = product(actual, predictions),
        fill = factor(is_correct)
      )
    )
)
stopifnot_absent(
  axis_text(transformed_fill_build),
  c("factor(is_correct)", "Correct prediction", "Incorrect prediction")
)

alpha_build <- build_without_warnings(
  ggplot(confusion) +
    geom_mosaic(
      aes(
        weight = Freq,
        x = product(actual, predictions),
        alpha = as.numeric(is_correct == "Correct prediction")
      )
    ) +
    scale_alpha_manual(values = c("0" = 0.4, "1" = 1))
)
stopifnot_absent(
  axis_text(alpha_build),
  c("as.numeric(is_correct == \"Correct prediction\")")
)

# Jitter colour follows the same rule. It still maps both colour values and
# generates one point per input observation.
point_data <- data.frame(
  actual = actual,
  predictions = predictions,
  is_correct = ifelse(
    actual == predictions,
    "Correct prediction",
    "Incorrect prediction"
  )
)
jitter_build <- build_without_warnings(
  ggplot(point_data) +
    geom_mosaic_jitter(
      aes(x = product(actual, predictions), colour = is_correct),
      seed = 1
    )
)
stopifnot(
  nrow(jitter_build$data[[1]]) == nrow(point_data),
  length(unique(jitter_build$data[[1]]$colour)) == 2L
)
stopifnot_absent(
  axis_text(jitter_build),
  c("is_correct", "Correct prediction", "Incorrect prediction")
)

# Legitimate inner product variables continue to use the automatic secondary
# axes even when an aesthetic-only fill partition is also present.
multi_data <- expand.grid(
  a = factor(c("a1", "a2")),
  b = factor(c("b1", "b2")),
  c = factor(c("c1", "c2"))
)
multi_data$flag <- ifelse(multi_data$a == "a1", "F1", "F2")
multi_data$n <- 1
multi_build <- build_without_warnings(
  ggplot(multi_data) +
    geom_mosaic(
      aes(weight = n, x = product(a, b, c), fill = flag)
    )
)
multi_x <- multi_build$layout$panel_scales_x[[1]]
stopifnot(
  identical(multi_x$product_name, "c"),
  identical(multi_x$secondary.axis$name, "a"),
  all(levels(multi_data$a) %in% multi_x$secondary.axis$labels)
)
stopifnot_absent(axis_text(multi_build), c("flag", "F1", "F2"))

# The existing NULL control still suppresses an otherwise legitimate automatic
# secondary axis.
no_secondary_build <- build_without_warnings(
  ggplot(multi_data) +
    geom_mosaic(
      aes(weight = n, x = product(a, b, c), fill = flag)
    ) +
    scale_x_productlist(sec.axis = NULL)
)
stopifnot(
  isTRUE(no_secondary_build$layout$panel_scales_x[[1]]$sec_disabled),
  inherits(
    no_secondary_build$layout$panel_scales_x[[1]]$secondary.axis,
    "waiver"
  )
)

# Conditioning variables, custom dividers, coordinate flipping, and paired
# mosaic/text layers continue to build with fill-only values excluded from the
# axes.
conditioned_plot <- ggplot(confusion) +
  geom_mosaic(
    aes(
      weight = Freq,
      x = product(actual),
      conds = product(predictions),
      fill = is_correct
    ),
    divider = c("hspine", "vspine", "hspine")
  )
conditioned_build <- build_without_warnings(conditioned_plot)
stopifnot(
  all(c("actual", "predictions") %in% axis_text(conditioned_build))
)
stopifnot_absent(
  axis_text(conditioned_build),
  c("is_correct", "Correct prediction", "Incorrect prediction")
)
stopifnot(inherits(ggplotGrob(conditioned_plot + coord_flip()), "gtable"))

paired_build <- build_without_warnings(
  issue_plot +
    geom_mosaic_text(
      aes(weight = Freq, x = product(actual, predictions)),
      size = 2
    )
)
stopifnot(length(paired_build$data) == 2L)
stopifnot_absent(
  axis_text(paired_build),
  c("is_correct", "Correct prediction", "Incorrect prediction")
)

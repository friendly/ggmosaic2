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

# Regression for issue #59: expression text must not be used as a formula
# variable name. Both factor() and numeric transformations should become
# ordinary grouping variables in the mosaic calculation.
factor_build <- build_without_warnings(
  ggplot(mtcars) +
    geom_mosaic(aes(x = product(gear), fill = factor(cyl))) +
    scale_fill_discrete()
)
log_build <- build_without_warnings(
  ggplot(mtcars) +
    geom_mosaic(aes(x = product(gear), fill = log(cyl))) +
    scale_fill_discrete()
)
stopifnot(
  nrow(factor_build$data[[1]]) == 9L,
  nrow(log_build$data[[1]]) == 9L,
  length(unique(factor_build$data[[1]]$fill)) == 3L,
  length(unique(log_build$data[[1]]$fill)) == 3L,
  identical(factor_build$plot$labels$fill, "factor(cyl)"),
  identical(log_build$plot$labels$fill, "log(cyl)")
)

# Computing the value in aes() must give the same rectangles as creating the
# column in advance.
precomputed <- mtcars
precomputed$cyl_factor <- factor(precomputed$cyl)
precomputed_build <- build_without_warnings(
  ggplot(precomputed) +
    geom_mosaic(aes(x = product(gear), fill = cyl_factor)) +
    scale_fill_discrete()
)
computed_geometry <- factor_build$data[[1]][c("label", "xmin", "xmax", "ymin", "ymax")]
precomputed_geometry <- precomputed_build$data[[1]][c("label", "xmin", "xmax", "ymin", "ymax")]
computed_geometry <- computed_geometry[order(computed_geometry$label), ]
precomputed_geometry <- precomputed_geometry[order(precomputed_geometry$label), ]
rownames(computed_geometry) <- NULL
rownames(precomputed_geometry) <- NULL
stopifnot(isTRUE(all.equal(computed_geometry, precomputed_geometry)))

# Transformations also work in product(), in conds, and through namespace-only
# product() calls. The original expression remains the visible axis title.
product_build <- build_without_warnings(
  ggplot(mtcars) +
    geom_mosaic(aes(
      x = ggmosaic2::product(factor(gear)),
      conds = product(cut(cyl, breaks = c(0, 5, 9))),
      fill = factor(vs)
    )) +
    scale_fill_discrete()
)
stopifnot(
  nrow(product_build$data[[1]]) == 12L,
  setequal(
    c(product_build$layout$panel_scales_x[[1]]$product_name,
      product_build$layout$panel_scales_y[[1]]$product_name),
    c("cut(cyl, breaks = c(0, 5, 9))", "factor(gear)")
  )
)

# All public mosaic layer variants use the same mapping preparation.
stat_build <- build_without_warnings(
  ggplot(mtcars) +
    stat_mosaic(aes(x = product(gear), fill = factor(cyl))) +
    scale_fill_discrete()
)
text_build <- build_without_warnings(
  ggplot(mtcars) +
    geom_mosaic_text(aes(x = product(gear), fill = factor(cyl)))
)
jitter_build <- build_without_warnings(
  ggplot(mtcars) +
    geom_mosaic_jitter(
      aes(x = product(gear), colour = factor(cyl)),
      seed = 1
    )
)
stopifnot(
  nrow(stat_build$data[[1]]) == 9L,
  nrow(text_build$data[[1]]) == 9L,
  nrow(jitter_build$data[[1]]) == nrow(mtcars)
)

# Safe internal IDs must continue to translate custom expected-model formulas
# written with the user's original variable names.
titanic_table <- as.data.frame(Titanic)
model_build <- build_without_warnings(
  ggplot(titanic_table) +
    geom_mosaic(
      aes(weight = Freq, x = product(Class, Sex)),
      expected = ~ Class + Sex
    )
)
stopifnot(
  nrow(model_build$data[[1]]) == 8L,
  all(c(".expected", ".residual") %in% names(model_build$data[[1]]))
)

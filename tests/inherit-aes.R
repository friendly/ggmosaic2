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

sort_cells <- function(data) {
  data <- data[order(data$label), , drop = FALSE]
  rownames(data) <- NULL
  data
}

geometry_columns <- c("label", "xmin", "xmax", "ymin", "ymax", ".n")

# The reported HairEyeColor example works with all structural aesthetics in
# the plot mapping and no mappings repeated in either mosaic layer.
hair_freq <- as.data.frame(HairEyeColor)
reported_build <- build_without_warnings(
  ggplot(
    hair_freq,
    aes(weight = Freq, x = product(Hair, Eye), fill = Hair)
  ) +
    geom_mosaic(alpha = 0.1) +
    geom_mosaic_jitter(size = 2, alpha = 0.8)
)
stopifnot(
  nrow(reported_build$data[[1]]) == 16L,
  nrow(reported_build$data[[2]]) == sum(hair_freq$Freq),
  sum(reported_build$data[[1]]$.n) == sum(hair_freq$Freq)
)

# With a fixed jitter seed, inherited mappings are exactly equivalent to the
# previously required explicit layer mappings.
hair_mapping <- aes(weight = Freq, x = product(Hair, Eye), fill = Hair)
global_build <- build_without_warnings(
  ggplot(hair_freq, hair_mapping) +
    geom_mosaic(alpha = 0.1) +
    geom_mosaic_jitter(size = 2, alpha = 0.8, seed = 19790801)
)
explicit_build <- build_without_warnings(
  ggplot(hair_freq) +
    geom_mosaic(hair_mapping, alpha = 0.1) +
    geom_mosaic_jitter(
      hair_mapping,
      size = 2,
      alpha = 0.8,
      seed = 19790801
    )
)
stopifnot(isTRUE(all.equal(global_build$data, explicit_build$data)))

# Mosaic and text layers prepared from the same global mapping retain matching
# cell geometry and frequencies.
text_build <- build_without_warnings(
  ggplot(hair_freq, aes(weight = Freq, x = product(Hair, Eye))) +
    geom_mosaic() +
    geom_mosaic_text(display_values = "observed", format_digits = 0)
)
mosaic_geometry <- sort_cells(text_build$data[[1]][geometry_columns])
text_geometry <- sort_cells(text_build$data[[2]][geometry_columns])
stopifnot(isTRUE(all.equal(mosaic_geometry, text_geometry)))

# Weight, fill, alpha, and conds supplied globally are all recorded before the
# stat computes the mosaic.
weighted_alpha_build <- build_without_warnings(
  ggplot(
    hair_freq,
    aes(
      weight = Freq,
      x = product(Hair, Eye),
      fill = Hair,
      alpha = as.numeric(Sex == "Male")
    )
  ) +
    geom_mosaic() +
    scale_alpha_manual(values = c("0" = 0.4, "1" = 1))
)
weighted_alpha_spec <- weighted_alpha_build$plot$layers[[1]]$mosaic_computed_spec
stopifnot(
  identical(weighted_alpha_spec$aesthetics$fill, ".mosaic_x1"),
  identical(weighted_alpha_spec$aesthetics$alpha, ".mosaic_alpha"),
  identical(weighted_alpha_spec$labels[[".mosaic_alpha"]],
            "as.numeric(Sex == \"Male\")"),
  sum(weighted_alpha_build$data[[1]]$.n) == sum(hair_freq$Freq)
)

conditioned_build <- build_without_warnings(
  ggplot(
    hair_freq,
    aes(
      weight = Freq,
      x = product(Hair),
      conds = product(Sex),
      fill = Eye
    )
  ) +
    geom_mosaic()
)
conditioned_spec <- conditioned_build$plot$layers[[1]]$mosaic_computed_spec
stopifnot(
  identical(unname(conditioned_spec$labels[conditioned_spec$cond]), "Sex"),
  identical(conditioned_spec$aesthetics$fill, ".mosaic_fill"),
  sum(conditioned_build$data[[1]]$.n) == sum(hair_freq$Freq)
)

# Quosure environments, transformed expressions, safe internal names, and
# readable labels survive plot-level inheritance.
transformed_build <- build_without_warnings(
  ggplot(
    mtcars,
    aes(
      x = ggmosaic2::product(factor(gear)),
      conds = product(cut(cyl, breaks = c(0, 5, 9))),
      fill = factor(vs)
    )
  ) +
    geom_mosaic() +
    scale_fill_discrete()
)
transformed_spec <- transformed_build$plot$layers[[1]]$mosaic_computed_spec
stopifnot(
  identical(unname(transformed_spec$labels[transformed_spec$marg]),
            c("factor(vs)", "factor(gear)")),
  identical(unname(transformed_spec$labels[transformed_spec$cond]),
            "cut(cyl, breaks = c(0, 5, 9))")
)

# Direct layer mappings override plot mappings.
override_build <- build_without_warnings(
  ggplot(hair_freq, aes(weight = Freq, x = product(Hair), fill = Hair)) +
    geom_mosaic(aes(x = product(Eye), fill = Eye))
)
override_spec <- override_build$plot$layers[[1]]$mosaic_computed_spec
stopifnot(
  identical(unname(override_spec$labels[override_spec$axis]), "Eye"),
  identical(override_spec$aesthetics$fill, ".mosaic_x1"),
  nrow(override_build$data[[1]]) == 4L,
  sum(override_build$data[[1]]$.n) == sum(hair_freq$Freq)
)

# inherit.aes = FALSE isolates all plot mappings, including weight.
isolated_build <- build_without_warnings(
  ggplot(hair_freq, aes(weight = Freq, x = product(Hair), fill = Hair)) +
    geom_mosaic(aes(x = product(Eye)), inherit.aes = FALSE)
)
isolated_spec <- isolated_build$plot$layers[[1]]$mosaic_computed_spec
stopifnot(
  is.null(isolated_spec$aesthetics$fill),
  identical(unname(isolated_spec$labels[isolated_spec$axis]), "Eye"),
  sum(isolated_build$data[[1]]$.n) == nrow(hair_freq)
)

# All three stat interfaces resolve global mappings through the same path.
titanic_table <- as.data.frame(Titanic)
stat_layers <- list(
  stat_mosaic(),
  stat_mosaic_text(),
  stat_mosaic_jitter(seed = 19790801)
)
stat_rows <- vapply(
  stat_layers,
  function(layer) {
    built <- build_without_warnings(
      ggplot(
        titanic_table,
        aes(weight = Freq, x = product(Class, Sex))
      ) +
        layer
    )
    nrow(built$data[[1]])
  },
  integer(1)
)
stopifnot(all(stat_rows == c(8L, 8L, sum(titanic_table$Freq))))

# Faceting, residual calculations, and explicit divider vectors remain valid
# when their mappings originate on the plot.
facet_build <- build_without_warnings(
  ggplot(
    hair_freq,
    aes(weight = Freq, x = product(Hair, Eye))
  ) +
    geom_mosaic() +
    facet_mosaic_grid(rows = vars(Sex))
)
stopifnot(length(unique(facet_build$data[[1]]$PANEL)) == 2L)

residual_build <- build_without_warnings(
  ggplot(
    titanic_table,
    aes(weight = Freq, x = product(Class, Sex))
  ) +
    geom_mosaic(
      expected = "independence",
      divider = c("vspine", "hspine")
    )
)
stopifnot(
  all(c(".expected", ".residual") %in% names(residual_build$data[[1]])),
  nrow(residual_build$data[[1]]) == 8L
)

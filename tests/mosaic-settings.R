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

geometry <- function(built, layer = 1L) {
  cells <- built$data[[layer]][
    c("label", "xmin", "xmax", "ymin", "ymax", ".n")
  ]
  cells <- cells[order(cells$label), , drop = FALSE]
  rownames(cells) <- NULL
  cells
}

built_layer_equal <- function(lhs, rhs, layer = 1L) {
  isTRUE(all.equal(
    lhs$data[[layer]],
    rhs$data[[layer]],
    check.attributes = FALSE
  ))
}

titanic_table <- as.data.frame(Titanic)

# All public constructors now return ordinary ggplot2 layers immediately.
constructors <- list(
  geom_mosaic(),
  stat_mosaic(),
  geom_mosaic_text(),
  stat_mosaic_text(),
  geom_mosaic_jitter(),
  stat_mosaic_jitter()
)
stopifnot(all(vapply(constructors, inherits, logical(1), what = "Layer")))

# Plot mappings added after a layer are resolved at build time.
late_mosaic <- build_without_warnings(
  ggplot(titanic_table) +
    geom_mosaic() +
    aes(weight = Freq, x = product(Class, Sex))
)
late_text <- build_without_warnings(
  ggplot(titanic_table) +
    geom_mosaic_text(display_values = "observed") +
    aes(weight = Freq, x = product(Class, Sex))
)
late_jitter <- build_without_warnings(
  ggplot(titanic_table) +
    geom_mosaic_jitter(seed = 19790801) +
    aes(weight = Freq, x = product(Class, Sex))
)
stopifnot(
  nrow(late_mosaic$data[[1]]) == 8L,
  nrow(late_text$data[[1]]) == 8L,
  nrow(late_jitter$data[[1]]) == sum(titanic_table$Freq)
)

# Direct mappings still override the final plot mapping, and isolation remains
# effective even when the plot mapping is added later.
override <- build_without_warnings(
  ggplot(titanic_table) +
    geom_mosaic(aes(x = product(Age))) +
    aes(weight = Freq, x = product(Class))
)
isolated <- build_without_warnings(
  ggplot(titanic_table) +
    geom_mosaic(aes(x = product(Age)), inherit.aes = FALSE) +
    aes(weight = Freq, x = product(Class))
)
stopifnot(
  identical(
    unname(override$plot$layers[[1]]$mosaic_computed_spec$labels),
    "Age"
  ),
  sum(isolated$data[[1]]$.n) == nrow(titanic_table)
)

# One settings object supplies model and layout parameters to sibling layers.
shared <- build_without_warnings(
  ggplot(
    titanic_table,
    aes(weight = Freq, x = product(Class, Sex))
  ) +
    mosaic_settings(
      expected = "independence",
      divider = c("vspine", "hspine"),
      offset = 0.02
    ) +
    geom_mosaic() +
    geom_mosaic_text(display_values = "residual")
)
stopifnot(
  all(c(".expected", ".residual") %in% names(shared$data[[1]])),
  all(c(".expected", ".residual") %in% names(shared$data[[2]])),
  isTRUE(all.equal(geometry(shared, 1L), geometry(shared, 2L)))
)

# Supplying all applicable settings at plot level is equivalent to supplying
# the same values directly to each of the six public constructors. Keep the
# jitter weights tiny so this lifecycle test remains inexpensive in R CMD
# check.
small_table <- aggregate(Freq ~ Class + Sex, titanic_table, sum)
small_table$Freq <- 1
constructor_base <- ggplot(
  small_table,
  aes(weight = Freq, x = product(Class, Sex))
)
constructor_settings <- mosaic_settings(
  expected = "independence",
  divider = c("vspine", "hspine"),
  offset = 0.02
)
constructor_pairs <- list(
  list(
    constructor_base + constructor_settings + geom_mosaic(),
    constructor_base + geom_mosaic(
      expected = "independence",
      divider = c("vspine", "hspine"),
      offset = 0.02
    )
  ),
  list(
    constructor_base + constructor_settings + stat_mosaic(),
    constructor_base + stat_mosaic(
      expected = "independence",
      divider = c("vspine", "hspine"),
      offset = 0.02
    )
  ),
  list(
    constructor_base + constructor_settings + geom_mosaic_text(),
    constructor_base + geom_mosaic_text(
      expected = "independence",
      divider = c("vspine", "hspine"),
      offset = 0.02
    )
  ),
  list(
    constructor_base + constructor_settings + stat_mosaic_text(),
    constructor_base + stat_mosaic_text(
      expected = "independence",
      divider = c("vspine", "hspine"),
      offset = 0.02
    )
  ),
  list(
    constructor_base + constructor_settings +
      geom_mosaic_jitter(seed = 19790801),
    constructor_base + geom_mosaic_jitter(
      divider = c("vspine", "hspine"),
      offset = 0.02,
      seed = 19790801
    )
  ),
  list(
    constructor_base + constructor_settings +
      stat_mosaic_jitter(seed = 19790801),
    constructor_base + stat_mosaic_jitter(
      divider = c("vspine", "hspine"),
      offset = 0.02,
      seed = 19790801
    )
  )
)
for (pair in constructor_pairs) {
  stopifnot(built_layer_equal(
    build_without_warnings(pair[[1]]),
    build_without_warnings(pair[[2]])
  ))
}

# Explicit layer values override plot settings, including expected = NULL.
override_settings <- build_without_warnings(
  ggplot(
    titanic_table,
    aes(weight = Freq, x = product(Class, Sex))
  ) +
    mosaic_settings(expected = "independence", offset = 0.05) +
    geom_mosaic(offset = 0.01) +
    geom_mosaic_text(expected = NULL, offset = 0.01,
                     display_values = "observed")
)
explicit_defaults <- build_without_warnings(
  ggplot(
    titanic_table,
    aes(weight = Freq, x = product(Class, Sex))
  ) +
    geom_mosaic(offset = 0.01)
)
stopifnot(
  isTRUE(all.equal(
    geometry(override_settings, 1L),
    geometry(explicit_defaults, 1L)
  )),
  !".expected" %in% names(override_settings$data[[2]]),
  !".residual" %in% names(override_settings$data[[2]])
)

# Repeated settings merge only supplied fields, including an explicit NULL.
merged_plot <- ggplot(titanic_table) +
  mosaic_settings(expected = "independence", offset = 0.02) +
  mosaic_settings(offset = 0.01) +
  mosaic_settings(expected = NULL)
stopifnot(
  identical(merged_plot$ggmosaic2_settings$offset, 0.01),
  "expected" %in% names(merged_plot$ggmosaic2_settings),
  is.null(merged_plot$ggmosaic2_settings$expected)
)

# Settings are order independent.
settings_first <- build_without_warnings(
  ggplot(titanic_table, aes(weight = Freq, x = product(Class, Sex))) +
    mosaic_settings(offset = 0.02) +
    geom_mosaic()
)
settings_last <- build_without_warnings(
  ggplot(titanic_table, aes(weight = Freq, x = product(Class, Sex))) +
    geom_mosaic() +
    mosaic_settings(offset = 0.02)
)
stopifnot(isTRUE(all.equal(geometry(settings_first), geometry(settings_last))))

# A plot-level expected model is inapplicable to jitter and is ignored.
jitter_with_model_setting <- build_without_warnings(
  ggplot(titanic_table, aes(weight = Freq, x = product(Class, Sex))) +
    mosaic_settings(expected = "independence") +
    geom_mosaic_jitter(seed = 19790801)
)
stopifnot(
  !".expected" %in% names(jitter_with_model_setting$data[[1]]),
  !".residual" %in% names(jitter_with_model_setting$data[[1]])
)

# Derived plots that share a layer retain independent build-time settings.
shared_layer <- geom_mosaic()
base_plot <- ggplot(
  titanic_table,
  aes(weight = Freq, x = product(Class, Sex))
) + shared_layer
p_small <- base_plot + mosaic_settings(offset = 0.005)
p_large <- base_plot + mosaic_settings(offset = 0.05)

small_first <- build_without_warnings(p_small)
large_second <- build_without_warnings(p_large)
large_first <- build_without_warnings(p_large)
small_second <- build_without_warnings(p_small)
stopifnot(
  !isTRUE(all.equal(geometry(small_first), geometry(large_second))),
  isTRUE(all.equal(geometry(small_first), geometry(small_second))),
  isTRUE(all.equal(geometry(large_first), geometry(large_second)))
)

# A failed build and a successful build both leave unresolved constructor
# parameters intact for future builds.
unresolved_layer <- geom_mosaic()
original_mapping <- unresolved_layer$mapping
bad_build <- try(
  ggplot_build(
    ggplot(titanic_table) +
      unresolved_layer +
      aes(x = product(Class), y = Age)
  ),
  silent = TRUE
)
stopifnot(
  inherits(bad_build, "try-error"),
  inherits(unresolved_layer$stat_params$offset,
           "ggmosaic_inherit_setting"),
  identical(unresolved_layer$mapping, original_mapping)
)
invisible(build_without_warnings(
  ggplot(titanic_table, aes(weight = Freq, x = product(Class))) +
    unresolved_layer
))
stopifnot(
  inherits(unresolved_layer$stat_params$offset,
           "ggmosaic_inherit_setting"),
  identical(unresolved_layer$mapping, original_mapping)
)

# Replacing a sentinel in a returned layer is an explicit override.
modified_layer <- geom_mosaic()
modified_layer$stat_params$offset <- 0.01
modified <- build_without_warnings(
  ggplot(titanic_table, aes(weight = Freq, x = product(Class, Sex))) +
    mosaic_settings(offset = 0.05) +
    modified_layer
)
stopifnot(isTRUE(all.equal(
  geometry(modified),
  geometry(explicit_defaults)
)))

# stat_mosaic_text() now accepts expected directly and through plot settings.
text_stat <- build_without_warnings(
  ggplot(titanic_table, aes(weight = Freq, x = product(Class, Sex))) +
    mosaic_settings(expected = "independence") +
    stat_mosaic_text()
)
stopifnot(all(c(".expected", ".residual") %in% names(text_stat$data[[1]])))

# Formula objects retain their environment, and the conditional shortcut works
# when a conditioning aesthetic is present.
formula_model <- local({
  environment_marker <- new.env()
  ~ Class + Sex
})
formula_plot <- ggplot(
  titanic_table,
  aes(weight = Freq, x = product(Class, Sex))
) +
  mosaic_settings(expected = formula_model) +
  geom_mosaic()
formula_build <- build_without_warnings(formula_plot)
stopifnot(
  identical(
    environment(formula_plot$ggmosaic2_settings$expected),
    environment(formula_model)
  ),
  identical(
    environment(
      formula_build$plot$layers[[1]]$computed_stat_params$expected
    ),
    environment(formula_model)
  )
)

conditional <- build_without_warnings(
  ggplot(
    titanic_table,
    aes(
      weight = Freq,
      x = product(Class, Age),
      conds = product(Sex)
    )
  ) +
    mosaic_settings(expected = "conditional") +
    geom_mosaic() +
    geom_mosaic_text(display_values = "residual")
)
stopifnot(all(vapply(
  conditional$data,
  function(data) all(c(".expected", ".residual") %in% names(data)),
  logical(1)
)))

# Shared settings are resolved independently in every facet, and sibling
# rectangle/text layers remain aligned panel by panel.
faceted <- build_without_warnings(
  ggplot(
    titanic_table,
    aes(weight = Freq, x = product(Class, Sex))
  ) +
    mosaic_settings(expected = "independence", offset = 0.02) +
    geom_mosaic() +
    geom_mosaic_text(display_values = "residual") +
    facet_wrap(vars(Age))
)
facet_geometry <- c("PANEL", "xmin", "xmax", "ymin", "ymax")
stopifnot(
  length(unique(faceted$data[[1]]$PANEL)) == 2L,
  isTRUE(all.equal(
    faceted$data[[1]][facet_geometry],
    faceted$data[[2]][facet_geometry],
    check.attributes = FALSE
  ))
)

# Plot metadata, inheritance sentinels, and their environments survive an R
# serialization round trip.
round_trip_plot <- unserialize(serialize(
  ggplot(
    titanic_table,
    aes(weight = Freq, x = product(Class, Sex))
  ) +
    mosaic_settings(expected = "independence", offset = 0.02) +
    geom_mosaic(),
  NULL
))
round_trip <- build_without_warnings(round_trip_plot)
stopifnot(
  nrow(round_trip$data[[1]]) == 8L,
  all(c(".expected", ".residual") %in% names(round_trip$data[[1]]))
)

# Existing implicit partition semantics are intentionally unchanged.
implicit_fill <- build_without_warnings(
  ggplot(
    titanic_table,
    aes(weight = Freq, x = product(Class), fill = Survived)
  ) +
    geom_mosaic()
)
implicit_both <- build_without_warnings(
  ggplot(
    titanic_table,
    aes(
      weight = Freq,
      x = product(Class),
      fill = Survived,
      alpha = as.numeric(Survived == "Yes")
    )
  ) +
    geom_mosaic() +
    scale_alpha_manual(values = c("0" = 0.4, "1" = 1))
)
stopifnot(
  nrow(implicit_fill$data[[1]]) == 8L,
  nrow(implicit_both$data[[1]]) == 16L
)

# Construction-time validation is strict for new settings but does not affect
# the existing layer argument validation lifecycle.
stopifnot(
  inherits(try(mosaic_settings(offset = -1), silent = TRUE), "try-error"),
  inherits(try(mosaic_settings(offset = c(0, 1)), silent = TRUE), "try-error"),
  inherits(try(mosaic_settings(expected = "unknown"), silent = TRUE), "try-error"),
  inherits(try(mosaic_settings(divider = NULL), silent = TRUE), "try-error")
)

# Preserve the existing model-shortcut interface: layer arguments accept
# case-insensitive and unambiguous partial matches, so plot settings do too.
for (shortcut in c("Independence", "INDEPENDENCE", "ind", "sat")) {
  shortcut_build <- build_without_warnings(
    ggplot(
      titanic_table,
      aes(weight = Freq, x = product(Class, Sex))
    ) +
      mosaic_settings(expected = shortcut) +
      geom_mosaic()
  )
  stopifnot(all(
    c(".expected", ".residual") %in% names(shortcut_build$data[[1]])
  ))
}

# Inherited parameters remain visible but are no longer printed as empty
# lists when inspecting the ordinary ggplot2 layer returned by a constructor.
layer_print <- capture.output(print(geom_mosaic()))
stopifnot(
  any(grepl("divider = <inherited>", layer_print, fixed = TRUE)),
  !any(grepl("list()", layer_print, fixed = TRUE))
)

# Settings on an otherwise ordinary ggplot are harmless.
ordinary <- build_without_warnings(
  ggplot(mtcars, aes(mpg, wt)) +
    mosaic_settings(offset = 0.02) +
    geom_point()
)
stopifnot(nrow(ordinary$data[[1]]) == nrow(mtcars))

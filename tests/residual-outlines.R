library(ggmosaic2)

outline_data <- as.data.frame(HairEyeColor)

default_plot <- ggplot(outline_data) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye, Sex)),
    expected = "independence"
  )
default_data <- ggplot_build(default_plot)$data[[1]]

positive <- default_data$.residual > 0
negative <- default_data$.residual < 0

stopifnot(
  any(positive),
  any(negative),
  all(default_data$colour[positive] == "darkblue"),
  all(default_data$linetype[positive] == "solid"),
  all(default_data$colour[negative] == "darkred"),
  all(default_data$linetype[negative] == "dashed"),
  all(default_data$linewidth == 0.4)
)

sign_check <- ggmosaic2:::residual_outline_aesthetics(c(-1e-12, 0, 1e-12))

stopifnot(
  identical(sign_check$colour, c("darkred", "black", "darkblue")),
  identical(sign_check$linetype, c("dashed", "solid", "solid"))
)

override_plot <- ggplot(outline_data) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye, Sex)),
    expected = "independence",
    colour = "purple",
    linetype = "dotdash",
    linewidth = 0.8
  )
override_data <- ggplot_build(override_plot)$data[[1]]

stopifnot(
  all(override_data$colour == "purple"),
  all(override_data$linetype == "dotdash"),
  all(override_data$linewidth == 0.8)
)

disabled_plot <- ggplot(outline_data) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye, Sex)),
    expected = "independence",
    color = NA
  ) +
  scale_fill_residual()
disabled_data <- ggplot_build(disabled_plot)$data[[1]]

collect_outline_grobs <- function(grob) {
  result <- list(grob)
  if (!is.null(grob$grobs)) {
    result <- c(
      result,
      unlist(lapply(grob$grobs, collect_outline_grobs), recursive = FALSE)
    )
  }
  if (!is.null(grob$children)) {
    result <- c(
      result,
      unlist(lapply(grob$children, collect_outline_grobs), recursive = FALSE)
    )
  }
  result
}

disabled_rects <- Filter(
  function(grob) inherits(grob, "rect"),
  collect_outline_grobs(ggplotGrob(disabled_plot))
)
disabled_cells <- disabled_rects[vapply(
  disabled_rects,
  function(grob) length(grob$gp$fill) == nrow(disabled_data),
  logical(1)
)]

stopifnot(
  all(is.na(disabled_data$colour)),
  length(disabled_cells) == 1,
  all(is.na(disabled_cells[[1]]$gp$col))
)

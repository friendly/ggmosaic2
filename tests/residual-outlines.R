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

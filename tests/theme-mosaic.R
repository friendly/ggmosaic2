library(ggmosaic2)

# Existing positional arguments retain their meaning after the addition of
# forwarded theme arguments.
stopifnot(identical(
  theme_mosaic(13, "mono", 30),
  theme_mosaic(base_size = 13, base_family = "mono", rot_labels = 30)
))

custom_theme <- theme_mosaic(
  rot_labels = 30,
  legend.position = "bottom",
  aspect.ratio = 2,
  axis.text.x = element_text(colour = "red")
)

stopifnot(
  identical(custom_theme$legend.position, "bottom"),
  identical(custom_theme$aspect.ratio, 2),
  identical(custom_theme$axis.text.x$colour, "red")
)

# Forwarded settings are applied last and can override mosaic defaults.
blank_x_text <- theme_mosaic(
  rot_labels = 30,
  axis.text.x = element_blank()
)
stopifnot(inherits(blank_x_text$axis.text.x, "element_blank"))

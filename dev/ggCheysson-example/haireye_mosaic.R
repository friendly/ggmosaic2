# HairEyeColor residual mosaic styled with ggCheysson::theme_cheysson()
# on a procedurally generated weathered-paper background.
# Run from the package root (ggmosaic2.Rproj).

suppressMessages({library(ggplot2); library(ggmosaic2); library(ggCheysson)})
source("dev/ggCheysson-example/paper.R")
ink <- "#3b2f25"

p <- HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), weight = Freq)) +
  mosaic_settings(expected = "independence") +
  geom_mosaic() +
  scale_fill_residual(
    low  = cheysson_pal("1886_04")[1],   # Album 1886 vermilion
    mid  = "#f7f1e3",
    high = cheysson_pal("1891_06")[1]    # Album 1891 blue
  ) +
  labs(title    = "Hair and Eye Colour of 592 Statistics Students",
       subtitle = "Pearson residuals from the model of independence",
       caption  = "Data: Snee (1974), HairEyeColor") +
  theme_cheysson(base_size = 12) +
  theme(
    plot.background   = element_rect(fill = paper_background(), colour = NA),
    panel.background  = element_blank(),
    panel.grid.major  = element_blank(),
    panel.grid.minor  = element_blank(),
    panel.border      = element_rect(colour = ink, linewidth = 0.4),
    legend.background = element_blank(),
    legend.key        = element_blank(),
    axis.text.x.top   = element_text(size = rel(0.85)),
    plot.title        = element_text(hjust = 0.5),
    plot.subtitle     = element_text(hjust = 0.5),
    plot.margin       = margin(24, 28, 18, 28)
  )

ggsave("dev/ggCheysson-example/haireye_mosaic.png", p, width = 9, height = 7, dpi = 110,
       device = ragg::agg_png, bg = "#efe4c9")

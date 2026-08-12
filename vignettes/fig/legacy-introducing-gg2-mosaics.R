# Contains mosaics made with haleyjeppson/ggmosaic for use in vignette
# introducing-ggmosaic2.Rmd

#remotes::install_github("haleyjeppson/ggmosaic")
library(ggmosaic)

# topright
topright <- HairEyeColor |>
  as.data.frame() |>
  ggplot() +
  geom_mosaic(aes(x = product(Sex, Eye, Hair), fill = Hair, weight = Freq)) +
  labs(title = "Old") +
  theme(plot.title = element_text(face = "bold", hjust = .5, size = 32))

ggsave("vignettes/fig/topright-old.png", topright, dpi = 300)

# theme
theme <- HairEyeColor |>
  as.data.frame() |>
  ggplot() +
  geom_mosaic(aes(x = product(Sex, Eye, Hair), fill = Hair, weight = Freq)) +
  theme_mosaic() +
  labs(title = "Old") +
  theme(plot.title = element_text(face = "bold", hjust = .5, size = 32))

ggsave("vignettes/fig/theme-old.png", theme, dpi = 300)

# faceting
faceting <- HairEyeColor |>
  as.data.frame() |>
  ggplot() +
  geom_mosaic(aes(x = product(Eye, Hair), fill = Hair, weight = Freq)) +
  theme_mosaic() +
  facet_grid(. ~ Sex) +
  labs(title = "Old") +
  theme(plot.title = element_text(face = "bold", hjust = .5, size = 32))

ggsave("vignettes/fig/facet-old.png", faceting, dpi = 300)

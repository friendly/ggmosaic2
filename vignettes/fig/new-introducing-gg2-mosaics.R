# Contains mosaics made with friendly/ggmosaic2 for use in vignette
# introducing-ggmosaic2.Rmd

#remotes::install_github("friendly/ggmosaic2")
library(ggmosaic2)

# topright
topright <- HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), fill = Hair, weight = Freq)) +
  geom_mosaic() +
  labs(title = "New") +
  theme(plot.title = element_text(face = "bold", hjust = .5, size = 32))

ggsave("vignettes/fig/topright-new.png", topright, dpi = 300)

# theme
theme <- HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Sex, Eye, Hair), fill = Hair, weight = Freq)) +
  geom_mosaic() +
  theme_mosaic(base_size = 12) +
  labs(title = "New") +
  theme(plot.title = element_text(face = "bold", hjust = .5, size = 32))

ggsave("vignettes/fig/theme-new.png", theme, dpi = 300)


# faceting
faceting <- HairEyeColor |>
  as.data.frame() |>
  ggplot(aes(x = product(Eye, Hair), fill = Hair, weight = Freq)) +
  geom_mosaic() +
  theme_mosaic() +
  facet_mosaic_grid(. ~ Sex) +
  labs(title = "New") +
  theme(plot.title = element_text(face = "bold", hjust = .5, size = 32))

ggsave("vignettes/fig/facet-new.png", faceting, dpi = 300)

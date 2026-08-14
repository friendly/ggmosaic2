# test cases for mosaics with jittered points

library(ggmosaic2)

HEC_df <- as.data.frame(HairEyeColor)
ggplot(data = HEC_df) +
  geom_mosaic(aes(x = product(Hair, Eye),
                  weight = Freq,
                  fill = Hair),
              alpha=0.1) +

  geom_mosaic_jitter(aes(weight = Freq,
                         x = product(Hair, Eye),
                         color=Hair),
                     size=2, alpha = 0.8) +
  labs(title = "Hair and Eye Color",
       subtitle = "Observed frequency mosaic with jittered points") +
  theme_mosaic(base_size = 14) +
  theme(legend.position = "none")

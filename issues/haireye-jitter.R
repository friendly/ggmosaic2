library(ggplot2)
library(ggmosaic)

hair_freq <- as.data.frame(HairEyeColor)
head(hair_freq)

# How to change the colors for Hair to reflect the actual colors, "black", "brown", "red", "blonde"?
# SOLUTION: Use scale_fill_manual() with custom colors
ggplot(data = hair_freq) +
  geom_mosaic(aes(weight = Freq, x = product(Hair, Eye), fill = Hair)) +
  scale_fill_manual(values = c("Black" = "darkgray",
                                "Brown" = "brown4",
                                "Red" = "red3",
                                "Blond" = "gold")) +
  labs(title = "Hair and Eye Color",
       subtitle = "Marimekko shading")

# why is this not working???
# PROBLEM: expected is inside aes() but should be a parameter to geom_mosaic()
# SOLUTION: Move expected outside of aes()
ggplot(data = hair_freq) +
  geom_mosaic(aes(weight = Freq, x = product(Hair, Eye)),
              expected = "independence") +
  scale_fill_residual(low = "red", high = "blue") +
  labs(title = "Hair and Eye Color",
       subtitle = "Independence model")

# try adding jittered points
ggplot(data = hair_freq) +
  geom_mosaic(aes(weight = Freq,
                  x = product(Hair, Eye),
                  fill = Hair),
              alpha=0.1) +
  geom_mosaic_jitter(aes(weight = Freq,
                         x = product(Hair, Eye),
                         color=Hair),
                     size=2, alpha = 0.8) +
  labs(title = "Hair and Eye Color",
       subtitle = "Observed frequency mosaic with jittered observed points") +
  theme_mosaic(base_size = 14) +
  theme(legend.position = "none")

# How can I do something similar, but using the expected frequencies to form the mosaic plot, and
# then showing the observed frequencies by jittering the observed points
# SOLUTION: Use expected parameter in both geom_mosaic and geom_mosaic_jitter
# The mosaic tiles show expected frequencies, jittered points show observed
ggplot(data = hair_freq) +
  geom_mosaic(aes(weight = Freq,
                  x = product(Hair, Eye)),
              expected = "independence",
              alpha = 0.2) +
  geom_mosaic_jitter(aes(weight = Freq,
                         x = product(Hair, Eye),
                         color = Hair),
                     expected = "independence",
                     size = 2, alpha = 0.8) +
  scale_fill_residual() +
  # scale_color_manual(values = c("Black" = "black",
  #                                "Brown" = "brown4",
  #                                "Red" = "red3",
  #                                "Blond" = "gold")) +
  labs(title = "Hair and Eye Color",
       subtitle = "Expected frequency mosaic with jittered observed points") +
  theme_mosaic(base_size = 14) +
  theme(legend.position = "none")

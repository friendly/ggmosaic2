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

# Preferred API: expected counts determine cell area, while the integrated
# points still represent observed counts. Density is therefore O / E.
ggplot(data = HEC_df) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye, Sex)),
    expected = "independence",
    area = "expected",
    jitter = TRUE,
    jitter_mapping = aes(colour = Hair),
    jitter_size = 2,
    jitter_alpha = 0.8,
    seed = 123
  ) +
  scale_fill_residual() +
  labs(
    title = "Hair and Eye Color",
    subtitle = "Expected-area mosaic with observed-count jitter"
  ) +
  theme_mosaic(base_size = 14)

# Lower-level compatibility form. Both layers must repeat the same layout
# arguments, which is why geom_mosaic(jitter = TRUE) is preferred.
ggplot(data = HEC_df) +
  geom_mosaic(
    aes(weight = Freq, x = product(Hair, Eye, Sex)),
    expected = "independence", area = "expected", alpha = 0.2
  ) +
  geom_mosaic_jitter(
    aes(weight = Freq, x = product(Hair, Eye, Sex), colour = Hair),
    expected = "independence", area = "expected", size = 2,
    alpha = 0.8, seed = 123
  ) +
  scale_fill_residual() +
  theme_mosaic(base_size = 14)

# Reference construction in vcd (if installed). vcd uses fitted values for
# geometry when type = "expected"; labeling_points uses observed values.
if (requireNamespace("vcd", quietly = TRUE) &&
    requireNamespace("vcdExtra", quietly = TRUE)) {
  vcd::mosaic(
    HairEyeColor,
    expected = ~ Hair + Eye + Sex,
    type = "expected",
    labeling = vcdExtra::labeling_points(value_type = "observed")
  )
}

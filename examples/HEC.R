# Variations of mosaic plots for the HairEyeColor data
#
# HairEyeColor: 3-way table Hair x Eye x Sex (32 cells, 592 students)
# HairEye:      HairEyeColor collapsed over Sex -> 2-way table Hair x Eye

library(ggmosaic2)
# library(vcdExtra) --masks mosaic(), spine(), so use as vcdExtra::

# ---- Data ---------------------------------------------------------------

data(HairEyeColor)

HairEye <- margin.table(HairEyeColor, c("Hair", "Eye"))
HairEye

HEC_df   <- as.data.frame(HairEyeColor)
HE_df <- as.data.frame(HairEye)

ftable(Hair ~ Eye, data = HairEye)
ftable(Hair ~ Eye + Sex, data = HairEyeColor)

# NB: color_table doesn't use the same syntax, i.e, a formula as `x`, and a `data=`
vcdExtra::color_table(HairEye)
vcdExtra::color_table(HairEyeColor)

# ---- HairEye: 2-way table, basic and residual-shaded --------------------

ggplot(HE_df) +
  geom_mosaic(aes(x = product(Hair, Eye), weight = Freq)) +
  theme_mosaic(rot_labels = 45)

# NB: The default shading is very dark. `theme_mosaic` doesn't expose anything about shading color
#   - Does it support the fill= aesthetic? YES!
#   - Should be used as an example to show what original `ggmosaic` did ("Marimekko" shading)

ggplot(HE_df) +
  geom_mosaic(aes(x = product(Hair, Eye), weight = Freq, fill=Hair)) +
  theme_mosaic(rot_labels = 45)


ggplot(HE_df) +
  geom_mosaic(aes(x = product(Hair, Eye), weight = Freq),
              expected = "independence") +
  scale_fill_residual(limits = c(-4, 4)) +
  theme_mosaic(rot_labels = 45)

# swap axis order: Eye then Hair
ggplot(HE_df) +
  geom_mosaic(aes(x = product(Eye, Hair), weight = Freq),
              expected = "independence") +
  scale_fill_residual(limits = c(-4, 4)) +
  theme_mosaic(rot_labels = 45)

# ---- HairEyeColor: 3-way table, basic and residual-shaded ---------------

ggplot(HEC_df) +
  geom_mosaic(aes(x = product(Sex, Eye, Hair), weight = Freq)) +
  theme_mosaic(rot_labels = 45)

ggplot(HEC_df) +
  geom_mosaic(aes(x = product(Sex, Eye, Hair), weight = Freq),
              expected = "independence") +
  scale_fill_residual(limits = c(-4, 4)) +
  theme_mosaic(rot_labels = 45)

# condition on Sex instead of including it in the product
ggplot(HEC_df) +
  geom_mosaic(aes(x = product(Eye, Hair), conds = product(Sex), weight = Freq),
              expected = "independence") +
  scale_fill_residual(limits = c(-4, 4)) +
  theme_mosaic(rot_labels = 45)

# ---- Jittered points: individual observations ----------------------------

HEC_indiv <- HEC_df |> tidyr::uncount(Freq)

ggplot(HEC_indiv) +
  geom_mosaic(aes(x = product(Sex, Eye, Hair)), expected = "independence") +
  scale_fill_residual(limits = c(-4, 4)) +
  geom_mosaic_jitter(aes(x = product(Sex, Eye, Hair)), alpha = 0.3) +
  theme_mosaic(rot_labels = 45)

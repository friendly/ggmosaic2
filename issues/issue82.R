# Adapted code from @karltk on GH; issue #82 from haleyjeppson/ggmosaic

ggmosaic2::happy |>
  dplyr::mutate(finrela = forcats::fct_recode(finrela,
                                       "far below     " = "far below average",
                                       "    below" = "below average",
                                       "average" = "average",
                                       "above    " = "above average",
                                       "l\n   far above" = "far above average")) |>
  ggplot2::ggplot() +
  ggmosaic2::geom_mosaic(ggplot2::aes(x = ggmosaic2::product(finrela), fill=health), show.legend = FALSE) +
  ggmosaic2::theme_mosaic() +
  ggplot2::scale_fill_manual(values = c("#4575B4", "#ABD9E9", "#FEE090", "#F46D43"))

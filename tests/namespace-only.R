# Regression test for issue #82: ggmosaic2 must work through `::` without
# attaching the package first.
stopifnot(!"package:ggmosaic2" %in% search())

namespace_plot <- ggplot2::ggplot(
  as.data.frame(Titanic),
  ggplot2::aes(
    weight = Freq,
    x = ggmosaic2::product(Class, Sex),
    fill = Survived
  )
) +
  ggmosaic2::geom_mosaic()

namespace_build <- ggplot2::ggplot_build(namespace_plot)

stopifnot(
  !"package:ggmosaic2" %in% search(),
  nrow(namespace_build$data[[1]]) == 16,
  inherits(
    namespace_build$layout$panel_scales_x[[1]],
    "ScaleContinuousProduct"
  ),
  identical(
    namespace_build$layout$panel_params[[1]]$x$get_labels(),
    c("Male", "Female")
  ),
  identical(
    namespace_build$layout$panel_params[[1]]$y$get_labels(),
    c("1st", "2nd", "3rd", "Crew")
  ),
  inherits(
    namespace_build$layout$panel_scales_x[[1]]$secondary.axis,
    "waiver"
  ),
  !any(c("No", "Yes") %in% c(
    namespace_build$layout$panel_scales_x[[1]]$labels,
    namespace_build$layout$panel_scales_y[[1]]$labels
  ))
)

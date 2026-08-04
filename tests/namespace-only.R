# Regression test for issue #82: ggmosaic2 must work through `::` without
# attaching the package first.
stopifnot(!"package:ggmosaic2" %in% search())

namespace_plot <- ggplot2::ggplot(as.data.frame(Titanic)) +
  ggmosaic2::geom_mosaic(
    ggplot2::aes(
      weight = Freq,
      x = ggmosaic2::product(Class, Sex),
      fill = Survived
    )
  )

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
    namespace_build$layout$panel_params[[1]]$x.sec$get_labels(),
    c("No", "Yes", "No", "Yes")
  )
)

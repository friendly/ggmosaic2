#' Theme for mosaic plots
#'
#' Themes set the general aspect of the plot such as the colour of the
#' background, gridlines, the size and colour of fonts.
#' \code{theme_mosaic} provides access to the regular ggplot2 theme, but removes
#' any background, axes ticks, most of the gridlines, and ensures an aspect
#' ratio of 1 for better viewing of the mosaics. This theme also applies a bold
#' face to axes labels and allows for the convenient rotation of category labels.
#'
#' @param base_size
#'   Base font size. Defaults to 11.
#' @param base_family
#'   Base font family. Defaults to \code{""}, which uses the graphics device's default font family.
#' @param rot_labels
#'   The angle (in degrees) used to rotate category labels. Defaults to 0 degrees.
#' @param ...
#'   Additional arguments passed to [ggplot2::theme()]. These are applied after
#'   the mosaic theme defaults and can therefore override them.
#'
#' @examples
#' library(ggmosaic2)
#' data(happy)
#' ggplot(data = happy,
#'        aes(weight = wtssall, x = product(health), fill = happy)) +
#'   geom_mosaic(na.rm = TRUE) +
#'   theme_mosaic()
#'
#' @name theme_mosaic
NULL
#' @export
#' @import ggplot2
theme_mosaic <- function (base_size = 11, base_family = "", rot_labels = 0, ...)
{
  # Match guide_axis() justification for bottom and left axes.
  angle_radians <- rot_labels * pi / 180
  cosine <- sign(round(cos(angle_radians), 3)) / 2 + 0.5
  sine <- sign(round(sin(angle_radians), 3)) / 2 + 0.5

  mosaic_theme <-
    theme_grey(base_size = base_size, base_family = base_family) %+replace%
    theme(
      axis.text = element_text(),
      axis.title = element_text(face = "bold"),
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      panel.background = element_blank(),
      aspect.ratio = 1
    )

  mosaic_theme +
    theme(
      axis.text.x = element_text(
        angle = rot_labels,
        hjust = sine,
        vjust = cosine
      ),
      axis.text.y = element_text(
        angle = rot_labels,
        hjust = cosine,
        vjust = 1 - sine
      ),
      axis.text.x.top = element_text(
        angle = rot_labels,
        hjust = 1 - sine,
        vjust = 1 - cosine
      ),
      axis.text.y.right = element_text(
        angle = rot_labels,
        hjust = 1 - cosine,
        vjust = sine
      )
    ) +
    theme(...)
}

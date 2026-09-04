# Development implementation of the fourfold plot theme.
# Package-ready: this file can be copied to R/ without source-time setup.

#' Theme for fourfold displays
#'
#' `theme_fourfold()` supplies a square, uncluttered panel and responsive
#' typography for [geom_fourfold()]. It also styles facet strips like fourfold
#' stratum headings and provides compact spacing that remains readable in both
#' the RStudio plot pane and exported graphics.
#'
#' @details
#' `base_size` and `base_family` control all text, including the category and
#' count labels drawn inside `geom_fourfold()`. Those labels respond to the
#' physical panel size while retaining a readable lower bound. Additional theme
#' elements passed through `...` are applied last and therefore override the
#' defaults.
#'
#' This theme uses ggplot2's theme-derived geom defaults and requires ggplot2
#' 4.0.0 or later.
#'
#' @param base_size Base font size in points.
#' @param base_family Base font family. The default, `""`, uses the graphics
#'   device's default family.
#' @param ... Additional arguments passed to [ggplot2::theme()]. They are
#'   applied after the fourfold defaults.
#'
#' @return A complete ggplot2 theme.
#'
#' @seealso [geom_fourfold()] and [ggplot2::theme()]
#'
#' @examples
#' ucb <- as.data.frame(UCBAdmissions)
#'
#' ggplot2::ggplot(
#'   ucb,
#'   ggplot2::aes(x = Gender, y = Admit, weight = Freq)
#' ) +
#'   geom_fourfold() +
#'   ggplot2::facet_wrap(ggplot2::vars(Dept), ncol = 3) +
#'   theme_fourfold(base_size = 12)
#'
#' @export
theme_fourfold <- function(base_size = 12, base_family = "", ...) {
  fourfold_theme <- ggplot2::`%+replace%`(
    ggplot2::theme_void(base_size = base_size, base_family = base_family),
    ggplot2::theme(
      aspect.ratio = 1,
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      panel.background = ggplot2::element_rect(fill = "white", colour = NA),
      panel.spacing.x = grid::unit(1.25, "lines"),
      panel.spacing.y = grid::unit(0.7, "lines"),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(
        size = ggplot2::rel(1.25), margin = ggplot2::margin(b = 1)
      ),
      strip.text.y = ggplot2::element_text(angle = 0),
      plot.title = ggplot2::element_text(
        hjust = 0.5, face = "bold", size = ggplot2::rel(5 / 3),
        margin = ggplot2::margin(b = 3)
      ),
      plot.subtitle = ggplot2::element_text(
        hjust = 0.5, margin = ggplot2::margin(b = 3)
      ),
      plot.caption = ggplot2::element_text(hjust = 0.5),
      plot.title.position = "plot",
      plot.margin = ggplot2::margin(8, 12, 8, 12),
      geom = ggplot2::element_geom(
        fontsize = base_size,
        family = base_family,
        linewidth = 0.28
      )
    )
  )

  fourfold_theme + ggplot2::theme(...)
}

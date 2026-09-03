#' Labeling for Mosaic plots.
#'
#' @author Gavin Klorfine
#' @export
#'
#' @description
#' A mosaic plot with text or labels
#'
#' @inheritParams ggplot2::layer
#' @param divider Divider function. The default divider function is mosaic() which will use spines in alternating directions. The four options for partitioning:
#' \itemize{
#' \item \code{vspine} Vertical spine partition: width constant, height varies.
#' \item \code{hspine}  Horizontal spine partition: height constant, width varies.
#' \item \code{vbar} Vertical bar partition: height constant, width varies.
#' \item \code{hbar}  Horizontal bar partition: width constant, height varies.
#' }
#' @param offset Set the fixed gap at the deepest split. Gaps increase by a
#'   factor of 1.5 toward the outermost split.
#' @param na.rm If \code{FALSE} (the default), removes missing values with a warning. If \code{TRUE} silently removes missing values.
#' @param as.label Show as a ggplot label (box with round corners)
#' @param repel Use ggrepel so labels don't overlap
#' @param repel_params List of ggrepel parameters (e.g. list(point.padding = 0))
#' @param check_overlap If `TRUE`, text that overlaps previous text in the
#'   same layer will not be plotted. `check_overlap` happens at draw time and in
#'   the order of the data. Therefore data should be arranged by the label
#'   column before calling `geom_label()` or `geom_text()`.
#' @param display_values Character string specifying what values to display in cells.
#'   Options: "label" (default, factor labels), "observed" (observed counts),
#'   "expected" (expected values from model), "residual" (Pearson residuals).
#'   Use "expected" or "residual" with the \code{expected} parameter.
#' @param format_digits Number of decimal places for formatting numeric values (default: 1).
#'   Only used when display_values is not "label".
#' @param expected Optional loglinear model specification (same as in \code{geom_mosaic}).
#'   Required when using display_values = "expected" or "residual".
#'   Can be a formula, character shortcut, or NULL, and can be inherited from
#'   \code{\link{mosaic_settings}} when omitted.
#' @param ... other arguments passed on to \code{layer}. These are often aesthetics, used to set an aesthetic to a fixed value, like \code{color = 'red'} or \code{size = 3}.
#'   Text aesthetics that can be controlled include: \code{size} (default: 2.7), \code{colour}/\code{color}, \code{fontface} ('plain', 'bold', 'italic', 'bold.italic'),
#'   \code{family} (font family), \code{angle} (rotation in degrees), \code{hjust}/\code{vjust} (justification), and \code{lineheight}.
#'   They may also be parameters to the paired geom/stat.
#' @examples
#' data(titanic)
#'
#' ggplot(data = titanic, aes(x = product(Class), fill = Survived)) +
#'   geom_mosaic() +
#'   geom_mosaic_text()
#'
#' ggplot(data = titanic, aes(x = product(Class, Sex), fill = Survived)) +
#'   geom_mosaic(divider = c("vspine", "hspine", "hspine")) +
#'   geom_mosaic_text(
#'     divider = c("vspine", "hspine", "hspine"), size = 2
#'   )
#'
#' ggplot(data = happy, aes(x = product(happy, health), fill = happy)) +
#'   geom_mosaic(aes(x = product(health)), na.rm = TRUE, show.legend = FALSE) +
#'   geom_mosaic_text(na.rm = TRUE, show.legend = FALSE)
#'
#' # avoid overlapping text
#' ggplot(data = happy, aes(x = product(happy, health), fill = happy)) +
#'   geom_mosaic(aes(x = product(health)), na.rm = TRUE, show.legend = FALSE) +
#'   geom_mosaic_text(na.rm = TRUE, check_overlap = TRUE, show.legend = FALSE)
#'
#' # or use ggrepel
#' ggplot(data = happy, aes(x = product(happy, health), fill = happy)) +
#'   geom_mosaic(aes(x = product(health)), na.rm = TRUE, show.legend = FALSE) +
#'   geom_mosaic_text(na.rm = TRUE, repel = TRUE, show.legend = FALSE)
#'
#' # and as a label
#' ggplot(data = happy, aes(x = product(happy, health), fill = happy)) +
#'   geom_mosaic(aes(x = product(health)), na.rm = TRUE, show.legend = FALSE) +
#'   geom_mosaic_text(
#'     na.rm = TRUE, repel = TRUE, as.label = TRUE,
#'     fill = "white", show.legend = FALSE
#'   )
#'
#' # Display observed counts in cells
#' ggplot(data = titanic, aes(x = product(Class, Sex))) +
#'   geom_mosaic(aes(fill = Survived)) +
#'   geom_mosaic_text(display_values = "observed")
#'
#' # Display residuals with one shared model specification
#' ggplot(data = titanic, aes(x = product(Class, Sex))) +
#'   mosaic_settings(expected = "independence") +
#'   geom_mosaic() +
#'   scale_fill_residual() +
#'   geom_mosaic_text(display_values = "residual",
#'                    format_digits = 2)
#'
#' # Display expected values
#' ggplot(data = titanic, aes(x = product(Class, Sex))) +
#'   mosaic_settings(expected = "independence") +
#'   geom_mosaic() +
#'   scale_fill_residual() +
#'   geom_mosaic_text(display_values = "expected",
#'                    format_digits = 1)
#'
geom_mosaic_text <- function(mapping = NULL, data = NULL, stat = "mosaic",
                             position = "identity", na.rm = FALSE,  divider = mosaic(), offset = 0.01,
                             show.legend = NA, inherit.aes = TRUE, as.label = FALSE, repel = FALSE,
                             repel_params = NULL, check_overlap = FALSE,
                             display_values = "label", format_digits = 1,
                             expected = NULL,
                             ...)
{
  divider_missing <- missing(divider)
  offset_missing <- missing(offset)
  expected_missing <- missing(expected)

  mosaic_layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomMosaicText,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    aesthetics = c("fill", "alpha"),
    params = list(
      na.rm = na.rm,
      divider = if (divider_missing) .mosaic_inherit_setting else divider,
      offset = if (offset_missing) .mosaic_inherit_setting else offset,
      as.label = as.label,
      repel = repel,
      repel_params = repel_params,
      check_overlap = check_overlap,
      display_values = display_values,
      format_digits = format_digits,
      expected = if (expected_missing) .mosaic_inherit_setting else expected,
      ...
    ),
    setting_defaults = list(
      divider = mosaic(),
      offset = 0.01,
      expected = NULL
    )
  )
}

#' Geom proto
#'
#' @format NULL
#' @usage NULL
#' @export
#' @importFrom grid grobTree
#' @importFrom tidyr nest unnest
#' @importFrom dplyr mutate select
#' @importFrom ggrepel GeomTextRepel
#' @importFrom ggrepel GeomLabelRepel
GeomMosaicText <- ggplot2::ggproto(
  "GeomMosaicText", ggplot2::Geom,
  setup_data = function(data, params) {
    #cat("setup_data in GeomMosaic\n")
    #browser()
    data
  },
  required_aes = c("xmin", "xmax", "ymin", "ymax"),
  default_aes = ggplot2::aes(width = 0.1, linetype = "solid", size=2.7,
                             shape = 19, colour = "black",
                             fill = "white", alpha = 1, stroke = 0.1,
                             linewidth=.1, weight = 1, x = NULL, y = NULL, conds = NULL,
                             point.size = NA,
                             segment.linetype = 1, segment.colour = NULL, segment.size = 0.5, segment.alpha = NULL,
                             segment.curvature = 0, segment.angle = 90, segment.ncp = 1,
                             segment.shape = 0.5, segment.square = TRUE, segment.squareShape = 1,
                             segment.inflect = FALSE, segment.debug = FALSE, bg.colour = NA, bg.r = 0.1,
                             angle = 0, hjust = 0.5, vjust = 0.5, family = "", fontface = 1, lineheight = 1.2

  ),
  draw_panel = function(data, panel_scales, coord, as.label, repel, repel_params,
                        check_overlap = FALSE, display_values = "label", format_digits = 1) {
    #cat("draw_panel in GeomMosaic\n")
    if (all(is.na(data$colour)))
      data$colour <- scales::alpha(data$fill, data$alpha) # regard alpha in colour determination

    sub <- subset(data, level==max(data$level))
    text <- subset(sub, .n > 0) # do not label the obs with weight 0

    # Create display text based on display_values parameter
    display_values <- match.arg(display_values, c("label", "observed", "expected", "residual"))

    if (display_values == "label") {
      # Default behavior: use factor labels
      text$display_text <- text$label
    } else if (display_values == "observed") {
      # Display observed counts
      text$display_text <- format(round(text$.n, format_digits), nsmall = format_digits)
    } else if (display_values == "expected") {
      # Display expected values (from model)
      if (!".expected" %in% names(text)) {
        warning("Expected values not available. Supply `expected` to this layer or use `mosaic_settings()`.",
                call. = FALSE)
        text$display_text <- ""
      } else {
        text$display_text <- format(round(text$.expected, format_digits), nsmall = format_digits)
      }
    } else if (display_values == "residual") {
      # Display Pearson residuals
      if (!".residual" %in% names(text)) {
        warning("Residuals not available. Supply `expected` to this layer or use `mosaic_settings()`.",
                call. = FALSE)
        text$display_text <- ""
      } else {
        text$display_text <- format(round(text$.residual, format_digits), nsmall = format_digits)
      }
    }

    text <- tidyr::nest(text, data = -display_text)

    text <-
      dplyr::mutate(
        text,
        coords = purrr::map(data, .f = function(d) {
          data.frame(
            x = (d$xmin + d$xmax)/2,
            y = (d$ymin + d$ymax)/2,
            angle = d$angle[1],
            hjust = d$hjust[1],
            vjust = d$vjust[1],
            alpha = NA,
            family = d$family[1],
            fontface = d$fontface[1],
            lineheight = d$lineheight[1],
            dplyr::select(d, -any_of(c("x", "y", "alpha", "angle", "hjust", "vjust", "family", "fontface", "lineheight")))
          )
        })
      )

    text <- tidyr::unnest(text, coords)

    # Rename display_text to label for GeomText/GeomLabel
    text$label <- text$display_text

    sub$fill <- NA
    sub$colour <- NA
    sub$size <- sub$size/10

    if(!repel) {
      if(!as.label) {
        GeomChosen <- GeomText
        ggplot2:::ggname("geom_mosaic_text", grobTree(
          GeomRect$draw_panel(sub, panel_scales, coord),
          GeomChosen$draw_panel(text, panel_scales, coord, check_overlap = check_overlap)
        ))
      } else if(as.label) {
        GeomChosen <- GeomLabel
        ggplot2:::ggname("geom_mosaic_text", grobTree(
          GeomRect$draw_panel(sub, panel_scales, coord),
          rlang::exec(GeomChosen$draw_panel, text, panel_scales, coord)
        ))
      }
    } else {
      if(!as.label) {
        GeomChosen <- GeomTextRepel
      } else if(as.label) {
        GeomChosen <- GeomLabelRepel
      }
      ggplot2:::ggname("geom_mosaic_text", grobTree(
        GeomRect$draw_panel(sub, panel_scales, coord),
        # GeomChosen$draw_panel(text, panel_scales, coord, !!!repel_params)
        rlang::exec(GeomChosen$draw_panel, text, panel_scales, coord, !!!repel_params)
      ))
    }


  },

  check_aesthetics = function(x, n) {
    #browser()
    ns <- vapply(x, length, numeric(1))
    good <- ns == 1L | ns == n


    if (all(good)) {
      return()
    }

    stop(
      "Aesthetics must be either length 1 or the same as the data (", n, "): ",
      paste(names(!good), collapse = ", "),
      call. = FALSE
    )
  },

  draw_key = ggplot2::draw_key_rect
)

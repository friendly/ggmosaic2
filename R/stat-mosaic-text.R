#' @rdname geom_mosaic
#' @inheritParams ggplot2::stat_identity
#' @section Computed variables:
#' \describe{
#' \item{x}{location of center of the rectangle}
#' \item{y}{location of center of the rectangle}
#' }
#' @export
stat_mosaic_text <- function(mapping = NULL, data = NULL, geom = "Text",
                        position = "identity", na.rm = FALSE,  divider = mosaic(),
                        show.legend = NA, inherit.aes = TRUE, offset = 0.01,
                        expected = NULL, ...)
{
  divider_missing <- missing(divider)
  offset_missing <- missing(offset)
  expected_missing <- missing(expected)

  mosaic_layer(
    data = data,
    mapping = mapping,
    stat = StatMosaicText,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    aesthetics = c("fill", "alpha"),
    params = list(
      na.rm = na.rm,
      divider = if (divider_missing) .mosaic_inherit_setting else divider,
      offset = if (offset_missing) .mosaic_inherit_setting else offset,
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
StatMosaicText <- ggplot2::ggproto(
  "StatMosaicText", ggplot2::Stat,
  #required_aes = c("x"),
  non_missing_aes = "weight",

  setup_params = function(data, params) {
    #cat("setup_params from StatMosaic\n")
    #browser()
    # if (!is.null(data$y)) {
    #   stop("stat_mosaic() must not be used with a y aesthetic.", call. = FALSE)
    # }
    params
  },

  setup_data = function(data, params) {
    #cat("setup_data from StatMosaic\n")
    #browser()

    data
  },

  compute_panel = function(self, data, scales, na.rm=FALSE, divider, offset,
                           expected = NULL, mosaic_spec = NULL) {

    first_stage <- StatMosaic$compute_panel(
      data, scales, na.rm = na.rm, divider = divider, offset = offset,
      expected = expected, mosaic_spec = mosaic_spec
    )

     # if (all(is.na(first_stage$colour)))
       # first_stage$colour <- scales::alpha(first_stage$fill, first_stage$alpha) # regard alpha in colour determination

     # browser()
     sub <- subset(first_stage, level==max(first_stage$level))
       text <- subset(sub, .n > 0) # do not label the obs with weight 0
     text <- tidyr::nest(text, data = -label)

     text <-
       dplyr::mutate(
         text,
         coords = purrr::map(data, .f = function(d) {
           data.frame(
             x = (d$xmin + d$xmax)/2,
             y = (d$ymin + d$ymax)/2,
             #size = 2.88,
             angle = 0,
             hjust = 0.5,
             vjust = 0.5,
             alpha = NA,
             family = "",
             fontface = 1,
             lineheight = 1.2,
             dplyr::select(d, -any_of(c("x", "y", "alpha")))
           )
         })
       )

     text <- tidyr::unnest(text, coords)

     # sub$fill <- NA
     # sub$colour <- NA
     # sub$size <- sub$size/10

     text

  }
)

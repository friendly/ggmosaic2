#' Settings for mosaic plot layers
#'
#' Set the divider, gap size, and model used to calculate expected frequencies
#' for mosaic layers in a plot. A value set directly in a layer takes priority.
#'
#' @param divider A divider function, a character vector naming divider
#'   functions, or a list of divider functions.
#' @param offset A single non-negative number giving the gap at the deepest
#'   split. Gaps increase by a factor of 1.5 toward the outermost split.
#' @param expected The log-linear model used to calculate expected frequencies
#'   and Pearson residuals. Supply a formula or one of `"independence"`,
#'   `"saturated"`, or `"conditional"`. The conditional model requires one or
#'   more variables mapped to `conds`. Supply `NULL` to turn off model fitting,
#'   including a model set by an earlier call to `mosaic_settings()`.
#'
#' @details
#' The position of `mosaic_settings()` among the layers in a plot has no
#' effect. If it is added more than once, the last supplied value for each
#' setting is used; omitted arguments do not change earlier settings.
#'
#' @return An object of class `"ggmosaic_settings"` that can be added to a
#'   ggplot with `+`.
#'
#' @seealso [geom_mosaic()], [geom_mosaic_text()],
#'   [geom_mosaic_jitter()], [mosaic()], and [ddecker()]
#' @author Gavin Klorfine
#' @export
#'
#' @examples
#' data(titanic)
#'
#' ggplot(titanic, aes(x = product(Class, Sex))) +
#'   mosaic_settings(
#'     expected = "independence",
#'     divider = c("vspine", "hspine"),
#'     offset = 0.005
#'   ) +
#'   geom_mosaic() +
#'   geom_mosaic_text(display_values = "residual") +
#'   scale_fill_residual() +
#'   theme_mosaic()
#'

mosaic_settings <- function(divider, offset, expected) {
  values <- list()

  if (!missing(divider)) {
    validate_mosaic_setting_divider(divider)
    values["divider"] <- list(divider)
  }
  if (!missing(offset)) {
    validate_mosaic_setting_offset(offset)
    values["offset"] <- list(offset)
  }
  if (!missing(expected)) {
    validate_mosaic_setting_expected(expected)
    values["expected"] <- list(expected)
  }

  structure(
    list(values = values),
    class = "ggmosaic_settings"
  )
}

validate_mosaic_setting_divider <- function(divider) {
  valid <- is.function(divider) ||
    (is.character(divider) && length(divider) > 0L &&
       !anyNA(divider) && all(nzchar(divider))) ||
    (is.list(divider) && length(divider) > 0L)

  if (!valid) {
    stop(
      "`divider` must be a divider function, a non-empty character ",
      "vector, or a non-empty divider list.",
      call. = FALSE
    )
  }
  invisible(divider)
}

validate_mosaic_setting_offset <- function(offset) {
  if (!is.numeric(offset) || length(offset) != 1L ||
      is.na(offset) || !is.finite(offset) || offset < 0) {
    stop("`offset` must be one finite, non-negative number.", call. = FALSE)
  }
  invisible(offset)
}

validate_mosaic_setting_expected <- function(expected) {
  shortcuts <- c("independence", "saturated", "conditional")
  valid_shortcut <- FALSE
  if (is.character(expected) && length(expected) == 1L && !is.na(expected)) {
    valid_shortcut <- !is.null(tryCatch(
      match.arg(tolower(expected), shortcuts),
      error = function(error) NULL
    ))
  }
  valid <- is.null(expected) ||
    inherits(expected, "formula") ||
    valid_shortcut

  if (!valid) {
    stop(
      "`expected` must be NULL, a formula, or one of ",
      paste(sprintf('"%s"', shortcuts), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  invisible(expected)
}

#' @export
ggplot_add.ggmosaic_settings <- function(object, plot, ...) {
  settings <- plot$ggmosaic2_settings %||% list()
  for (setting in names(object$values)) {
    settings[setting] <- object$values[setting]
  }
  plot$ggmosaic2_settings <- settings
  plot
}

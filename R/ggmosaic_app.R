#' Launch shiny app (deprecated)
#'
#' Shiny app "EDA with Mosaic Plots" for interactive exploratory model building.
#'
#' **Deprecated.** Inherited as-is from the original `ggmosaic` package and kept only for the
#' historical record. It is not maintained, and currently cannot find its app directory because
#' `system.file()` still looks up the old `ggmosaic` package name rather than `ggmosaic2`.
#'
#' @param example Selected shiny app to launch.
#' @param ... arguments passed on.
#'
#' @return Called for its side effect of launching a Shiny app; returns the
#'   result of `shiny::runApp()`.
#' @export
#' @keywords internal
#' @examples
#' \dontrun{
#' # Deprecated and currently non-functional; see Details.
#' ggmosaic_app("mosaics")
#' }
ggmosaic_app <- function(example = c("mosaics", "models"), ...) {
  .Deprecated(
    msg = paste(
      "`ggmosaic_app()` is deprecated. It is inherited as-is from the original `ggmosaic`",
      "package for the historical record, is not maintained, and does not currently work",
      "(it looks up its app directory under the old `ggmosaic` package name)."
    )
  )

  # validate example
  example <- rlang::arg_match(example)

  appDir <- system.file("shiny", example, package = "ggmosaic")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `ggmosaic`.", call. = FALSE)
  }
  getFromNamespace("runApp", asNamespace("shiny"))(appDir, ...)
}

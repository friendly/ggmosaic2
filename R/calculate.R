#' Calculate frequencies.
#'
#' @param data input data frame
#' @param formula formula specifying display of plot
#' @param divider divider function
#' @param cascade cascading amount, per nested layer
#' @param scale_max Logical vector of length 1. If \code{TRUE} maximum values
#'   within each nested layer will be scaled to take up all available space.
#'   If \code{FALSE}, areas will be comparable between nested layers.
#' @param na.rm Logical vector of length 1 - should missing levels be
#'   silently removed?
#' @param offset Numeric value specifying the fixed gap at the deepest split
#'   (default: 0.01). Gaps increase by a factor of 1.5 toward the outermost
#'   split.
#' @param expected Optional. Specification for loglinear model to calculate
#'   residuals. Can be:
#'   \itemize{
#'     \item NULL (default): No model fitting
#'     \item Formula: Custom model specification (e.g., \code{~ A + B} for independence)
#'     \item Character: Shortcut - "independence", "saturated", or "conditional"
#'   }
#'   When specified, adds \code{.expected} and \code{.residual} columns to output.
#' @param area Values used to construct the mosaic rectangles. \code{"observed"}
#'   (the default) uses observed counts. \code{"expected"} uses the fitted
#'   counts from \code{expected} and therefore requires a non-\code{NULL}
#'   \code{expected} specification. Observed counts are retained in \code{.n}
#'   in either case.
#' @param variable_labels Optional named character vector mapping internal
#'   variable names to the expressions shown to users. Used internally by the
#'   ggplot2 layer wrappers.
#' @return A data frame giving rectangle boundaries (\code{l}, \code{r},
#'   \code{b}, \code{t}) and computed frequencies for each partition/cell,
#'   plus \code{.expected}/\code{.residual} columns when \code{expected} is
#'   supplied.
#' @keywords internal
#' @export
#' @examples
#' \dontrun{
#' library(productplots)
#' prodcalc(happy, ~ happy, "hbar", offset = 0.005)
#' prodcalc(happy, ~ happy, "hspine", offset = 0.01)
#' }
prodcalc <- function(data, formula, divider = mosaic(), cascade = 0, scale_max = TRUE,
                     na.rm = FALSE, offset = 0.01, expected = NULL,
                     variable_labels = NULL,
                     area = c("observed", "expected")) {

  vars <- parse_product_formula(stats::as.formula(formula))
  area <- match.arg(area)
  if (identical(area, "expected") && is.null(expected)) {
    stop("`area = \"expected\"` requires a non-NULL `expected` specification.",
         call. = FALSE)
  }
#browser()
  if (length(vars$wt) == 1) {
    data$.wt <- data[[vars$wt]]
  } else {
    data$.wt <- 1
  }
  margin <- getFromNamespace("margin", "productplots")

  all_vars <- c(vars$marg, vars$cond)

  # Keep one row per finest cross-classification throughout model fitting.
  # Geometry can then be calculated from either the observed or fitted count
  # column while .n, .expected, and .residual retain their usual meanings.
  finest <- margin(data, all_vars)
  finest <- dplyr::rename(finest, .n = ".wt")

  if ("weight2" %in% names(data)) {
    point_data <- data
    point_data$.wt <- point_data$weight2
    point_counts <- margin(point_data, all_vars)
    point_counts <- dplyr::rename(point_counts, .n2 = ".wt")
    finest <- dplyr::left_join(finest, point_counts, by = all_vars)
  }

  if (!is.null(expected)) {
    model_formula <- build_model_formula(
      expected, vars$marg, vars$cond,
      variable_labels = variable_labels
    )
    finest <- fit_loglinear_model(
      finest, all_vars, model_formula,
      strict = identical(area, "expected")
    )
  }

  if (identical(area, "expected")) {
    invalid_expected <- !is.finite(finest$.expected) | finest$.expected < 0
    if (any(invalid_expected) || anyNA(finest$.expected)) {
      stop(
        "Expected-area geometry requires one finite, non-negative fitted ",
        "value for every cell.",
        call. = FALSE
      )
    }

    if (length(vars$cond)) {
      group_totals <- stats::aggregate(
        finest[".expected"], finest[vars$cond], sum
      )$.expected
    } else {
      group_totals <- sum(finest$.expected)
    }
    if (any(!is.finite(group_totals) | group_totals <= 0)) {
      stop(
        "Expected-area geometry requires a positive fitted total in every ",
        "conditioning group.",
        call. = FALSE
      )
    }

    data_for_wt <- finest[, c(all_vars, ".expected"), drop = FALSE]
    data_for_wt <- dplyr::rename(data_for_wt, .wt = ".expected")
  } else {
    data_for_wt <- data
  }

  wt <- margin(data_for_wt, vars$marg, vars$cond)
  #browser()
  #wt$.n <- wt2$.wt

  if (na.rm) {
    wt <- wt[stats::complete.cases(wt), ]
  }


  if (is.function(divider)) divider <- divider(ncol(wt) - 1)
  if (is.character(divider)) divider <- lapply(divider, match.fun)

  n_splits <- ncol(wt) - 1L
  if (length(offset) != 1L) {
    stop("`offset` must be a single number.", call. = FALSE)
  }
  # The supplied offset is the innermost gap; each preceding (outer) split
  # is 1.5 times wider.
  offset <- offset * 1.5 ^ rev(seq_len(n_splits) - 1L)

  max_wt <- if (scale_max) NULL else 1

  df <- divide(wt, divider = rev(divider), cascade = cascade, max_wt = max_wt, offset = offset)
#  browser()
  result <- dplyr::left_join(df, finest, by = all_vars)

  result
}

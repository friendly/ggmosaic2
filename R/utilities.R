
"%||%" <- function(a, b) {
  if (!is.null(a)) a else b
}

in_data <- function(data, variable) {
  length(intersect(names(data), variable)) > 0
}

parse_product_formula <- getFromNamespace("parse_product_formula", "productplots")

#' Wrapper for a list
#'
#' @param ... Unquoted variables going into the product plot.
#' @export
#' @examples
#' data(titanic)
#' ggplot(data = titanic) +
#'   geom_mosaic(aes(x = product(Survived, Class), fill = Survived))
product <- function(...) {
  rlang::exprs(...)
}

# Turn a mosaic mapping into ordinary ggplot2 mappings backed by safe,
# syntactic variable names.  Mosaic calculations pass their variables through
# formulas and productplots::margin(), so using expression text (for example,
# "factor(cyl)") as a data-frame column name is not reliable.
prepare_mosaic_mapping <- function(mapping = NULL,
                                   aesthetics = c("fill", "alpha")) {
  if (is.null(mapping)) {
    mapping <- ggplot2::aes()
  }

  if (!is.null(mapping$y)) {
    stop("stat_mosaic() must not be used with a y aesthetic.", call. = FALSE)
  }
  mapping$y <- structure(1L, class = "productlist")

  product_quosures <- function(mapping_quo) {
    if (is.null(mapping_quo)) {
      return(list())
    }

    expr <- rlang::quo_get_expr(mapping_quo)
    if (rlang::is_call(expr) && identical(rlang::call_name(expr), "product")) {
      env <- rlang::quo_get_env(mapping_quo)
      return(lapply(rlang::call_args(expr), rlang::new_quosure, env = env))
    }

    list(mapping_quo)
  }

  same_expression <- function(lhs, rhs) {
    identical(rlang::quo_get_expr(lhs), rlang::quo_get_expr(rhs))
  }

  x_quos <- product_quosures(mapping$x)
  cond_quos <- product_quosures(mapping$conds)
  x_names <- if (length(x_quos)) paste0(".mosaic_x", seq_along(x_quos)) else character()
  cond_names <- if (length(cond_quos)) paste0(".mosaic_cond", seq_along(cond_quos)) else character()

  labels <- stats::setNames(
    c(vapply(x_quos, rlang::as_label, character(1)),
      vapply(cond_quos, rlang::as_label, character(1))),
    c(x_names, cond_names)
  )

  aesthetic_vars <- stats::setNames(vector("list", length(aesthetics)), aesthetics)
  extra_names <- character()
  extra_quos <- list()

  for (aesthetic in aesthetics) {
    aesthetic_quo <- mapping[[aesthetic]]
    if (is.null(aesthetic_quo)) {
      next
    }

    matching_x <- which(vapply(
      x_quos,
      same_expression,
      logical(1),
      rhs = aesthetic_quo
    ))

    if (length(matching_x)) {
      aesthetic_vars[[aesthetic]] <- x_names[[matching_x[[1]]]]
      next
    }

    internal_name <- paste0(".mosaic_", aesthetic)
    # A repeated aesthetic name is not expected, but keep IDs unique if this
    # helper is extended to accept aliases in the future.
    if (internal_name %in% c(x_names, cond_names, extra_names)) {
      internal_name <- paste0(internal_name, length(extra_names) + 1L)
    }
    aesthetic_vars[[aesthetic]] <- internal_name
    extra_names <- c(extra_names, internal_name)
    extra_quos[[internal_name]] <- aesthetic_quo
    labels[[internal_name]] <- rlang::as_label(aesthetic_quo)
  }

  # Preserve the historical partition order: mapped aesthetics that are not
  # already in product() are innermost, followed by the product variables.
  margin_names <- c(extra_names, x_names)

  if (length(x_quos)) {
    mapping$x <- structure(1L, class = "productlist")
  }
  if (length(cond_quos)) {
    mapping$conds <- structure(1L, class = "productlist")
  }

  for (internal_name in names(extra_quos)) {
    mapping[[internal_name]] <- extra_quos[[internal_name]]
  }
  for (i in seq_along(x_names)) {
    mapping[[x_names[[i]]]] <- x_quos[[i]]
  }
  for (i in seq_along(cond_names)) {
    mapping[[cond_names[[i]]]] <- cond_quos[[i]]
  }

  list(
    mapping = mapping,
    spec = list(
      marg = margin_names,
      cond = cond_names,
      axis = c(x_names, cond_names),
      labels = labels,
      aesthetics = aesthetic_vars
    )
  )
}

# Add point mappings to an integrated mosaic-jitter layer without changing
# the variables that define the mosaic cells. A point aesthetic must therefore
# refer to a variable that is already part of x, conds, fill, or alpha.
prepare_integrated_jitter_mapping <- function(mapping, jitter_mapping, spec) {
  if (is.null(jitter_mapping)) {
    spec$jitter_aesthetics <- list()
    return(list(mapping = mapping, spec = spec))
  }
  if (!inherits(jitter_mapping, "uneval")) {
    stop("`jitter_mapping` must be created by `aes()`.", call. = FALSE)
  }

  allowed <- c("colour", "shape", "size", "stroke")
  unsupported <- setdiff(names(jitter_mapping), allowed)
  if (length(unsupported)) {
    stop(
      "Unsupported `jitter_mapping` aesthetic", if (length(unsupported) > 1) "s" else "",
      ": ", paste(unsupported, collapse = ", "),
      ". Supported aesthetics are colour, shape, size, and stroke.",
      call. = FALSE
    )
  }

  labels <- unname(spec$labels)
  jitter_aesthetics <- list()
  for (aesthetic in names(jitter_mapping)) {
    expression_label <- rlang::as_label(jitter_mapping[[aesthetic]])
    matches <- which(labels == expression_label)
    if (!length(matches)) {
      stop(
        "`jitter_mapping` variable `", expression_label,
        "` must also appear in `x`, `conds`, `fill`, or `alpha` so that ",
        "each mosaic cell has one point-aesthetic value.",
        call. = FALSE
      )
    }

    internal_name <- names(spec$labels)[matches[[1]]]
    mapping[[aesthetic]] <- jitter_mapping[[aesthetic]]
    jitter_aesthetics[[aesthetic]] <- internal_name
  }

  spec$jitter_aesthetics <- jitter_aesthetics
  list(mapping = mapping, spec = spec)
}

mosaic_formula <- function(spec, response = "weight") {
  marg <- spec$marg %||% character()
  cond <- spec$cond %||% character()
  rhs <- if (length(marg)) paste(marg, collapse = "+") else "1"

  formula <- paste(response, "~", rhs)
  if (length(cond)) {
    formula <- paste(formula, paste(cond, collapse = "+"), sep = "|")
  }
  stats::as.formula(formula)
}

# ggplot2 discovers extension scale constructors in the plot environment.
# When ggmosaic2 is used only through `::`, its exported scale functions are
# not on the attached search path, so give the plot a private environment in
# which ggplot2 can find them. Attached-package calls can keep returning an
# ordinary Layer object.
add_mosaic_scale_environment <- function(layer) {
  if ("package:ggmosaic2" %in% search()) {
    return(layer)
  }

  structure(list(layer = layer), class = "ggmosaic_namespace_layer")
}

#' @export
ggplot_add.ggmosaic_namespace_layer <- function(object, plot, ...) {
  plot <- ggplot2::ggplot_add(object$layer, plot, ...)

  if (!exists("scale_x_productlist", envir = plot$plot_env,
              mode = "function", inherits = TRUE)) {
    plot$plot_env <- rlang::env(
      plot$plot_env,
      scale_x_productlist = scale_x_productlist,
      scale_y_productlist = scale_y_productlist
    )
  }

  plot
}

is.formula <- function (x) inherits(x, "formula")

is.discrete <- function(x) {
  is.factor(x) || is.character(x) || is.logical(x)
}

product_names <- function() {
  function(x) {
    #cat(" in product_breaks\n")
    #browser()
    unique(x)
  }
}

product_breaks <- function() {
  function(x) {
    #cat(" in product_breaks\n")
    #browser()
    unique(x)
  }
}

product_labels <- function() {
  function(x) {
    #cat(" in product_labels\n")
    #browser()

    unique(x)
  }
}

is.waive <- function(x) inherits(x, "waiver")




## copied from ggplot2
with_seed_null <- function(seed, code) {
  if (is.null(seed)) {
    code
  } else {
    withr::with_seed(seed, code)
  }
}

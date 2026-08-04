
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

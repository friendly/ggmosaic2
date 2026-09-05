
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
#' @return A list of expressions (see [rlang::exprs()]), one per argument,
#'   used inside `aes()` to mark the variables that define the mosaic's
#'   product formula.
#' @export
#' @examples
#' data(titanic)
#' ggplot(data = titanic,
#'        aes(x = product(Survived, Class), fill = Survived)) +
#'   geom_mosaic()
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

# `layer_class` is an internal ggplot2 extension point. Keep the lookup and all
# parent dispatch in one place so compatibility changes are localized.
.ggplot2_layer_parent <- getFromNamespace("Layer", "ggplot2")

.mosaic_inherit_setting <- structure(
  "<inherited>",
  class = "ggmosaic_inherit_setting"
)

is_mosaic_inherit_setting <- function(x) {
  inherits(x, "ggmosaic_inherit_setting")
}

resolve_mosaic_layer_settings <- function(stat_params, defaults,
                                          plot_settings = list()) {
  applicable <- intersect(names(defaults), names(stat_params))
  resolved <- list()

  for (setting in applicable) {
    value <- stat_params[[setting]]
    if (is_mosaic_inherit_setting(value)) {
      if (setting %in% names(plot_settings)) {
        resolved[setting] <- plot_settings[setting]
      } else {
        resolved[setting] <- defaults[setting]
      }
    } else {
      resolved[setting] <- stat_params[setting]
    }
  }

  resolved
}

LayerMosaic <- ggplot2::ggproto(
  "LayerMosaic", .ggplot2_layer_parent,

  setup_layer = function(self, data, plot) {
    data <- ggplot2::ggproto_parent(
      .ggplot2_layer_parent, self
    )$setup_layer(data, plot)

    prepared <- prepare_mosaic_mapping(
      self$computed_mapping,
      self$mosaic_aesthetics
    )
    self$computed_mapping <- prepared$mapping
    self$mosaic_computed_spec <- prepared$spec
    self$mosaic_resolved_settings <- resolve_mosaic_layer_settings(
      self$stat_params,
      self$mosaic_setting_defaults,
      plot$ggmosaic2_settings %||% list()
    )

    data
  },

  compute_statistic = function(self, data, layout) {
    original_params <- self$stat_params
    on.exit(self$stat_params <- original_params, add = TRUE)

    resolved_params <- original_params
    for (setting in names(self$mosaic_resolved_settings)) {
      resolved_params[setting] <- self$mosaic_resolved_settings[setting]
    }

    if ("mosaic_spec" %in% self$stat$parameters(TRUE)) {
      resolved_params["mosaic_spec"] <- list(self$mosaic_computed_spec)
    }
    self$stat_params <- resolved_params

    ggplot2::ggproto_parent(
      .ggplot2_layer_parent, self
    )$compute_statistic(data, layout)
  }
)

# Construct an ordinary ggplot2 layer immediately. Mosaic mappings and shared
# settings are resolved later, in LayerMosaic$setup_layer(), when the final
# plot mapping and metadata are available.
mosaic_layer <- function(data, mapping, stat, geom, position, show.legend,
                         inherit.aes, aesthetics, params,
                         setting_defaults = list()) {
  layer <- ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    check.aes = FALSE,
    layer_class = LayerMosaic,
    params = params
  )
  layer$mosaic_aesthetics <- aesthetics
  layer$mosaic_setting_defaults <- setting_defaults
  layer
}

#' @export
ggplot_add.LayerMosaic <- function(object, plot, ...) {
  plot <- NextMethod()

  # ggplot2 discovers extension scale constructors in the plot environment.
  # Install them privately so namespace-only calls work without attaching the
  # package. This is harmless when the package is attached as well.
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

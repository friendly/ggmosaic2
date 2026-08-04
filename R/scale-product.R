#' Helper function for determining scales
#'
#' Used internally to determine class of variable x
#' @param x variable
#' @return character string "productlist"
#' @importFrom ggplot2 scale_type
#' @export
scale_type.productlist <- function(x) {
  #  cat("checking for type productlist\n")
  #browser()
  "productlist"
}




#' Determining scales for mosaics
#'
#' @param name set to pseudo waiver function `product_names` by default.
#' @inheritParams ggplot2::continuous_scale
#' @export
scale_x_productlist <- function(name = ggplot2::waiver(), breaks = product_breaks(),
                                minor_breaks = NULL, labels = product_labels(),
                                limits = NULL, expand = ggplot2::waiver(), oob = scales::censor,
                                na.value = NA_real_, transform = "identity",
                                position = "bottom", sec.axis = ggplot2::waiver()) {
  #browser()
  sc <- ggplot2::continuous_scale(
    c("x", "xmin", "xmax", "xend", "xintercept", "xmin_final", "xmax_final", "xlower", "xmiddle", "xupper"),
    palette = identity, name = name, breaks = breaks,
    minor_breaks = minor_breaks, labels = labels, limits = limits,
    expand = expand, oob = oob, na.value = na.value, transform = transform,
    guide = ggplot2::waiver(), position = position, super = ScaleContinuousProduct
  )

  set_product_sec_axis(sc, sec.axis)
}

#' @rdname scale_x_productlist
#' @param sec.axis specify a secondary axis. By default, category labels for
#'   the inner variables of the mosaic are displayed on the opposite (top or
#'   right) side whenever more than one variable is split along a direction.
#'   Set to \code{NULL} to suppress these labels, or supply a
#'   \code{\link[ggplot2]{sec_axis}} for full control.
#' @export
scale_y_productlist <- function(name = ggplot2::waiver(), breaks = product_breaks(),
                                minor_breaks = NULL, labels = product_labels(),
                                limits = NULL, expand = ggplot2::waiver(), oob = scales::censor,
                                na.value = NA_real_, transform = "identity",
                                position = "left", sec.axis = ggplot2::waiver()) {
  #browser()
  sc <- ggplot2::continuous_scale(
    c("y", "ymin", "ymax", "yend", "yintercept", "ymin_final", "ymax_final", "ylower", "ymiddle", "yupper"),
    palette = identity, name = name, breaks = breaks,
    minor_breaks = minor_breaks, labels = labels, limits = limits,
    expand = expand, oob = oob, na.value = na.value, transform = transform,
    guide = ggplot2::waiver(), position = position, super = ScaleContinuousProduct
  )

  set_product_sec_axis(sc, sec.axis)
}

# Apply the sec.axis argument of scale_*_productlist() to the scale.
# A waiver keeps the automatic top/right category labels, NULL suppresses
# them, and a formula or sec_axis() specifies a secondary axis manually.
set_product_sec_axis <- function(sc, sec.axis) {
  if (is.null(sec.axis)) {
    sc$sec_disabled <- TRUE
    return(sc)
  }
  if (!is.waive(sec.axis)) {
    if (is.formula(sec.axis)) sec.axis <- ggplot2::sec_axis(sec.axis)
    is.sec_axis <- getFromNamespace("is.sec_axis", "ggplot2")
    if (!is.sec_axis(sec.axis)) {
      stop("Secondary axes must be specified using 'sec_axis()' or NULL", call. = FALSE)
    }
    sc$secondary.axis <- sec.axis
  }
  sc
}

# Strip the internal aesthetic prefixes off variable names used in scales.
product_clean_name <- function(x) {
  x <- gsub("x__alpha__", "", x)
  x <- gsub("x__fill__", "", x)
  x <- gsub("x__", "", x)
  gsub("conds\\d+__", "", x)
}

# Compute the position scales for a mosaic, including the category labels
# that belong on the opposite (top/right) sides of the display.
#
# `res` must be the full prodcalc() result (all levels, with l/r/b/t
# columns), `formula` the product formula, and `divider` the vector of
# dividers aligned with c(marg, cond) in formula order (innermost first).
# `axis_vars` identifies the variables explicitly mapped through x or conds;
# variables added only to support non-position aesthetics remain part of the
# partition but are not shown on the position axes. A NULL value preserves the
# legacy internal behaviour of labelling every formula variable.
#
# The outermost variable of each direction keeps the primary (bottom/left)
# axis; any inner variables of the same direction are labelled along the
# top/right, vcd-style, at the midpoints of the rectangles that touch that
# side. The secondary information is stashed on the scale objects
# (sec_name/sec_breaks/sec_labels) and picked up in
# ScaleContinuousProduct$train().
product_scales <- function(res, formula, divider, labels = NULL,
                           axis_vars = NULL) {
  prs <- parse_product_formula(formula)
  cols <- c(prs$marg, prs$cond) # innermost variable first
  p <- length(cols)
  eps <- 1e-6

  if (is.null(axis_vars)) {
    axis_vars <- cols
  }
  axis_idx <- which(cols %in% axis_vars)

  display_name <- function(column) {
    if (!is.null(labels) && column %in% names(labels)) {
      return(unname(labels[[column]]))
    }
    product_clean_name(column)
  }

  axis_info <- function(dir) {
    direction_idx <- grep(dir, divider)
    if (length(direction_idx) == 0) {
      breaks <- seq(0, 1, length.out = 5)
      return(list(name = "", breaks = breaks, labels = round(breaks, 2),
                  sec_name = NULL, sec_breaks = NULL, sec_labels = NULL))
    }

    idx <- intersect(direction_idx, axis_idx)
    if (length(idx) == 0) {
      return(list(name = "", breaks = numeric(), labels = character(),
                  sec_name = NULL, sec_breaks = NULL, sec_labels = NULL))
    }

    # the outermost variable of this direction is labelled along the
    # primary axis, next to the rectangles that touch the bottom/left edge
    outer <- max(idx)
    prim <- res[res$level == p - outer + 1, ]
    if (dir == "h") {
      prim <- prim[prim$b < eps, ]
      prim <- prim[prim$r - prim$l > eps, ]
      prim$pos <- (prim$l + prim$r) / 2
    } else {
      prim <- prim[prim$l < eps, ]
      prim <- prim[prim$t - prim$b > eps, ]
      prim$pos <- (prim$b + prim$t) / 2
    }
    prim <- prim[order(prim$pos), ]
    info <- list(name = display_name(cols[outer]), breaks = prim$pos,
                 labels = as.character(prim[[cols[outer]]]),
                 sec_name = NULL, sec_breaks = NULL, sec_labels = NULL)

    # inner variables of the same direction are labelled along the
    # opposite side, next to the rectangles that touch the top/right edge
    inner <- setdiff(idx, outer)
    if (length(inner) > 0) {
      sec <- res[res$level == max(res$level), ]
      if (dir == "h") {
        sec <- sec[sec$t > max(sec$t) - eps, ]
        sec <- sec[sec$r - sec$l > eps, ]
        sec$pos <- (sec$l + sec$r) / 2
      } else {
        sec <- sec[sec$r > max(sec$r) - eps, ]
        sec <- sec[sec$t - sec$b > eps, ]
        sec$pos <- (sec$b + sec$t) / 2
      }
      sec <- sec[order(sec$pos), ]
      labels <- do.call(paste, c(unname(sec[cols[inner]]), sep = ":"))
      info$sec_name <- paste(vapply(cols[inner], display_name, character(1)),
                             collapse = ":")
      info$sec_breaks <- sec$pos
      info$sec_labels <- labels
    }
    info
  }

  make_scale <- function(scale_fun, info) {
    sc <- scale_fun(info$name, breaks = info$breaks, labels = info$labels)
    sc$sec_name <- info$sec_name
    sc$sec_breaks <- info$sec_breaks
    sc$sec_labels <- info$sec_labels
    sc
  }

  list(x = make_scale(ggplot2::scale_x_continuous, axis_info("h")),
       y = make_scale(ggplot2::scale_y_continuous, axis_info("v")))
}


#' @rdname scale_x_productlist
#' @export
ScaleContinuousProduct <- ggproto(
  "ScaleContinuousProduct", ScaleContinuousPosition,
  train =function(self, x) {
    #cat("train in ScaleContinuousProduct\n")
    #cat("class of variable: ")
    #cat(class(x))
    #browser()
    if (is.list(x)) {
      x <- x[[1]]
      if ("Scale" %in% class(x)) {
        #browser()
        # re-assign the scale values now that we have the information - but only if necessary
        if (is.function(self$breaks)) self$breaks <- x$breaks
        if (is.function(self$labels)) self$labels <- x$labels
        if (is.waive(self$name)) {
          self$product_name <- product_clean_name(x$name)
        }
        # category labels for inner variables go on the opposite (top/right)
        # side, unless a secondary axis was supplied or suppressed (NULL)
        if (!is.null(x$sec_breaks) && is.waive(self$secondary.axis) &&
            !isTRUE(self$sec_disabled)) {
          self$secondary.axis <- ggplot2::sec_axis(
            ~., name = product_clean_name(x$sec_name),
            breaks = x$sec_breaks, labels = x$sec_labels
          )
        }
        #cat("\n")
        return()
      }
    }
    if (is.discrete(x)) {
      self$range$train(x=c(0,1))
      #cat("\n")
      return()
    }
    self$range$train(x)
    #cat("\n")
  },
  map = function(self, x, limits = self$get_limits()) {
    #cat("map in ScaleContinuousProduct\n")
    #browser()
    if (is.discrete(x)) return(x)
    if (is.list(x)) return(0) # need a number
    scaled <- as.numeric(self$oob(x, limits))
    ifelse(!is.na(scaled), scaled, self$na.value)
  },
  dimension = function(self, expand = c(0, 0)) {
    #cat("dimension in ScaleContinuousProduct\n")
    c(-0.05,1.05)
  },
  make_title = function(guide, scale, label, self) {
    # In ggplot2 4.0+, make_title has three arguments: guide, scale, label
    title <- ggproto_parent(ScaleContinuousPosition, self)$make_title(guide, scale, label)
    if (isTRUE(title %in% self$aesthetics)) {
      title <- self$product_name
    }
    else title
  }
)

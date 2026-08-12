# Script from @neuwirthe on GH, issue #78 from haleyjeppson/ggmosaic

library(tidyverse)
library(scales)
library(ggmosaic2)

in_data <-
  structure(list(
    CYCLE = structure(c(
      1L, 1L, 1L, 1L, 1L, 1L, 1L,
      1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 2L, 2L, 2L,
      2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L,
      2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L
    ), levels = c(
      "Zyklus 1",
      "Zyklus 2"
    ), class = "factor"), COUNTRY = structure(c(
      1L, 1L,
      1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L,
      2L, 2L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L,
      2L, 2L, 2L, 2L, 2L, 2L, 3L, 3L, 3L, 3L, 3L, 3L, 3L, 3L, 3L, 3L
    ), levels = c("Österreich", "Deutschland", "Schweiz"), class = "factor"),
    GENDER = structure(c(
      1L, 1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L,
      2L, 1L, 1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L, 2L, 1L, 1L, 1L, 1L,
      1L, 2L, 2L, 2L, 2L, 2L, 1L, 1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L,
      2L, 1L, 1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L, 2L
    ), levels = c(
      "Weiblich",
      "Männlich"
    ), class = "factor"), AGE = structure(c(
      1L, 2L,
      3L, 4L, 5L, 1L, 2L, 3L, 4L, 5L, 1L, 2L, 3L, 4L, 5L, 1L, 2L,
      3L, 4L, 5L, 1L, 2L, 3L, 4L, 5L, 1L, 2L, 3L, 4L, 5L, 1L, 2L,
      3L, 4L, 5L, 1L, 2L, 3L, 4L, 5L, 1L, 2L, 3L, 4L, 5L, 1L, 2L,
      3L, 4L, 5L
    ), levels = c(
      "<=24", "25-34", "35-44", "45-54",
      "55 plus"
    ), class = "factor"), n = c(
      450L, 479L, 557L, 607L,
      507L, 448L, 479L, 560L, 581L, 462L, 532L, 501L, 571L, 679L,
      506L, 537L, 493L, 553L, 630L, 463L, 356L, 461L, 472L, 495L,
      676L, 366L, 389L, 426L, 407L, 517L, 365L, 497L, 484L, 484L,
      607L, 381L, 466L, 499L, 431L, 579L, 482L, 637L, 737L, 759L,
      746L, 485L, 632L, 687L, 689L, 794L
    )
  ), class = c(
    "tbl_df",
    "tbl", "data.frame"
  ), row.names = c(NA, -50L))

p <- in_data |>
  ggplot() +
  geom_mosaic(aes(weight = n, x = product(AGE, COUNTRY), fill = AGE)) +
  facet_mosaic_grid(. ~ CYCLE) +
  guides(fill = "none")

issue78_build <- ggplot_build(p)
p_mosaic <- p + theme_mosaic()
stopifnot(
  length(issue78_build$layout$panel_scales_x) == 2L,
  length(issue78_build$layout$panel_scales_y) == 2L,
  isTRUE(all.equal(
    issue78_build$layout$panel_scales_x[[1]]$breaks,
    c(0.2348325, 0.7348325),
    tolerance = 1e-6
  )),
  isTRUE(all.equal(
    issue78_build$layout$panel_scales_x[[2]]$breaks,
    c(0.1383247, 0.4368827, 0.7985580),
    tolerance = 1e-6
  )),
  !isTRUE(all.equal(
    issue78_build$layout$panel_scales_y[[1]]$breaks,
    issue78_build$layout$panel_scales_y[[2]]$breaks
  )),
  inherits(ggplotGrob(p_mosaic), "gtable")
)

ggsave("issues/issue78.png", p, dpi = 300)
ggsave(
  "issues/issue78-theme-mosaic.png",
  p_mosaic,
  width = 10,
  height = 7,
  dpi = 300
)

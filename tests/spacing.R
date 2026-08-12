library(ggmosaic2)

spacing_data <- expand.grid(
  A = factor(c("a1", "a2")),
  B = factor(c("b1", "b2")),
  C = factor(c("c1", "c2"))
)
spacing_data$Freq <- 1

spacing_result <- prodcalc(
  spacing_data,
  Freq ~ A + B + C,
  offset = 0.01
)

outer <- subset(spacing_result, level == 1)
outer <- outer[order(outer$l), ]
outer_gap <- outer$l[2] - outer$r[1]

middle <- subset(spacing_result, level == 2 & C == "c1")
middle <- middle[order(middle$b), ]
middle_gap <- middle$b[2] - middle$t[1]

inner <- subset(spacing_result, level == 3 & C == "c1" & B == "b1")
inner <- inner[order(inner$l), ]
inner_gap <- inner$l[2] - inner$r[1]

stopifnot(
  isTRUE(all.equal(outer_gap, 0.0225, tolerance = 1e-10)),
  isTRUE(all.equal(middle_gap, 0.015, tolerance = 1e-10)),
  isTRUE(all.equal(inner_gap, 0.01, tolerance = 1e-10))
)

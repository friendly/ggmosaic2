# Procedural weathered-paper texture, base R only.
# Returns a raster (matrix of hex colours) of size h x w.

# Smooth value noise: random lattice, bilinear upsampled, several octaves.
value_noise <- function(h, w, cells, octaves = 4, persistence = 0.5) {
  out <- matrix(0, h, w)
  amp <- 1
  total <- 0
  for (o in seq_len(octaves)) {
    nr <- ceiling(cells * 2^(o - 1) * h / max(h, w)) + 2
    nc <- ceiling(cells * 2^(o - 1) * w / max(h, w)) + 2
    g <- matrix(stats::runif(nr * nc), nr, nc)
    yi <- seq(1, nr - 1, length.out = h)
    xi <- seq(1, nc - 1, length.out = w)
    y0 <- floor(yi); x0 <- floor(xi)
    fy <- yi - y0; fx <- xi - x0
    # smoothstep weights avoid visible lattice creases
    fy <- fy * fy * (3 - 2 * fy); fx <- fx * fx * (3 - 2 * fx)
    a <- g[y0, x0]; b <- g[y0, x0 + 1]
    c <- g[y0 + 1, x0]; d <- g[y0 + 1, x0 + 1]
    top <- a + (b - a) * rep(fx, each = h)
    bot <- c + (d - c) * rep(fx, each = h)
    out <- out + amp * (top + (bot - top) * fy)
    total <- total + amp
    amp <- amp * persistence
  }
  out / total
}

paper_texture <- function(w = 1600, h = 1200, seed = 1879,
                          base = "#efe4c9", stain = "#b98f52",
                          edge = "#8a6436", rust = "#9b5a2c", fold = TRUE) {
  set.seed(seed)
  base_rgb  <- grDevices::col2rgb(base)[, 1] / 255
  stain_rgb <- grDevices::col2rgb(stain)[, 1] / 255
  edge_rgb  <- grDevices::col2rgb(edge)[, 1] / 255
  rust_rgb  <- grDevices::col2rgb(rust)[, 1] / 255

  # 1. large, soft discolouration (tide marks, uneven ageing)
  blotch <- value_noise(h, w, cells = 3, octaves = 5, persistence = 0.55)
  blotch <- pmax(0, (blotch - 0.45) / 0.55)^1.6

  # 2. fine fibre grain
  grain <- value_noise(h, w, cells = 90, octaves = 2, persistence = 0.6) - 0.5
  speck <- matrix(stats::rnorm(h * w, 0, 1), h, w)

  # 3. foxing: scattered small rust spots with soft edges
  yy <- matrix(rep(seq_len(h), w), h, w)
  xx <- matrix(rep(seq_len(w), each = h), h, w)
  # (a crisp rust core with a faint halo; drawn only in a local window)
  fox <- matrix(0, h, w)
  n_fox <- 70
  cx <- stats::runif(n_fox, 1, w); cy <- stats::runif(n_fox, 1, h)
  r  <- stats::rexp(n_fox, 1 / 2.2) + 1
  for (i in seq_len(n_fox)) {
    rows <- max(1, floor(cy[i] - 6 * r[i])):min(h, ceiling(cy[i] + 6 * r[i]))
    cols <- max(1, floor(cx[i] - 6 * r[i])):min(w, ceiling(cx[i] + 6 * r[i]))
    d2 <- outer((rows - cy[i])^2, (cols - cx[i])^2, `+`) / r[i]^2
    spot <- stats::runif(1, 0.35, 0.8) * exp(-d2^1.5) + 0.08 * exp(-d2 / 9)
    fox[rows, cols] <- pmax(fox[rows, cols], spot)
  }

  # 4. darker, browner margins (vignette), irregular via noise
  ux <- (xx - 1) / (w - 1); uy <- (yy - 1) / (h - 1)
  dist_edge <- pmin(ux, 1 - ux, uy * h / w, (1 - uy) * h / w)
  wobble <- value_noise(h, w, cells = 6, octaves = 3) * 0.035
  vign <- pmax(0, 1 - (dist_edge + wobble) / 0.09)^2.2

  # 5. faint vertical fold crease (Album plates were folded sheets)
  crease <- matrix(0, h, w)
  if (fold) {
    fx <- 0.5 + (value_noise(h, 1, cells = 4, octaves = 2)[, 1] - 0.5) * 0.004
    dx <- ux - fx[yy]
    crease <- 0.10 * exp(-(dx / 0.0025)^2) - 0.05 * exp(-((dx - 0.004) / 0.004)^2)
  }

  mix <- function(ch) {
    v <- base_rgb[ch] +
      blotch * 0.7 * (stain_rgb[ch] - base_rgb[ch]) +
      fox    * (rust_rgb[ch] - base_rgb[ch]) +
      vign   * 0.75 * (edge_rgb[ch] - base_rgb[ch]) +
      grain  * 0.06 + speck * 0.012 - crease
    pmin(1, pmax(0, v))
  }
  grDevices::rgb(mix(1), mix(2), mix(3)) |>
    matrix(h, w) |>
    grDevices::as.raster()
}

# A ggplot2 background element that fills with the texture.
paper_background <- function(...) {
  tex <- paper_texture(...)
  grid::pattern(
    grid::rasterGrob(tex, width = grid::unit(1, "npc"),
                     height = grid::unit(1, "npc"), interpolate = TRUE),
    extend = "pad"
  )
}

Draft replies to post back on
https://github.com/ggplot2-extenders/ggplot-extension-club/discussions/134

Two separate comments, per the plan in `staging.md`: a short one making the main point
(ggmosaic2 exists, working toward CRAN), and a follow-up with the details. Edit before
posting -- these are a first pass.

---

## Reply 1 (main point)

Update on this: My student Gavin & I went ahead and did it! `

ggmosaic2` v. 0.5.1 is up on R-universe
(https://friendly.r-universe.dev/ggmosaic2) and on GitHub
(https://github.com/friendly/ggmosaic2), with pkgdown documentation (https://friendly.github.io/ggmosaic2/index.html).

So, I'm working toward a CRAN submission. But I want to avoid stepping on toes, so this is still in a holding pattern.

Never heard back from Haley, Heike, or Di after the emails, so I kept the original PR's
work (haleyjeppson/ggmosaic#86), fully crediting all three as authors. We built on it from there rather than let it sit as abandoned.
Details are the next comment, for anyone who wants them. Any guidance from gg-extenders is welcome
in this unusual and somewhat tricky situation.

## Reply 2 (details)

A few specifics, for anyone still following this thread.

The compatibility break that got `ggmosaic` pulled from CRAN is fixed, obviously -- but
that was really the smaller part of it. We also cleared out a handful of longstanding open
issues on the original repo: 

* haleyjeppson/ggmosaic#39 (fill/alpha/jitter variables no longer force themselves onto the product axes), 
* haleyjeppson/ggmosaic#78 (facet-specific product-axis ticks, via a new `facet_mosaic_grid()`), 
* haleyjeppson/ggmosaic#59 (computed aesthetics like `fill = factor(cyl)` now work inside`product()`), 
* haleyjeppson/ggmosaic#77 (factor ordering, e.g. from `forcats::fct_inorder()`, is respected), and
* haleyjeppson/ggmosaic#82 (fully-qualified calls like `ggmosaic2::geom_mosaic()` without attaching the package).

Beyond the bug fixes, the residual-shading work from my original PR is still the core of
it -- fit a loglinear model, shade tiles by Pearson residuals, same idea as `vcd`'s
strucplot shading but inside a `ggplot2` layer. 

There's also a jittered-point overlay now
(`geom_mosaic_jitter()`), so you can show individual observations on top of the shaded
tiles -- @EvaMaeRey, that's the "ideal gas law" one you noticed in the code I posted back in
January, now with a proper `geom_`.

Three vignettes cover this: one on what's new/changed relative to `ggmosaic`, one on the
loglinear/residual-shading side, and one just on the three ways frequency data shows up
(table, frequency, case form) and converting between them, since that trips people up.

Authors@R still lists Haley, Heike, and Di as authors, and the original R Journal paper
(Jeppson & Hofmann, 2023) is still the primary citation for the package -- that doesn't
change just because I forked it

```
> citation("ggmosaic2")
To cite package ‘ggmosaic2’ in publications use:

  Friendly M, Klorfine G, Jeppson H, Hofmann H, Cook D (2026). _ggmosaic2: Mosaic Plots in the 'ggplot2' Framework, Extended_. R package version 0.5.1,
  <https://friendly.github.io/ggmosaic2/>.

  Jeppson & Hofmann, "The R Journal: Generalized Mosaic Plots in the ggplot2 Framework", The R Journal, 2023
```

I will of course contact Haley, Heike, and Di before going further, but thought it prudent to run this by gg-extenders
because this is such an unusual situation.


@teunbrand, re: the GPL 2+ point from earlier -- yes, kept that.

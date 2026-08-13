# Issue #59 from `haleyjeppson/ggmosaic`

## Written by @GegznaV

In contrast to `ggplot2`, it seems that `ggmosaic` does not support variables created on the fly:

``` r
library(tidyverse)
library(ggmosaic)

# OK: fill = cyl
ggplot(datasets::mtcars) +
  geom_mosaic(aes(x = product(gear), fill = cyl)) +
  scale_fill_discrete()
```

![](https://i.imgur.com/GkINGbc.png)

``` r
# FAILURE: fill = factor(cyl)
ggplot(datasets::mtcars) +
  geom_mosaic(aes(x = product(gear), fill = factor(cyl))) +
  scale_fill_discrete()
#> Warning: Computation failed in `stat_mosaic()`:
#> undefined columns selected
```

![](https://i.imgur.com/veJrIIh.png)

``` r
# FAILURE: fill = log(cyl)
ggplot(datasets::mtcars) +
  geom_mosaic(aes(x = product(gear), fill = log(cyl))) +
  scale_fill_discrete()
#> Warning: Computation failed in `stat_mosaic()`:
#> undefined columns selected
```

![](https://i.imgur.com/SUnH44u.png)

``` r
# OK: log is pre-computed
datasets::mtcars %>% 
  mutate(log_cyl = log(cyl)) %>% 
  ggplot() +
  geom_mosaic(aes(x = product(gear), fill = log_cyl)) +
  scale_fill_discrete()
```

![](https://i.imgur.com/lUfddKP.png)

<sup>Created on 2021-12-23 by the [reprex package](https://reprex.tidyverse.org) (v2.0.1)</sup>

Could  `ggmosaic` support this kind of functionality? Or at least a more specific error message be issued to indicate what is the real issue?

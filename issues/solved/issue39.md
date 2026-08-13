# Issue #39 from `haleyjeppson/ggmosaic`

## Written by @richierocks

The variable used for the fill color shows up in labels on the x-axis. I'm not sure if it is ever desirable for that to happen, but here's an example where it isn't.

I thought it would be useful to show a confusion matrix using a mosaic plot. Here's a reproducible example. 

``` r
library(dplyr)
library(ggplot2)
library(ggmosaic)

# Some sample data
set.seed(19790801)
actual <- iris$Species
predictions <- sample(iris$Species)

confusion <- table(actual, predictions) %>% 
  as.data.frame() %>% 
  mutate(
    is_correct = ifelse(
      actual == predictions, 
      "Correct prediction", 
      "Incorrect prediction"
    )
  )

ggplot(confusion) +
  geom_mosaic(
    aes(
      weight = Freq, 
      x = product(actual, predictions), 
      fill = is_correct
    )
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
```

![](https://i.imgur.com/P8tFIAV.png)

I expected the x-axis labels to be levels of`actual` (setosa/versicolor/virginica), but they are actually combinations of `is_correct` (Correct prediction/Incorrect prediction) and `predictions` (setosa/versicolor/virginica).

- Is this a bug?
- Did I just specify the aesthetics incorrectly?
- Is it possible to not show fill aesthetic values in x-axis labels?

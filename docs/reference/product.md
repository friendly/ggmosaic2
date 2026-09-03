# Wrapper for a list

Wrapper for a list

## Usage

``` r
product(...)
```

## Arguments

- ...:

  Unquoted variables going into the product plot.

## Examples

``` r
data(titanic)
ggplot(data = titanic,
       aes(x = product(Survived, Class), fill = Survived)) +
  geom_mosaic()
```

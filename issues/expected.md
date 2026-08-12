# Expected-area mosaics with jittered observations

## Issue

The README claims that jittered points reveal departures from independence
through varying point density. That is not true for the current example:

- Mosaic cell area is proportional to the observed count, \(O_i\).
- The jitter layer draws \(O_i\) points in that cell.
- Therefore, density \(O_i / A_i\) is theoretically constant.

Any visible density differences arise from random jitter, overlap, gaps, and
point padding rather than from the fitted model. Only the residual shading
currently represents model departure.

For point density to be meaningful, cell area should instead be proportional
to the model's expected count, \(E_i\), while retaining \(O_i\) observed
points. Density would then be proportional to \(O_i / E_i\).

This construction also needs to account for consistency between layers, zero
cells, weights, gaps, overplotting, and large counts.

## Open API question

Should this be expressed through an explicit option such as `area =
"expected"`, used consistently by both the mosaic and jitter layers, while
`expected` selects the loglinear model?

```r
geom_mosaic(
  aes(x = product(Sex, Eye, Hair)),
  expected = "independence",
  area = "expected"
) +
geom_mosaic_jitter(
  aes(x = product(Sex, Eye, Hair)),
  expected = "independence",
  area = "expected"
)
```

Alternatively, should the API coordinate the two layers through a helper or
some other mechanism? In particular, adding a jitter layer should not silently
change the construction of another layer.

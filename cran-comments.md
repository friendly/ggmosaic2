
## Test environments
* local Windows 11, R version 4.6.1 (2026-06-24 ucrt)
* local Mac OS [GK]
* ubuntu 16.04 (on travis-ci), R 3.6.3
* win-builder (R Under development (unstable), 2026-08-31 r90457 ucrt)

## R CMD check results

0 errors | 0 warnings | 1 note

* Possibly misspelled words in DESCRIPTION: ggmosaic. This is the name of
  the predecessor CRAN package that 'ggmosaic2' extends (mentioned by name
  in the Description text); the spelling is correct. Fixed by single-quoting
  'ggmosaic' rather than backtick-quoting it, matching this DESCRIPTION's
  existing convention for 'ggplot2'/'mosaic' -- CRAN's DESCRIPTION spell
  check skips single-quoted terms.

## ggmosaic 0.5.1

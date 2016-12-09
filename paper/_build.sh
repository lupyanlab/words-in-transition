#!/bin/sh

Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"
open _book/index.html

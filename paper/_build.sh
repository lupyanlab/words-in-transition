#!/bin/sh
open_after=false

while getopts ":oc" opt; do
  case $opt in
    o)
      open_after=true
      ;;
    c)
      rm -rf .cache/ figs/
      ;;
  esac
done

Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"

if [ "$open_after" = true ]; then
  open _book/index.html
fi
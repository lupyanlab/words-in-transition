#!/bin/sh

Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"

while getopts ":o" opt; do
  case $opt in
    o)
      open _book/index.html
      ;;
  esac
done
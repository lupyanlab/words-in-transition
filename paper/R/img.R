library(grid)
library(png)
library(magrittr)


img <- function(png_stem, ...) {
  grid.newpage()
  paste0(png_stem, ".png") %>%
    file.path("img", .) %>%
    readPNG() %>%
    rasterGrob(...) %T>%
    grid.draw()
}
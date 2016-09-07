#' @export
find_extdata <- function(name, ext) {
  data_file <- paste0(name, ext)
  data_path <- system.file("extdata", data_file, package = "wordsintransition")
  if (!file.exists(data_path)) stop("File '", data_file, "' not found in extdata")
  data_path
}

#' @export
find_graphviz <- function(name) {
  find_extdata(name, ext = ".gv")
}

#' @importFrom knitr read_chunk
#' @export
read_all_graphviz_chunks <- function() {
  chunks <- c("design", "transition-wordlike", "games", "transcriptions",
              "category-match", "category-match-true-seed", "specific-match")
  for (chunk in chunks) {
    chunk_path <- find_graphviz(chunk)
    read_chunk(chunk_path, labels = chunk)
  }

}

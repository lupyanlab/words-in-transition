#' Read all available knitr chunks in the wordsintransition package.
#' @importFrom crotchet read_all_graphviz_chunks
#' @export
read_wordsintransition_chunks <- function() {
  read_all_graphviz_chunks("wordsintransition")
}

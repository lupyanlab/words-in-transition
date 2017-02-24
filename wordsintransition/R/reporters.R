
#' Count the unique values in a tidy data frame.
#' @import dplyr
#' @export
count_unique <- function(frame, id_col) {
  frame[[id_col]] %>% na.omit() %>% unique() %>% length()
}

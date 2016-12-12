#' Bin trials into named groups.
#'
#' @example
#' lsn %<>% bin_trials("block_transition", before = c(30:40), after = c(1:10))
bin_trials <- function(frame, bin_col, ...) {
  frame[bin_col] <- NA
  frame
}


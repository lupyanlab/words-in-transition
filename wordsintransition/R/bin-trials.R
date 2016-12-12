#' Bin trials into named groups.
#'
#' @example
#' lsn %<>% bin_trials("block_transition", before = c(30:40), after = c(1:10))
bin_trials <- function(frame, bin_col, ...) {
  trial_labels <- list(...)
  frame[bin_col] <- NA

  for (name in names(trial_labels)) {
    in_trial_label <- (frame$trial_ix %in% trial_labels[[name]])
    frame[in_trial_label, bin_col] <- name
  }

  frame
}

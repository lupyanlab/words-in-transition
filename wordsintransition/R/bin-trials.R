#' Bin trials into named groups.
#' @export
bin_trials <- function(frame, new_bin_col, col_to_bin_on = "trial_ix", ...) {
  frame[new_bin_col] <- NA
  trial_labels <- list(...)

  for (name in names(trial_labels)) {
    in_trial_label <- (frame[[col_to_bin_on]] %in% trial_labels[[name]])
    frame[in_trial_label, new_bin_col] <- name
  }

  frame
}


#' Label trial number within each block.
#' @import dplyr
#' @export
label_trial_in_block <- function(frame) {
  frame %>%
    group_by(subj_id, block_ix) %>%
    arrange(trial_ix) %>%
    mutate(trial_in_block = 1:n()) %>%
    ungroup()
}

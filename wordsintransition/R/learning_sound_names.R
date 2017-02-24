
#' Recode the transition between blocks
#' @import dplyr
#' @export
recode_block_transition <- function(frame) {
  block_transition_levels <- c("before", "after")
  block_transition_map <- data_frame(
    block_transition = block_transition_levels,
    block_transition_label = factor(block_transition_levels,
                                    levels = block_transition_levels),
    block_transition_c = c(-0.5, 0.5)
  )
  left_join(frame, block_transition_map)
}

#' Recode the word type of the word learned in the LSN experiment.
#' @import dplyr
#' @export
recode_lsn_word_type <- function(frame) {
  frame %>%
    rename(message_type = word_type) %>%
    recode_message_type()
}

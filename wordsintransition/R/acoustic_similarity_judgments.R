
#' z-score acoustic similarity judgments by participant
#' @import dplyr
#' @export
z_score_by_subj <- function(frame) {
  z_score <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
  frame %>%
    group_by(name) %>%
    mutate(similarity_z = z_score(similarity)) %>%
    ungroup()
}

#' Recode edge generations for acoustic similarity judgments.
#' @import dplyr
#' @export
recode_edge_generations <- function(frame) {
  data_frame(
    edge_generations = c("1-2", "2-3", "3-4", "4-5", "5-6", "6-7", "7-8"),
    edge_generation_n = seq_along(edge_generations)
  ) %>%
    left_join(frame, .)
}

#' Label the trial id based on sound_x and sound_y of acoustic similarity trial.
#' @import dplyr
#' @export
determine_trial_id <- function(frame) {
  # Warning! Ignores presentation order.
  mutate(frame, trial_id = paste(sound_x, ":", sound_y))
}

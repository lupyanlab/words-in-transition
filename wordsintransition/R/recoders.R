#' @import dplyr
#' @export
recode_question_type <- function(frame) {
  map <- data_frame(
    question_type = c("exact", "category"),
    question_c = c(-0.5, 0.5)
  )

  frame %>% left_join(map)
}


#' @import dplyr
#' @import magrittr
#' @export
recode_message_type <- function(frame) {
  frame %<>%
    mutate(
      message_type = ifelse(message_id == seed_id, "sound_effect", "imitation")
    )

  levels <- c("sound_effect", "imitation") %>% rev
  labels <- c("Sound effect transcription", "Imitation transcription") %>% rev

  map <- data_frame(
    message_type = levels,
    message_label = factor(message_type, levels = levels, labels = labels),
    message_c = c(-0.5, 0.5)
  )

  frame %>% left_join(map)
}


#' @import dplyr
#' @export
recode_version <- function(frame) {
  levels <- c("pilot", "A")
  labels <- c("Pilot (Qualtrics)", "Test (App)")

  map <- data_frame(
    version = levels,
    version_label = factor(levels, levels = levels, labels = labels)
  )

  frame %>% left_join(map)
}

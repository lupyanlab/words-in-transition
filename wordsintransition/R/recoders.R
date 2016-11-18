#' @import dplyr
#' @export
recode_question_type <- function(frame) {
  labels <- c("Category match\n(true seed)", "Category match")
  map <- data_frame(
    question_type = c("exact", "category"),
    question_c = c(-0.5, 0.5),
    question_label = factor(labels, levels = labels)
  )

  frame %>% left_join(map)
}


#' @import dplyr
#' @import magrittr
#' @export
recode_message_type <- function(frame) {
  try({
    frame %<>%
      mutate(
        message_type = ifelse(message_id == seed_id, "sound_effect",
                              ifelse(generation == 1, "first_gen_imitation", "last_gen_imitation"))
      )
  })

  levels <- c("sound_effect", "first_gen_imitation", "last_gen_imitation")
  labels <- c("Sound effect", "First gen imitation", "Last gen imitation")
  long_labels <- c("Transcription of sound effect",
                   "Transcription of first gen imitation",
                   "Transcription of last gen imitation")

  map <- data_frame(
    message_type = levels,
    message_label = factor(message_type, levels = levels, labels = labels),
    message_label_long = factor(message_type, levels = levels, labels = long_labels),
    message_c = c(NA, -0.5, 0.5)
  )

  frame %>% left_join(map)
}


#' @import dplyr
#' @export
recode_version <- function(frame) {
  levels <- c("pilot", "version_a", "version_b", "version_c")
  labels <- c("Pilot", "Version A", "Version B", "Version C")

  map <- data_frame(
    version = levels,
    version_label = factor(levels, levels = levels, labels = labels)
  )

  frame %>% left_join(map)
}


#' @import dplyr
#' @export
recode_transcription_frequency <- function(frame) {
  map <- data_frame(
    no_agreement = c(0, 1),
    frequency_type = c("Some agreement", "No agreement")
  )
  frame %>% left_join(map)
}

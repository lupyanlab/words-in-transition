library(ggplot2)
library(dplyr)
library(magrittr)

library(wordsintransition)
data("transcriptions")
data("imitations")

transcriptions %<>%
  filter(is_catch_trial == 0) %>%
  recode_message_type

transcribed_message_ids <- unique(transcriptions$message_id)

imitations %<>%
  filter(game_name == "words-in-transition")

transcribed_imitations_first_gen_ids <- imitations %>%
  filter(
    generation > 1,
    message_id %in% transcribed_message_ids
  ) %>%
  .$first_gen_id

untranscribed_first_gen_ids <- imitations %>%
  filter(
    generation == 1,
    !(message_id %in% transcribed_message_ids),
    message_id %in% transcribed_imitations_first_gen_ids
  ) %>%
  .$message_id

# Input for New Transcription form
paste(untranscribed_first_gen_ids, collapse = ",")

# Number of participants needed
n_transcriptions_per_subj <- 9  # 9 good transcriptions + 1 catch trial
n_transcriptions_per_imitation <- 20
n_imitations <- length(untranscribed_first_gen_ids)
(n_subjs <- ceiling((n_transcriptions_per_imitation * n_imitations)/n_transcriptions_per_subj))

reward_per_assignment <- 0.25
(base_cost <- n_subjs * reward_per_assignment)

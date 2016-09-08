library(ggplot2)
library(dplyr)
library(magrittr)

library(wordsintransition)
data("imitations")
data("transcriptions")

imitations %<>%
  filter(game_name == "words-in-transition")

transcriptions %<>%
  filter(is_catch_trial == 0)

transcribed_message_ids <- unique(transcriptions$message_id)

untranscribed_imitations <- imitations %>%
  filter(!(message_id %in% transcribed_message_ids))

untranscribed_seed_message_ids <- untranscribed_imitations %>%
  filter(generation == 0) %>%
  .$message_id

pick_terminal_messages <- function(branch, n = 1) {
  max_gen <- max(branch$generation)
  gens_to_keep <- seq(max_gen, max_gen - (n-1))

  branch %>%
    filter(generation %in% gens_to_keep)
}

untranscribed_terminal_message_ids <- untranscribed_imitations %>%
  filter(generation > 0) %>%
  group_by(seed_id) %>%
  do({ pick_terminal_messages(., n = 1) }) %>%
  .$message_id

untranscribed_message_ids <- c(untranscribed_seed_message_ids,
                               untranscribed_terminal_message_ids)

# Input for New Transcription form
paste(untranscribed_message_ids, collapse = ",")

# Number of participants needed
n_transcriptions_per_subj <- 9  # 9 good transcriptions + 1 catch trial
n_transcriptions_per_imitation <- 20
n_imitations <- length(untranscribed_message_ids)
(n_subjs <- ceiling((n_transcriptions_per_imitation * n_imitations)/n_transcriptions_per_subj))

reward_per_assignment <- 0.25
(base_cost <- n_subjs * reward_per_assignment)

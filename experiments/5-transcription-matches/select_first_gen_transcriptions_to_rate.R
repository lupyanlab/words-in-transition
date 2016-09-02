library(dplyr)
library(magrittr)

library(wordsintransition)
data("imitations")
data("transcription_frequencies")
data("transcription_matches")

gen_labels <- imitations %>%
  select(message_id, generation)

all_first_gen_transcriptions_to_match <- transcription_frequencies %>%
  left_join(gen_labels) %>%
  filter(
    is_english == 0,
    generation == 1
  )

words_already_matched <- unique(transcription_matches$word)
most_frequent_first_gen_unmatched_transcriptions <- all_first_gen_transcriptions_to_match %>%
  group_by(chain_name, seed_id, message_id) %>%
  arrange(desc(n)) %>%
  mutate(order = 1:n()) %>%
  ungroup %>%
  filter(
    order < 5,
    !(text %in% words_already_matched)
  )

write.csv(most_frequent_first_gen_unmatched_transcriptions,
          "experiments/5-transcription-matches/surveys/version-c/selected_transcriptions.csv",
          row.names = FALSE)

match_transcriptions_version_c <- most_frequent_first_gen_unmatched_transcriptions %>%
  select(text)

# Calculate cost of experiment
num_words <- nrow(match_transcriptions_version_c)
survey_types <- 4
num_questions <- num_words * survey_types
num_responses_per_question <- 8
total_num_responses <- num_questions * num_responses_per_question
responses_per_subj <- 30
(n_subjs <- (total_num_responses/responses_per_subj) %>% ceiling)
reward_per_subj <- 0.75
(base_cost <- n_subjs * reward_per_subj)
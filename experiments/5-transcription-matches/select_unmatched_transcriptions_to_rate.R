library(dplyr)
library(magrittr)

library(wordsintransition)
data("transcription_frequencies")
data("transcription_matches")

all_transcriptions_to_match <- transcription_frequencies %>%
  filter(is_english == 0)

write.csv(all_transcriptions_to_match,
          "experiments/5-transcription-matches/all_transcriptions_to_match.csv",
          row.names = FALSE)

words_already_matched <- unique(transcription_matches$word)
most_frequent_unmatched_transcriptions <- all_transcriptions_to_match %>%
  group_by(chain_name, seed_id, message_id) %>%
  arrange(desc(n)) %>%
  mutate(order = 1:n()) %>%
  ungroup() %>%
  filter(
    order < 5,
    !(text %in% words_already_matched)
  )

match_transcriptions_version_b <- most_frequent_unmatched_transcriptions %>%
  select(text)

# Calculate cost of experiment
num_words <- nrow(match_transcriptions_version_b)
survey_types <- 4
num_questions <- num_words * survey_types
num_responses_per_question <- 8
total_num_responses <- num_questions * num_responses_per_question
responses_per_subj <- 30
(n_subjs <- (total_num_responses/responses_per_subj) %>% ceiling)
reward_per_subj <- 0.75
(base_cost <- n_subjs * reward_per_subj)
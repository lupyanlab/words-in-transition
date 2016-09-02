library(dplyr)

library(wordsintransition)
data("transcription_frequencies")

selected <- transcription_frequencies %>%
  filter(
    is_english == 0,
    transcription_survey_name == "hand picked 1"
  ) %>%
  group_by(chain_name, seed_id, message_id) %>%
  arrange(desc(n)) %>%
  mutate(order = 1:n()) %>%
  ungroup() %>%
  filter(order < 5)

write.csv(selected,
          "experiments/5-transcription-matches/surveys/qualtrics/transcriptions/selected_transcriptions.csv",
          row.names = FALSE)

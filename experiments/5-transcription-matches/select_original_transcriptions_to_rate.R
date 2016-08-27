library(dplyr)

library(wordsintransition)
data("transcription_frequencies")

selected <- transcription_frequencies %>%
  filter(is_english == 0) %>%
  group_by(chain_name, seed_id, message_id) %>%
  arrange(desc(n)) %>%
  mutate(order = 1:n()) %>%
  ungroup() %>%
  filter(order < 5)

write.csv(selected, "experiments/5-transcription-matches/selected.csv", row.names = FALSE)

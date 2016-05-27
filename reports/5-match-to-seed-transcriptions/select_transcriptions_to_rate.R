library(dplyr)

library(wordsintransition)
data("transcriptions")

survey_names <- c("hand picked 1", "hand picked 1 seeds")
frequencies <- transcriptions %>%
  filter(!grepl("\\.wav$", chain_name),  # catch trials have files as chain names
         transcription_survey_name %in% survey_names) %>%
  count(transcription_survey_name, chain_name, seed_id, message_id, text) %>%
  arrange(desc(n)) %>%
  mutate(order = 1:n())

# Select the 4 most frequent transcriptions
selected <- frequencies %>%
  group_by(transcription_survey_name, message_id) %>%
  filter(order < 5)

write.csv(selected, "reports/5-match-to-seed-transcriptions/selected.csv", row.names = FALSE)
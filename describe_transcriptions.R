library(dplyr, quietly = TRUE)

transcriptions <- read.csv("match-transcriptions/transcriptions.csv",
                           stringsAsFactors = FALSE)

survey_names <- c("hand picked 1", "hand picked 1 seeds")
frequencies <- transcriptions %>%
    filter(!grepl("\\.wav$", chain_name),  # catch trials have files as chain names
           transcription_survey_name %in% survey_names) %>%
    count(transcription_survey_name, chain_name, seed_id, message_id, text) %>%
    arrange(desc(n)) %>%
    mutate(order = 1:n())

write.csv(frequencies, "match-transcriptions/frequencies.csv",
          row.names = FALSE)

# Select the 4 most frequent transcriptions
select_transcriptions_to_match <- function(frame, survey_name) {
  selected <- frame %>% filter(order < 5)
  dst <- file.path("match-transcriptions/surveys", survey_name, "transcriptions/selected.csv")
  write.csv(selected, dst, row.names = FALSE)
}

match_to_seed_transcriptions <- frequencies %>%
  filter(transcription_survey_name == "hand picked 1") %>%
  select_transcriptions_to_match("match_to_seed")

# Commented out until "hand picked 1 seeds" transcription survey data is in
match_to_source_transcriptions <- frequencies %>%
  filter(transcription_survey_name == "hand picked 1 seeds") %>%
  select_transcriptions_to_match("match_to_source")

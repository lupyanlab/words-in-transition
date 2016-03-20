library(dplyr)

transcriptions <- read.csv("match-transcriptions/transcriptions.csv",
                           stringsAsFactors = FALSE)

frequencies <- transcriptions %>%
    filter(chain_name != "alligator_1.wav",  # catch trial
           transcription_survey_name == "hand picked 1") %>%
    count(chain_name, seed_id, message_id, text) %>%
    arrange(desc(n)) %>%
    mutate(order = 1:n())

write.csv(frequencies, "match-transcriptions/frequencies.csv",
          row.names = FALSE)

# Select the 4 most frequent transcriptions
selected <- frequencies %>%
    filter(order < 5)

write.csv(selected, "match-transcriptions/selected.csv",
          row.names = FALSE)

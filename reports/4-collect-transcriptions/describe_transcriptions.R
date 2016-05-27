library(dplyr, quietly = TRUE)

library(wordsintransition)
data("transcriptions")

report_dir <- file.path("reports/4-collect-transcriptions")

survey_names <- c("hand picked 1", "hand picked 1 seeds")
frequencies <- transcriptions %>%
    filter(!grepl("\\.wav$", chain_name),  # catch trials have files as chain names
           transcription_survey_name %in% survey_names) %>%
    count(transcription_survey_name, chain_name, seed_id, message_id, text) %>%
    arrange(desc(n)) %>%
    mutate(order = 1:n())

write.csv(frequencies, file.path(report_dir, "frequencies.csv"),
          row.names = FALSE)

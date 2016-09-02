library(dplyr)

library(wordsintransition)
data("transcription_frequencies")

all_transcriptions_to_match <- transcription_frequencies %>%
  filter(is_english == 0)

write.csv(all_transcriptions_to_match,
          "experiments/5-transcription-matches/all_transcriptions_to_match.csv",
          row.names = FALSE)

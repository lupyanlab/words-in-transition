library(dplyr)
library(stringr)
library(ggplot2)

guesses <- read.csv("match-transcriptions/match_transcriptions.csv",
                    stringsAsFactors = FALSE)

extract_category <- function(x) str_split_fixed(x, "-", n = 2)[, 1]

guesses$answer_category <- extract_category(guesses$filename)
guesses$choice_category <- extract_category(guesses$choice_filename)
guesses$is_correct <- as.numeric(guesses$answer_category == guesses$choice_category)


accuracy <- guesses %>%
  group_by(chain_name, answer_category, text) %>%
  summarize(
    accuracy = mean(is_correct),
    n = n()
  )

ggplot(accuracy, aes(x = chain_name, y = accuracy)) +
  geom_point(shape = 1) +
  geom_text(aes(label = text), hjust = -0.1, angle = 45)

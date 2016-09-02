library(dplyr)
library(magrittr)
library(stringr)
library(ggplot2)

library(wordsintransition)
data("transcription_matches")

chance <- 0.25

transcription_matches %<>%
  mutate(chance = chance) %>%
  filter(word_category != "catch_trial")

accuracy <- transcription_matches %>%
  group_by(word_category, question_type, word) %>%
  summarize(
    accuracy = mean(is_correct),
    n = n()
  )

ggplot(accuracy, aes(x = word_category, y = accuracy)) +
  geom_point(shape = 1) +
  geom_text(aes(label = word), hjust = -0.1, angle = 45) +
  facet_wrap("question_type")

summary(glm(is_correct ~ 1, offset = chance, data = transcription_matches))
summary(glm(is_correct ~ 1, offset = chance, data = filter(transcription_matches, question_type == "exact")))
summary(glm(is_correct ~ 1, offset = chance, data = filter(transcription_matches, question_type == "category")))

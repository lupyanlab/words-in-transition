library(dplyr)
library(stringr)
library(ggplot2)

library(wordsintransition)
data(matches)

matches$chance <- 0.25

accuracy <- matches %>%
  group_by(text_category, question_type, text) %>%
  summarize(
    accuracy = mean(is_correct),
    n = n()
  )

ggplot(accuracy, aes(x = text_category, y = accuracy)) +
  geom_point(shape = 1) +
  geom_text(aes(label = text), hjust = -0.1, angle = 45) +
  facet_wrap("question_type")

ggplot(guesses, aes(x = 1, y = is_correct)) +
  geom_bar(stat = "summary", fun.y = "mean") +
  facet_wrap("question_type")

summary(glm(is_correct ~ 1, offset = chance, data = matches))
summary(glm(is_correct ~ 1, offset = chance, data = filter(matches, question_type == "exact")))
summary(glm(is_correct ~ 1, offset = chance, data = filter(matches, question_type == "category")))

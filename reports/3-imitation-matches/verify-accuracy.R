library(wordsintransition)
data("imitation_matches")

library(tidyverse)
library(magrittr)

# Drop catch trials
imitation_matches %<>%
  filter(question_type != "catch_trial")

question_accuracies <- imitation_matches %>%
  group_by(question_pk) %>%
  summarize(accuracy = mean(is_correct)) %>%
  left_join(
    imitation_matches %>% select(question_pk, survey_type) %>% unique()
  ) %>%
  arrange(accuracy) %>%
  mutate(question_ord = factor(question_pk, levels = question_pk))

ggplot(question_accuracies) +
  aes(question_ord, accuracy, fill = survey_type) +
  geom_bar(stat = "identity")

ggplot(question_accuracies %>% filter(accuracy < 0.3)) +
  aes(question_ord, accuracy, fill = survey_type) +
  geom_bar(stat = "identity")

bad_questions <- question_accuracies %>%
  filter(accuracy == 0)

ggplot(bad_questions) +
  aes(survey_type) +
  geom_bar()

data("imitation_matches")
bad_question_ids <- imitation_matches %>%
  filter(question_type != "catch_trial") %>%
  group_by(question_pk) %>%
  summarize(accuracy = mean(is_correct)) %>%
  filter(accuracy == 0) %>%
  .$question_pk

setequal(bad_questions$question_pk, bad_question_ids)
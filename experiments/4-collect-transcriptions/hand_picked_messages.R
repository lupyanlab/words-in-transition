# As a first pass, 2 imitations from each category were hand selected.
# This script labels the imitations that were selected, and displays
# the match to seed guessing accuracy for these messages.

library(dplyr)
library(ggplot2)
library(tidyr)
library(broom)

library(wordsintransition)
data("imitation_matches")

# Summarize branch performance
branches <- imitation_matches %>%
  filter(question_type != "catch_trial") %>%
  group_by(chain_name, seed_id, first_gen_id, survey_type, generation) %>%
  summarize(accuracy = mean(is_correct)) %>%
  ungroup()

hand_picked <- c(566, 502, 560, 522, 466, 563, 377, 505)

selected_branch_ids <- imitation_matches %>%
  filter(message_id %in% hand_picked) %>%
  .$first_gen_id %>%
  unique

selected_branches <- filter(branches, first_gen_id %in% selected_branch_ids)

ggplot(selected_branches, aes(x = generation, y = accuracy)) +
  geom_line(aes(group = survey_type, color = survey_type), stat = "summary", fun.y = "mean") +
  facet_wrap("chain_name")
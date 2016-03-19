library(dplyr)
library(ggplot2)
library(tidyr)
library(broom)

library(wordsintransition)
data(responses)

# Summarize branch performance
branches <- responses %>%
  filter(question_type != "catch_trial") %>%
  group_by(chain_name, seed_id, first_gen_id, survey_type, generation) %>%
  summarize(accuracy = mean(is_correct)) %>%
  ungroup()

# Select the highest performing branch for each chain
pick_best_branch <- function(chain) {
  long_enough_branches <- chain %>%
    group_by(first_gen_id) %>%
    filter(max(generation) > 3) %>%
    .$first_gen_id
  
  slopes <- chain %>%
    filter(survey_type != "within", first_gen_id %in% long_enough_branches) %>%
    group_by(first_gen_id, survey_type) %>%
    do(mod = lm(accuracy ~ generation, data = .)) %>%
    tidy(mod) %>%
    filter(term == "generation")
  
  category_diffs <- slopes %>%
    select(first_gen_id, survey_type, estimate) %>%
    spread(survey_type, estimate) %>%
    mutate(diff = between - same) %>%
    arrange(diff)
  
  selected_branch_id <- category_diffs$first_gen_id[[1]]
  
  chain %>% filter(first_gen_id == selected_branch_id)
}

selected_branches <- branches %>%
  group_by(chain_name) %>%
  do({ pick_best_branch(.) })

ggplot(selected_branches, aes(x = generation, y = accuracy)) +
  geom_line(aes(group = survey_type, color = survey_type)) +
  facet_wrap("chain_name")

unique(selected_branches[,c("seed_id", "first_gen_id")])
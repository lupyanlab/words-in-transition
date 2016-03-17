library(dplyr)
library(ggplot2)
library(lme4)

library(wordsintransition)
devtools::load_all("wordsintransition")
data(responses)

survey_type_map <- data_frame(
  survey_type = c("between", "same", "within"),
  # Treatment contrasts
  between_v_same = c(0, 1, 0),
  between_v_within = c(0, 0, 1)
)

responses <- left_join(responses, survey_type_map)

# Create a list of subjects who passed the catch trials
passed_catch_trials <- responses %>%
  filter(!is.na(subj_id), question_type == "catch_trial") %>%
  group_by(subj_id) %>%
  summarize(catch_trial_accuracy = mean(is_correct)) %>%
  filter(catch_trial_accuracy == 1.0) %>%
  .$subj_id

match_to_seed <- filter(responses,
                        rejected == "False",
                        question_type != "catch_trial")

# Between
between <- filter(match_to_seed, survey_type == "between")

ggplot(between, aes(x = generation, y = is_correct)) +
  geom_line(aes(color = chain_name), stat = "summary", fun.y = "mean")

ggplot(between, aes(x = generation, y = is_correct)) +
  geom_line(aes(group = seed_id, color = chain_name), stat = "summary", fun.y = "mean")

ggplot(between, aes(x = generation, y = is_correct)) +
  geom_line(aes(group = message_id, color = chain_name), stat = "summary", fun.y = "mean")



match_to_seed_mod <- glmer(is_correct ~ generation * (between_v_same + between_v_within) + (generation|chain_name),
                           offset = chance, family = "binomial", data = match_to_seed)
summary(match_to_seed_mod)

ggplot(match_to_seed, aes(x = generation, y = is_correct)) +
  geom_point(aes(color = survey_type), stat = "summary", fun.y = "mean",
             shape = 1, size = 2)

ggplot(match_to_seed, aes(x = generation, y = is_correct)) +
  geom_point(aes(group = chain_name, color = survey_type), stat = "summary", fun.y = "mean",
             shape = 1, size = 2)
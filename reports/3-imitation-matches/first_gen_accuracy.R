library(dplyr)
library(ggplot2)
library(lme4)

library(wordsintransition)
data(responses)

responses$is_correct <- as.numeric(responses$selection == responses$answer)

# Create a list of subjects who passed the catch trials
passed_catch_trials <- responses %>%
  filter(!is.na(subj_id), question_type == "catch_trial") %>%
  group_by(subj_id) %>%
  summarize(catch_trial_accuracy = mean(is_correct)) %>%
  filter(catch_trial_accuracy == 1.0) %>%
  .$subj_id

first_gen <- filter(responses,
                    generation == 1,
                    rejected == "False",
                    subj_id %in% passed_catch_trials)

ggplot(first_gen, aes(x = survey_type, y = is_correct)) +
  geom_bar(stat = "summary", fun.y = "mean")

ggplot(first_gen, aes(x = survey_type, y = is_correct)) +
  geom_line(aes(group = chain_name, color = chain_name), stat = "summary", fun.y = "mean")

ggplot(first_gen, aes(x = survey_type, y = is_correct)) +
  geom_line(aes(group = seed_id, color = chain_name), stat = "summary", fun.y = "mean")

ggplot(first_gen, aes(x = survey_type, y = is_correct)) +
  geom_line(aes(group = message_id, color = chain_name), stat = "summary", fun.y = "mean")

# How many guesses per imitation?
guesses_per_message <- first_gen %>%
  count(survey_type, chain_name, message_id)

ggplot(guesses_per_message, aes(x = survey_type, y = n)) +
  geom_point(shape = 1, position = position_jitter(width = 0.2, height = 0.0))

# Which messages were significantly above chance?
first_gen$chance <- 0.25
between_mod <- glmer(is_correct ~ 1 + (1|message_id),
                     offset = chance,
                     family = "binomial",
                     data = filter(first_gen, survey_type == "between"))

glm_results <- first_gen %>%
  filter(survey_type == "between") %>%
  group_by(message_id) %>%
  do(mod = glm(is_correct ~ 1, offset = chance, family = "binomial", data = .)) %>%
  tidy(mod) %>%
  select(message_id, glm_estimate = estimate, glm_p = p.value)

glmer_results <- tidy(between_mod) %>%
  mutate(level = as.numeric(level)) %>%
  select(message_id = level, glmer_estimate = estimate)

between_coefs <- left_join(glm_results, glmer_results) 

ggplot(between_coefs, aes(x = glmer_estimate)) +
  geom_histogram()

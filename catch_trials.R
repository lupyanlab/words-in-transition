library(dplyr)
library(ggplot2)

library(wordsintransition)
data(responses)

responses$is_correct <- as.numeric(responses$selection == responses$answer)

catch_trials <- filter(responses, !is.na(subj_id), question_type == "catch_trial")

# Accuracy on catch trials
ggplot(catch_trials, aes(x = survey_type, y = is_correct)) +
  geom_point(aes(group = message_id, color = chain_name), stat = "summary", fun.y = "mean",
             shape = 1, size = 4) +
  geom_point(stat = "summary", fun.y = "mean", size = 6) +
  geom_line(aes(group = message_id, color = chain_name), stat = "summary", fun.y = "mean")

# How many catch trials per subject?
num_catch_trials <- catch_trials %>%
  group_by(subj_id) %>%
  summarize(num_catch_trials = n())

ggplot(num_catch_trials, aes(x = num_catch_trials)) +
  geom_histogram(binwidth = 1) +
  ggtitle("Catch trials per subject")
# - all subjects had at least one catch trial
# - subjects with more than 4 catch trials participated in multiple surveys

# Confirm that catch trials are labeled correctly
sum(catch_trials$answer != catch_trials$message_id)  # should be 0

# Confirm that answer is present in choices
catch_trials %>%
  group_by(message_id, choices) %>%
  summarize(answer_not_in_choices = !grepl(message_id[1], choices[1])) %>%
  .$answer_not_in_choices %>% sum  # should be 0

# Subjects that answered all catch questions correctly
subjs <- catch_trials %>%
  group_by(subj_id) %>%
  summarize(
    num_catch_trials = n(),
    catch_trial_accuracy = mean(is_correct),
    passed_catch_trials = catch_trial_accuracy == 1.0
  )

ggplot(subjs, aes(x = passed_catch_trials)) +
  geom_histogram()

ggplot(subjs, aes(x = num_catch_trials, y = catch_trial_accuracy)) +
  geom_point(shape = 1, position = position_jitter(width = 0.1, height = 0.01)) +
  scale_x_continuous("Number of catch trials", breaks = c(0, 1, seq(5, 15, by = 5)))
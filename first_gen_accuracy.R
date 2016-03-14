library(dplyr)
library(ggplot2)

devtools::load_all("wordsintransition")
data(responses)

label_correct <- function(frame) {
  mutate(frame, is_correct = as.numeric(selection == answer))
}

label_bad_subjs <- function(frame) {
  subjs <- frame %>%
    filter(question_type == "catch_trial") %>%
    group_by(subj_id) %>%
    summarize(
      num_catch_trials = n(),
      catch_accuracy = mean(is_correct)
    ) %>%
    mutate(
      is_bad_subj = catch_accuracy < 1.0
    )
  
  left_join(frame, subjs)
}

responses <- responses %>%
  label_correct %>%
  label_bad_subjs

match_to_seed <- filter(responses, question_type != "catch_trial")

ggplot(match_to_seed, aes(x = survey_type, y = is_correct)) +
  geom_point(aes(group = given, color = chain_name), stat = "summary", fun.y = "mean",
             shape = 1, size = 4) +
  geom_point(stat = "summary", fun.y = "mean", size = 6) +
  geom_line(aes(group = given, color = chain_name), stat = "summary", fun.y = "mean")

library(dplyr)
library(ggplot2)

library(wordsintransition)
data(responses)

responses$is_correct <- as.numeric(responses$selection == responses$answer)

match_to_seed <- filter(responses, question_type != "catch_trial")

ggplot(match_to_seed, aes(x = survey_type, y = is_correct)) +
  geom_point(aes(group = message_id, color = chain_name), stat = "summary", fun.y = "mean",
             shape = 1, size = 4) +
  geom_point(stat = "summary", fun.y = "mean", size = 6) +
  geom_line(aes(group = message_id, color = chain_name), stat = "summary", fun.y = "mean")

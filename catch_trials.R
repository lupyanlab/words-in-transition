library(dplyr)
library(ggplot2)

library(wordsintransition)
data(responses)

label_correct <- function(frame) {
  mutate(frame, is_correct = selection == answer)
}

responses <- label_correct(responses)

responses %>%
  group_by(survey_name, question_type) %>%
  summarize(
    n = n(),
    accuracy = mean(is_correct)
  )


responses %>% filter(question_type == "catch_trial", survey_name == "within-category-glass")


responses %>% group_by(survey_name, question_type) %>% summarize(num_questions = length(unique(question_id)))
# Why do between-3 and between-4 only have 3 catch trials?

between3_catch <- responses %>% 
  filter(survey_name == "between-3", question_type == "catch_trial")
between3_catch$given %>% unique()

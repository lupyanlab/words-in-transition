library(dplyr)
library(ggplot2)
options(stringsAsFactors = FALSE)

library(wordsintransition)
data(responses)
data(questions)
data(messages)

questions_with_no_responses <- setdiff(questions$question_id, responses$question_id)
missing_questions <- filter(questions, question_id %in% questions_with_no_responses) %>%
  arrange(survey_name)
write.csv(missing_questions, "missing_questions.csv", row.names = FALSE)


missing_messages <- missing_questions$given
missing_question_messages <- filter(messages, message_id %in% missing_messages)
write.csv(missing_question_messages, "missing_question_messages.csv", row.names = FALSE)




responses <- merge(responses, questions, all = TRUE)
questions_with_no_responses <- is.na(responses$selection)
responses

question_counts <- count(responses, survey_name, question_id)
question_counts %>% ungroup %>% arrange(n)

ggplot(question_counts, aes(x = n)) +
  geom_density(aes(color = survey_name))

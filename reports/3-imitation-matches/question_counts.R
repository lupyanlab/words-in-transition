library(dplyr)
library(ggplot2)

library(wordsintransition)
data(responses)
data(questions)
data(messages)

questions_with_no_responses <- setdiff(questions$question_id, responses$question_id)
missing_questions <- filter(questions, question_id %in% questions_with_no_responses) %>%
  arrange(survey_name)

pylist_to_r <- function(x) {
  x %>%
    gsub("\\[", "c(", x = .) %>%
    gsub("\\]", ")", x = .) %>%
    parse(text = .) %>%
    eval
}

missing_questions %>% group_by(survey_name) %>%
  do({
    data.frame(
      survey_name = paste0(.$survey_name[1], "-missing"),
      choices = paste(pylist_to_r(.$choices), collapse = ","),
      questions = paste(.$message_id, collapse = ",")
    )
  })

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

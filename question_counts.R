library(dplyr)
library(ggplot2)
options(stringsAsFactors = FALSE)

responses <- read.csv("data/responses.csv")

question_counts <- count(responses, question_id)
question_counts %>% arrange(n)

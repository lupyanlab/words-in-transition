library(dplyr)
library(ggplot2)
options(stringsAsFactors = FALSE)

devtools::load_all("wordsintransition")

responses <- read.csv("data/responses.csv")

question_counts <- count(responses, question_id)
question_counts %>% arrange(n)

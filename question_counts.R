library(dplyr)
library(ggplot2)
options(stringsAsFactors = FALSE)

devtools::load_all("wordsintransition")

question_counts <- count(responses, question_id)
question_counts %>% arrange(n)

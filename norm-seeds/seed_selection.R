library(dplyr)
library(ggplot2)
options(stringsAsFactors = FALSE)

odd_one_out <- read.csv("survey-1/odd_one_out.csv")

odd_one_out <- filter(odd_one_out,
                      failed_catch_trial == FALSE,
                      problem_with_audio == FALSE)

ggplot(odd_one_out, aes(x = filename)) +
  geom_histogram() +
  facet_wrap("category")
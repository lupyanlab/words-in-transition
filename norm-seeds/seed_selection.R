library(dplyr)
library(ggplot2)
options(stringsAsFactors = FALSE)

odd_one_out <- read.csv("survey-1/odd_one_out.csv")

odd_one_out <- filter(odd_one_out,
                      failed_catch_trial == 0,
                      problem_with_audio == 0)

ggplot(odd_one_out, aes(x = filename)) +
  geom_histogram() +
  facet_wrap("category", scales = "free_x", ncol = 2) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
  ggtitle("Odd one out")

ggsave("odd_one_out.png", height = 10)

library(dplyr)
library(ggplot2)
library(magrittr)

library(wordsintransition)
data("sound_similarity_6")

count_valid_responses <- function(frame) {
  frame <- filter(frame,
                  failed_catch_trial == 0,
                  problem_with_audio == 0)

  counts <- frame %>%
    count(category, filename) %>%
    arrange(desc(n))
}

odd_sounds <- sound_similarity_6 %>%
  count_valid_responses %>%
  group_by(category) %>%
  mutate(odd_one_out = ifelse(n >= n[2], "odd", "normal")) %>%
  filter(odd_one_out == "odd") %>%
  select(category, filename)

write.csv(odd_sounds, "reports/1-determine-seeds/odd_sounds.csv", row.names = FALSE)

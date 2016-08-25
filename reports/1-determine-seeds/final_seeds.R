library(dplyr)
library(ggplot2)
library(magrittr)
options(stringsAsFactors = FALSE)

library(wordsintransition)
data("sound_similarity_4")

sound_similarity_4 %<>%
  count_valid_responses

selected_seeds <- read.csv("reports/1-determine-seeds/selected_seeds.csv") %>%
  select(category, filename)

final_seeds <- left_join(selected_seeds, sound_similarity_4) %>%
  filter(category %in% c("glass", "tear", "zipper", "water")) %>%
  mutate(n = ifelse(is.na(n), 0, n)) %>%
  group_by(category) %>%
  arrange(desc(n))

write.csv(final_seeds, "reports/1-determine-seeds/final_seeds.csv", row.names = FALSE)
write.csv(final_seeds, "wordsintransition/data-raw/final_seeds.csv", row.names = FALSE)

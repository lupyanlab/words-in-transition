library(dplyr)

library(wordsintransition)
data("frequencies")

selected <- frequencies %>%
  filter(is_english == 0) %>%
  group_by(chain_name, seed_id, message_id) %>%
  arrange(desc(n)) %>%
  mutate(order = 1:n()) %>%
  ungroup() %>%
  filter(order < 5)

write.csv(selected, "reports/5-match-to-seed-transcriptions/selected.csv", row.names = FALSE)

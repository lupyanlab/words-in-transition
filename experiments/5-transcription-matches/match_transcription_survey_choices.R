library(dplyr)
library(magrittr)
library(tidyr)

library(wordsintransition)
data("imitations")

seeds <- imitations %>%
  filter(game_name == "words-in-transition") %>%
  select(chain_name, seed_id) %>%
  unique

match_transcription_choices <- list(
    seeds_1 = c(34, 39, 42, 47),
    seeds_2 = c(35, 41, 45, 49),
    seeds_3 = c(36, 40, 44, 48),
    seeds_4 = c(37, 38, 43, 46)
  ) %>%
  as_data_frame %>%
  gather(choice_label, seed_id)

seeds_labeled <- left_join(seeds, match_transcription_choices)

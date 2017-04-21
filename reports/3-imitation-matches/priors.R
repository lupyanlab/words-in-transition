# Why did performance go below chance on some questions?
# Where some sounds more likely to be picked than chance,
# regardless of the question?
# Compare likelihood of getting picked as the odd one out in the norming
# study with the likelihood of getting picked in the Guess the seed game
# matching accuracy.

library(tidyverse)
library(magrittr)
library(wordsintransition)

data("sound_similarity_6")
data("sound_similarity_4")

odd_one_out_counts <- bind_rows(sound_similarity_6, sound_similarity_4) %>%
  count_valid_responses()

selected_seeds <- read_csv("reports/1-determine-seeds/selected_seeds.csv") %>%
  filter(category %in% c("glass", "tear", "zipper", "water")) %>%
  select(category, filename)

final_seeds <- left_join(selected_seeds, odd_one_out_counts) %>%
  mutate(n = ifelse(is.na(n), 0, n)) %>%
  arrange(category, desc(n))

seed_filenames <- data_frame(
  `34` = "glass_01.mp3",
  `35` = "glass_02.mp3",
  `36` = "glass_05.mp3",
  `37` = "glass_06.mp3",
  `38` = "tear_01.mp3",
  `39` = "tear_02.mp3",
  `40` = "tear_03.mp3",
  `41` = "tear_04.mp3",
  `42` = "water_03.mp3",
  `43` = "water_04.mp3",
  `44` = "water_05.mp3",
  `45` = "water_06.mp3",
  `46` = "zipper_01.mp3",
  `47` = "zipper_03.mp3",
  `48` = "zipper_04.mp3",
  `49` = "zipper_05.mp3"
) %>%
  gather(seed_id, filename) %>%
  mutate(seed_id = as.numeric(seed_id))

odd_one_out <- left_join(seed_filenames, final_seeds) %>%
  select(category, seed_id, n_odd = n)

data("imitation_matches")
guesses <- imitation_matches %>%
  filter(survey_type == "within") %>%
  count(answer) %>%
  select(seed_id = answer, n_match = n)

ggplot(left_join(odd_one_out, guesses)) +
  aes(n_odd, n_match, color = category) +
  geom_point()

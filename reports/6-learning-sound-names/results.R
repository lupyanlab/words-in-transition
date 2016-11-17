# ---- 6-setup
library(dplyr)
library(magrittr)
library(ggplot2)

library(wordsintransition)
data("learning_sound_names")

learning_sound_names %<>%
  mutate(rt = ifelse(is_correct == 1, rt, NA))

# ---- 6-rts-over-trials
ggplot(learning_sound_names, aes(trial_ix, rt)) +
  geom_point(aes(color = factor(block_ix))) +
  geom_smooth(aes(group = factor(block_ix), color = factor(block_ix)),
              method = "lm", se = FALSE) +
  theme(legend.position = "none") +
  facet_wrap("word_type")

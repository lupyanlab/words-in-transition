library(ggplot2)
global_theme <- theme_minimal() +
  theme(axis.ticks = element_blank())

# ---- 6-setup
library(dplyr)
library(magrittr)
library(ggplot2)

library(wordsintransition)

recode_word_type <- . %>%
  rename(message_type = word_type) %>%
  recode_message_type

data("learning_sound_names")
learning_sound_names %<>%
  mutate(rt = ifelse(is_correct == 1, rt, NA)) %>%
  mutate(word_category_by_block_ix = paste(word_category, block_ix, sep = ":")) %>%
  recode_word_type

scale_x_trial_ix <- scale_x_continuous("Trial number (24 trials per block)",
                                       breaks = seq(1, 96, by = 24))

ggbase <- ggplot(learning_sound_names, aes(trial_ix, rt)) +
  scale_x_trial_ix +
  global_theme

# ---- 6-rts-over-trials
ggbase +
  geom_point(aes(color = factor(block_ix))) +
  geom_smooth(aes(group = factor(block_ix), color = factor(block_ix)),
              method = "lm", se = FALSE) +
  scale_color_brewer("Block", palette = "Set2") +
  theme(legend.position = "none") +
  facet_wrap("message_label_long") +
  labs(title = "RTs over blocks by transcription type")

ggbase +
  geom_point(aes(color = word_category)) +
  geom_smooth(aes(group = word_category_by_block_ix, color = word_category),
              method = "lm", se = FALSE) +
  scale_color_brewer("Category", palette = "Set2") +
  theme(legend.position = "top") +
  facet_wrap("message_label_long") +
  labs(title = "RTs over blocks for each sound category")

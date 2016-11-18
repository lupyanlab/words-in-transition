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
  mutate(rt = ifelse(is_correct == 1, rt, NA),
         is_error = 1 - is_correct) %>%
  mutate(word_category_by_block_ix = paste(word_category, block_ix, sep = ":")) %>%
  recode_word_type

scale_x_trial_ix <- scale_x_continuous("Trial number (24 trials per block)",
                                       breaks = seq(1, 96, by = 24))
scale_y_rt <- scale_y_continuous("Reaction time (msec)")

ggbase <- ggplot(learning_sound_names) +
  global_theme

# ---- 6-errors
ggbase_error <- ggbase
ggbase_error$mapping <- aes(block_ix, is_error)

ggbase_error +
  geom_bar(aes(fill = factor(block_ix)), stat = "summary", fun.y = "sum") +
  scale_x_continuous("Block number (24 trials per block)", breaks = 1:4) +
  scale_y_continuous("Total number of errors") +
  scale_fill_brewer(palette = "Set2") +
  theme(legend.position = "none")

# ---- 6-rts-over-trials
ggbase_rt <- ggbase +
  scale_x_trial_ix +
  scale_y_rt
ggbase_rt$mapping <- aes(trial_ix, rt)

ggbase_rt +
  geom_point(aes(color = factor(block_ix))) +
  geom_smooth(aes(group = factor(block_ix), color = factor(block_ix)),
              method = "lm", se = FALSE) +
  scale_color_brewer("Block", palette = "Set2") +
  theme(legend.position = "none") +
  facet_wrap("message_label_long") +
  labs(title = "RTs over blocks by transcription type")

ggbase_rt +
  geom_point(aes(color = word_category)) +
  geom_smooth(aes(group = word_category_by_block_ix, color = word_category),
              method = "lm", se = FALSE) +
  scale_color_brewer("category:", palette = "Set2") +
  theme(legend.position = "top") +
  facet_wrap("message_label_long") +
  labs(title = "RTs over blocks for each sound category")

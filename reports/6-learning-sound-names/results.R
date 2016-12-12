library(ggplot2)
global_theme <- theme_minimal() +
  theme(axis.ticks = element_blank())
colors <- RColorBrewer::brewer.pal(3, "Set2")
names(colors) <- c("green", "orange", "blue")

# ---- 6-setup
library(dplyr)
library(magrittr)
library(ggplot2)
library(scales)
library(gridExtra)

library(wordsintransition)

recode_word_type <- . %>%
  rename(message_type = word_type) %>%
  recode_message_type()

data("learning_sound_names")
learning_sound_names %<>%
  mutate(rt = ifelse(is_correct == 1, rt, NA),
         is_error = 1 - is_correct) %>%
  mutate(word_category_by_block_ix = paste(word_category, block_ix, sep = ":")) %>%
  recode_word_type()

scale_x_trial_ix <- scale_x_continuous("Trial number (24 trials per block)",
                                       breaks = seq(1, 96, by = 24))
scale_x_block_ix <- scale_x_continuous("Block number (24 trials per block)",
                                       breaks = 1:4)
scale_y_rt <- scale_y_continuous("Reaction time (msec)")
scale_color_message_label <- scale_color_manual(
  "Transcription of",
  labels = c("Sound effect", "First generation", "Last generation"),
  values = unname(colors[c("orange", "green", "blue")])
)
scale_color_message_label_2 <- scale_color_manual(
  "Transcription of",
  labels = c("First generation", "Last generation"),
  values = unname(colors[c("green", "blue")])
)

ggbase <- ggplot(learning_sound_names) +
  global_theme

# ---- 6-subjects
subjects <- learning_sound_names %>%
  group_by(subj_id) %>%
  summarize(
    rt = mean(rt, na.rm = TRUE),
    error = mean(is_error, na.rm = TRUE)
  ) %>%
  mutate(
    rt_rank = rank(rt, ties.method = "random"),
    error_rank = rank(error, ties.method = "random")
  )

subj_plot <- ggplot(subjects) +
  geom_point(shape = 1) +
  geom_text(aes(label = subj_id), angle = 90, hjust = -0.1, size = 3) +
  scale_x_continuous("Rank", breaks = c(1, seq(5, nrow(subjects), by = 10)))

subj_plot +
  aes(rt_rank, rt) +
  scale_y_continuous("RT") +
  coord_cartesian(ylim = c(0, max(subjects$rt) + 200)) +
  global_theme

subj_plot +
  aes(error_rank, error) +
  scale_y_continuous("Error", labels = scales::percent) +
  coord_cartesian(ylim = c(0, max(subjects$error) + 0.1)) +
  global_theme

# ---- 6-drop-outliers
outliers <- c("LSN102", "LSN148", "LSN104", "LSN147")
learning_sound_names %<>% filter(!(subj_id %in% outliers))

# ---- 6-errors
ggbase_error <- ggbase
ggbase_error$mapping <- aes(block_ix, is_error)

error_plot <- ggbase_error +
  geom_line(aes(color = factor(message_label)),
            stat = "summary", fun.y = "mean",
            size = 1.2) +
  scale_x_block_ix +
  scale_y_continuous("Error rate", labels = percent) +
  scale_color_message_label +
  theme(legend.position = "top")
error_plot

# ---- 6-rts-over-trials
ggbase_rt <- ggbase +
  scale_x_trial_ix +
  scale_y_rt
ggbase_rt$mapping <- aes(trial_ix, rt)

ggbase_rt +
  geom_point(aes(color = factor(block_ix)), alpha = 0.2) +
  geom_smooth(aes(group = factor(block_ix), color = factor(block_ix)),
              method = "loess", se = FALSE) +
  coord_cartesian(ylim = c(0, 2000)) +
  scale_color_brewer(palette = "Set2") +
  theme(legend.position = "none") +
  facet_wrap("message_label_long") +
  labs(title = "RTs over blocks by transcription type")

ggbase_rt_ave <- ggbase +
  scale_x_block_ix +
  scale_y_rt
ggbase_rt_ave$mapping <- aes(block_ix, rt)

rt_plot <- ggbase_rt_ave +
  geom_line(aes(group = message_label, color = message_label),
            stat = "summary", fun.y = "mean", size = 1.2) +
  scale_color_message_label +
  theme(legend.position = "top")
rt_plot

# ---- 6-rt-transition


learning_sound_names %>%
  label_trial_in_block() %>%
  bin_trials("block_transition", "trial_in_block", before = )

# ---- 6-results
first_last_gen <- filter(learning_sound_names, message_type != "sound_effect")

grid.arrange(
  (rt_plot %+% first_last_gen) + 
    scale_color_message_label_2 +
    theme(legend.position = "none"),
  (error_plot %+% first_last_gen) +
    theme(legend.position = c(0.8, 0.9)) +
    scale_color_message_label_2,
  nrow = 1
)

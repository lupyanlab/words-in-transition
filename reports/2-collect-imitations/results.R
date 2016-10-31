library(ggplot2)
global_theme <- theme_minimal() +
  theme(axis.ticks = element_blank())

# ---- 2-setup
library(magrittr)
library(dplyr)
library(wordsintransition)
data("acoustic_similarity_linear")
data("acoustic_similarity_judgments")

z_score_by_subj <- function(frame) {
  z_score <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
  frame %>%
    group_by(name) %>%
    mutate(similarity_z = z_score(similarity)) %>%
    ungroup()
}

acoustic_similarity_judgments %<>%
  mutate(similarity = ifelse(similarity == -1, NA, similarity)) %>%
  z_score_by_subj

# ---- 2-raters
ggplot(acoustic_similarity_judgments, aes(x = similarity)) +
  geom_density(aes(color = name)) +
  scale_x_continuous(breaks = 1:7)

ggplot(acoustic_similarity_judgments, aes(x = similarity_z)) +
  geom_density(aes(color = name))

# ---- 2-similarity-judgments-within-chains
set.seed(604)
ggplot(acoustic_similarity_judgments, aes(x = edge_generations, y = similarity,
                                          color = category)) +
  geom_point(position = position_jitter(0.4, 0.2), shape = 1) +
  geom_line(aes(group = category), stat = "summary", fun.y = "mean") +
  geom_smooth(aes(group = 1), method = "lm", se = FALSE, color = "gray") +
  scale_y_continuous(breaks = 1:7) +
  global_theme

ggplot(acoustic_similarity_judgments, aes(x = edge_generations, y = similarity_z,
                                          color = category)) +
  geom_point(position = position_jitter(0.4, 0.2), shape = 1) +
  geom_line(aes(group = category), stat = "summary", fun.y = "mean") +
  geom_smooth(aes(group = 1), method = "lm", se = FALSE, color = "gray") +
  global_theme

# ---- 2-similarity-within-chains
set.seed(603)
ggplot(acoustic_similarity_linear, aes(x = edge_generations, y = similarity)) +
  geom_point(position = position_jitter(0.4, 0.0), shape = 1) +
  geom_line(aes(group = 1), stat = "summary", fun.y = "mean") +
  geom_smooth(aes(group = 1), method = "lm", se = FALSE) +
  global_theme

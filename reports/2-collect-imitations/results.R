library(ggplot2)
global_theme <- theme_minimal() +
  theme(axis.ticks = element_blank())

# ---- 2-setup
library(magrittr)
library(dplyr)
library(wordsintransition)
data("acoustic_similarity_linear")
data("acoustic_similarity_judgments")

acoustic_similarity_judgments %<>%
  mutate(similarity = ifelse(similarity == -1, NA, similarity))

# ---- 2-similarity-within-chains
set.seed(603)
ggplot(acoustic_similarity_linear, aes(x = edge_generations, y = similarity)) +
  geom_point(position = position_jitter(0.4, 0.0), shape = 1) +
  geom_line(aes(group = 1), stat = "summary", fun.y = "mean") +
  geom_smooth(aes(group = 1), method = "lm", se = FALSE) +
  global_theme

# ---- 2-similarity-judgments-within-chains
set.seed(604)
ggplot(acoustic_similarity_judgments, aes(x = edge_generations, y = similarity,
                                          color = category)) +
  geom_point(position = position_jitter(0.4, 0.2), shape = 1) +
  geom_line(aes(group = category), stat = "summary", fun.y = "mean") +
  geom_smooth(aes(group = 1), method = "lm", se = FALSE, color = "gray") +
  scale_y_continuous(breaks = 1:7) +
  global_theme
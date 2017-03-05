library(ggplot2)
global_theme <- theme_minimal() +
  theme(axis.ticks = element_blank())

# ---- 2-setup
library(magrittr)
library(dplyr)
library(lme4)
library(AICcmodavg)
library(wordsintransition)
data("acoustic_similarity_judgments")

z_score_by_subj <- function(frame) {
  z_score <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
  frame %>%
    group_by(name) %>%
    mutate(similarity_z = z_score(similarity)) %>%
    ungroup()
}

recode_edge_generations <- function(frame) {
  data_frame(
    edge_generations = c("1-2", "2-3", "3-4", "4-5", "5-6", "6-7", "7-8"),
    edge_generation_n = seq_along(edge_generations)
  ) %>%
    left_join(frame, .)
}

determine_trial_id <- function(frame) {
  # Warning! Ignores presentation order.
  mutate(frame, trial_id = paste(sound_x, ":", sound_y))
}

acoustic_similarity_judgments %<>%
  mutate(similarity = ifelse(similarity == -1, NA, similarity)) %>%
  z_score_by_subj() %>%
  recode_edge_generations() %>%
  determine_trial_id()

data("algo_linear")
data("algo_within_chain")
data("algo_within_seed")
data("algo_within_category")
data("algo_between_category")

algo_linear %<>%
  recode_edge_generations()

algo_between_category %<>%
  recode_edge_generations()

# ---- 2-raters
ggplot(acoustic_similarity_judgments, aes(x = similarity)) +
  geom_density(aes(color = name)) +
  scale_x_continuous(breaks = 1:7) +
  labs(title = "Distribution of similarity scores by rater")

ggplot(acoustic_similarity_judgments, aes(x = similarity_z)) +
  geom_density(aes(color = name)) +
  labs(title = "Distribution of similarity scores by rater (z-score)")

# ---- 2-similarity-judgments-within-chains
set.seed(604)
ggplot(acoustic_similarity_judgments, aes(x = edge_generations, y = similarity,
                                          color = category)) +
  geom_point(position = position_jitter(0.4, 0.2), shape = 1) +
  geom_line(aes(group = category), stat = "summary", fun.y = "mean") +
  geom_smooth(aes(group = 1), method = "lm", se = FALSE, color = "gray") +
  scale_y_continuous(breaks = 1:7) +
  global_theme +
  labs(title = "Raw similarity scores and category means")

ggplot(acoustic_similarity_judgments, aes(x = edge_generations, y = similarity_z,
                                          color = category)) +
  geom_point(position = position_jitter(0.4, 0.2), shape = 1) +
  geom_line(aes(group = category), stat = "summary", fun.y = "mean") +
  geom_smooth(aes(group = 1), method = "lm", se = FALSE, color = "gray") +
  global_theme +
  labs(title = "Mean similarity scores (z-score)")

# ---- 2-similarity-judgments-mod
similarity_judgments_mod <- lmer(similarity_z ~ edge_generation_n + 
                                   (edge_generation_n|name) + (edge_generation_n|category),
                                 data = acoustic_similarity_judgments)

similarity_judgments_preds <- data_frame(edge_generation_n = 1:7) %>%
  cbind(., predictSE(similarity_judgments_mod, newdata = ., se = TRUE)) %>%
  rename(similarity_z = fit, se = se.fit) %>%
  recode_edge_generations

# ---- 2-similarity-judgments-plot
similarity_judgments_means <- acoustic_similarity_judgments %>%
  group_by(edge_generations, category) %>%
  summarize(similarity_z = mean(similarity_z, na.rm = TRUE)) %>%
  recode_edge_generations

set.seed(949)
gg_similarity_judgments <- ggplot(similarity_judgments_means) +
  aes(x = edge_generations, y = similarity_z) +
  geom_point(aes(color = category), position = position_jitter(0.6, 0.0),
             size = 2, alpha = 0.8) +
  geom_smooth(aes(group = 1, ymin = similarity_z - se, ymax = similarity_z + se),
              data = similarity_judgments_preds, stat = "identity",
              alpha = 0.2, color = "gray") +
  scale_x_discrete("Generation") +
  scale_y_continuous("Acoustic similarity") +
  scale_color_brewer("Category", palette = "Set2") +
  global_theme +
  theme(legend.position = "top")
gg_similarity_judgments

# ---- 2-similarity-within-chains
similarity_linear_mod <- lm(similarity ~ edge_generation_n,
                            data = algo_linear)

set.seed(603)
ggplot(algo_linear, aes(x = edge_generations, y = similarity)) +
  geom_point(position = position_jitter(0.4, 0.0), shape = 1) +
  geom_line(aes(group = 1), stat = "summary", fun.y = "mean") +
  geom_smooth(aes(group = 1), method = "lm", se = FALSE) +
  global_theme

# ---- 2-acoustic-similarity-comparison
acoustic_similarity_comparison <- bind_rows(
    linear = algo_linear,
    within_chain = algo_within_chain,
    within_seed = algo_within_seed,
    within_category = algo_within_category,
    between_fixed = algo_between_category,
    .id = "edge_type"
  ) %>%
  mutate(
    edge_type_label = factor(edge_type, levels = c("linear", "within_chain", "within_seed", "within_category", "between_fixed"))
  )

ggplot(acoustic_similarity_comparison) +
  aes(edge_type_label, similarity) +
  geom_point(position = position_jitter(width = 0.2), alpha = 0.1) +
  geom_bar(stat = "summary", fun.y = "mean", alpha = 0.4)

library(ggplot2)
global_theme <- theme_minimal() +
  theme(axis.ticks = element_blank())

# ---- 3-setup
library(dplyr)
library(ggplot2)
library(scales)
library(grid)
library(tidyr)
library(lme4)
library(AICcmodavg)
library(pander)

# colors
colors <- RColorBrewer::brewer.pal(4, "Set2")
names(colors) <- c("green", "orange", "blue", "pink")
between_color <- colors[["green"]]
within_color <- colors[["blue"]]

# ggplot theme
distractor_labels <- c("Category match\n(true seed)", "Category match", "Specific match")
distractor_colors <- c(between_color, colors[["orange"]], within_color)

scale_y_accuracy <- scale_y_continuous(
  "Guess the seed accuracy",
  labels = percent,
  breaks = seq(0, 1, by = 0.25)
)
scale_x_generation <- scale_x_continuous(
  "Generation",
  breaks = 1:12
)
scale_x_generation_1 <- scale_x_continuous(
  "Generation",
  breaks = 0:11,
  labels = 1:12
)
scale_x_distractors <- scale_x_discrete(
  "",
  labels = distractor_labels
)
scale_fill_distractors <- scale_fill_manual(
  "",
  values = distractor_colors
)
scale_fill_categories <- scale_fill_manual(
  "",
  values = unname(colors)
)
scale_color_distractors <- scale_color_manual(
  "",
  values = distractor_colors,
  labels = distractor_labels
)

chance_line <- geom_hline(yintercept = 0.25, lty = 2, alpha = 0.4, size = 1.5)
chance_label <- annotate("text", x = 10, y = 0.26, label = "chance",
                         size = 7, vjust = -0.1, fontface = "italic", alpha = 0.4)

distractor_xlim <- c(-0.2, 7.2)
distractor_coords <- coord_cartesian(
  xlim = distractor_xlim,
  ylim = c(-0.02, 1.02)
)
distractor_diff_coords <- coord_cartesian(
  xlim = distractor_xlim,
  ylim = c(-0.02, 0.8)
)

# ---- 3-data
library(wordsintransition)
data("imitation_matches")
data("transcriptions")
data("transcription_matches")

survey_map <- data_frame(
  survey_type = c("between", "same", "within"),
  # Treatment contrasts
  same_v_between = c(1, 0, 0),
  same_v_within = c(0, 0, 1)
)

imitation_matches <- imitation_matches %>%
  filter(question_type != "catch_trial") %>%
  mutate(generation_1 = generation - 1) %>%
  left_join(survey_map)

question_type_map <- data_frame(
  question_type = c("exact", "category"),
  question_f = factor(question_type, levels = question_type),
  question_c = c(-0.5, 0.5)
)

transcription_matches <- transcription_matches %>%
  left_join(question_type_map)

# ---- 3-num-responses-per-question
response_counts <- imitation_matches %>%
  count(message_id, survey_type)

message_id_decr <- response_counts %>%
  group_by(message_id) %>%
  summarize(total_n = sum(n)) %>%
  arrange(desc(total_n)) %>%
  .$message_id
response_counts$message_id_decr <- factor(response_counts$message_id,
                                          levels = message_id_decr)

ggplot(response_counts, aes(x = message_id_decr, y = n)) +
  geom_bar(stat = "identity") +
  facet_wrap("survey_type", ncol = 1)

# ---- 3-models
imitation_matches_mod <- glmer(is_correct ~ generation_1 * (same_v_between + same_v_within) + 
                                 (generation_1|chain_name/seed_id),
                               family = "binomial", data = imitation_matches)

x_preds <- expand.grid(
  generation_1 = unique(imitation_matches$generation_1),
  survey_type = c("between", "same", "within"),
  stringsAsFactors = FALSE
) %>% left_join(survey_map) %>%
  mutate(
    generation = generation_1 + 1,
    generation_label = paste("Generation", generation)
  )

transition_preds <- predictSE(imitation_matches_mod, x_preds, se = TRUE) %>%
  cbind(x_preds, .) %>%
  rename(is_correct = fit, se = se.fit)

transcription_matches_mod <- glmer(is_correct ~ question_c + (1|word_category),
                                   family = "binomial", data = transcription_matches)

x_preds <- data.frame(question_c = c(-0.5, 0.5)) 
transcription_matches_preds <- predictSE(transcription_matches_mod, x_preds, se = TRUE) %>%
  cbind(x_preds, .) %>%
  rename(is_correct = fit, se = se.fit) %>%
  left_join(question_type_map)

# ---- 3-first-gen
ggplot(filter(transition_preds, generation_1 == 0), aes(x = survey_type, y = is_correct)) +
  geom_bar(aes(fill = survey_type), stat = "identity", width = 0.96) +
  geom_linerange(aes(ymin = is_correct - se, ymax = is_correct + se)) +
  scale_y_accuracy +
  scale_x_distractors +
  scale_fill_distractors +
  global_theme +
  chance_line +
  coord_cartesian(ylim = c(0, 1.0)) +
  theme(legend.position = "none") +
  ggtitle("First generation imitations")

# ---- 3-match-to-seed
ggplot(imitation_matches, aes(x = generation_1, y = is_correct)) +
  geom_smooth(aes(ymin = is_correct - se, ymax = is_correct + se, color = survey_type),
              stat = "identity", data = transition_preds,
              size = 2.0) +
  scale_x_generation_1 +
  scale_y_accuracy +
  scale_color_distractors +
  chance_line +
  distractor_coords +
  global_theme +
  theme(legend.position = "top", legend.key.size = unit(2, "lines"))

# ---- 3-first-last-gen
ggplot(filter(transition_preds, generation_1 %in% c(0,7)), aes(x = survey_type, y = is_correct)) +
  geom_bar(aes(fill = survey_type), stat = "identity", width = 0.96) +
  geom_linerange(aes(ymin = is_correct - se, ymax = is_correct + se)) +
  facet_wrap("generation_label") +
  scale_y_accuracy +
  scale_x_distractors +
  scale_fill_distractors +
  global_theme +
  chance_line +
  coord_cartesian(ylim = c(0, 1.0)) +
  theme(legend.position = "none")

# ---- 3-transcription-agreement
examples <- transcriptions %>%
  filter(
    transcription_survey_name == "hand picked 1",
    is_catch_trial == 0
  ) %>%
  count(chain_name, seed_id, text) %>%
  arrange(desc(n)) %>%
  mutate(order = 1:n()) %>%
  filter(order == 1, n > 1) %>%
  select(-order) %>%
  ungroup() %>%
  arrange(desc(n))

examples$text <- factor(examples$text, levels = examples$text)

ggplot(examples, aes(x = text, y = n)) +
  geom_bar(aes(fill = chain_name), stat = "identity") +
  geom_text(aes(label = text), vjust = -0.4, size = 8, angle = 45, hjust = 0) + 
  scale_x_discrete("") +
  scale_y_continuous("Frequency of spelling", breaks = seq(0, 10, by = 2)) +
  scale_fill_categories +
  coord_cartesian(ylim = c(0, 11)) +
  global_theme +
  theme(
    legend.position = "top",
    axis.text.x = element_blank()
  ) +
  ggtitle("Transcription agreement")

# ---- 3-transcription-matches
ggplot(transcription_matches, aes(x = question_f, y = is_correct)) +
  geom_bar(aes(fill = question_f), stat = "identity", data = transcription_matches_preds,
           width = 0.96) +
  geom_linerange(aes(ymin = is_correct - se, ymax = is_correct + se), data = transcription_matches_preds) +
  chance_line +
  coord_cartesian(ylim = c(0, 1.0)) +
  scale_x_discrete("", labels = c("Category match (true seed)", "Category match")) +
  scale_y_accuracy +
  scale_fill_categories +
  global_theme +
  theme(legend.position = "none") +
  ggtitle("Guess the seed accuracy with transcriptions")
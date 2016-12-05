library(ggplot2)
global_theme <- theme_minimal() +
  theme(axis.ticks = element_blank())

colors <- RColorBrewer::brewer.pal(4, "Set2")
names(colors) <- c("blue", "orange", "green", "pink")
question_type_colors <- unname(colors[c("green", "blue")])

# ---- 5-setup
library(dplyr)
library(magrittr)
library(stringr)
library(ggplot2)
library(scales)
library(lme4)
library(broom)
library(AICcmodavg)

library(wordsintransition)
data("transcription_matches")

transcription_matches %<>%
  recode_question_type %>%
  recode_message_type %>%
  recode_version

bad_subj_ids <- transcription_matches %>%
  filter(question_type == "catch_trial", is_correct == 0) %>%
  .$subj_id %>% unique

catch_trials <- transcription_matches %>%
  filter(question_type == "catch_trial")

transcription_matches %<>%
  filter(question_type != "catch_trial",
         !(subj_id %in% bad_subj_ids))

all_transcription_matches <- transcription_matches
transcription_matches %<>% filter(message_type != "sound_effect")

scale_x_message <- scale_x_continuous("Transcriptions", breaks = c(-0.5, 0.5), labels = c("First generation", "Last generation"))
scale_x_question <- scale_x_continuous("Question type", breaks = c(-0.5, 0.5), labels = c("Match to exact sound", "Match to same category"))
scale_y_accuracy <- scale_y_continuous("Match to seed accuracy", labels = percent,
                                       breaks = c(0, 0.5, by = 0.05))
scale_fill_question_type <- scale_fill_brewer(palette = "Set2")

gg <- ggplot(transcription_matches, aes(x = question_c, y = is_correct, fill = question_type)) +
  geom_hline(yintercept = 0.25, lty = 2, alpha = 0.6) +
  scale_x_question +
  scale_y_accuracy +
  scale_fill_question_type +
  coord_cartesian(ylim = c(0.0, 0.61)) +
  global_theme

# ---- 5-subjects
transcription_matches %>%
  group_by(version) %>%
  summarize(
    num_subjects = length(unique(subj_id)),
    num_responses_per_subject = round(n()/num_subjects)
  ) %>%
  knitr::kable(col.names = c("Version", "Subjects", "Responses per subject"),
               align = "l")

# ---- 5-num-sounds-transcribed-and-matched
data("imitations")
data("transcriptions")

imitations %<>%
  filter(game_name == "words-in-transition")

gen_labels <- imitations %>%
  select(message_id, generation)

transcriptions %<>%
  filter(is_catch_trial == 0) %>%
  # label the generation of the imitations being transcribed
  left_join(gen_labels) %>%
  recode_message_type

base <- ggplot() +
  global_theme

scale_x_generation <- scale_x_continuous(breaks = 0:8)

hist <- base +
  geom_histogram(aes(x = generation), binwidth = 1,
                 color = "black", fill = "white", alpha = 0.6) +
  scale_x_generation

transcribed_imitations <- imitations %>%
  filter(message_id %in% transcriptions$message_id)

matched_imitation_transcriptions <- imitations %>%
  filter(message_id %in% transcription_matches$message_id)

(hist %+% transcribed_imitations) +
  geom_histogram(aes(x = generation), data = imitations,
                 binwidth = 1, fill = "black", alpha = 0.2) +
  geom_histogram(aes(x = generation), data = matched_imitation_transcriptions,
                 binwidth = 1, fill = "red", alpha = 0.4) +
  ggtitle("Proportion of sounds transcribed and matched")

# ---- 5-prop-transcriptions-matched

# Of the sounds that were transcribed, what
# proportion of the transcriptions were used
# in the match to imitation surveys?
# > the top 4 most frequent transcriptions

# ---- 5-responses-per-question
decr_word_n <- count(transcription_matches, word) %>%
  arrange(-n) %>% 
  .$word
transcription_matches$word_decr <- factor(
  transcription_matches$word, levels = decr_word_n
)

ggplot(transcription_matches, aes(x = word_decr)) +
  geom_bar(stat = "count") +
  facet_wrap("question_type", ncol = 1)

# ---- 5-catch-trials
exclusions <- catch_trials %>%
  mutate(is_correct_f = factor(is_correct, labels = c("Failed", "Passed"))) %>%
  group_by(is_correct_f) %>%
  summarize(n = length(unique(subj_id)))

ggplot(exclusions, aes(x = is_correct_f, y = n)) +
  geom_bar(stat = "identity") +
  scale_x_discrete("")

# ---- 5-plot-means
means_plot <- gg + geom_bar(stat = "summary", fun.y = "mean",
                            width = 0.99, alpha = 0.8)
means_plot + 
  facet_wrap("message_type") +
  ggtitle("Match accuracy by origin of transcription")

# ---- 5-match-transcription-to-seed-mod
acc_mod <- glmer(is_correct ~ question_c * message_c + (question_c * message_c|subj_id),
                 family = binomial, data = transcription_matches)

x_preds <- expand.grid(question_c = c(-0.5, 0.5), message_c = c(-0.5, 0.5))
y_preds <- predictSE(acc_mod, x_preds, se = TRUE)
preds <- cbind(x_preds, y_preds) %>%
  rename(is_correct = fit, se = se.fit) %>%
  recode_question_type %>%
  recode_message_type

# ---- 5-match-transcription-to-seed-plot
gg_match_transcription <- (gg %+% preds) +
  geom_bar(stat = "identity", width = 0.99, alpha = 0.6) +
  geom_linerange(aes(ymin = is_correct - se, ymax = is_correct + se)) +
  facet_wrap("message_label")
gg_match_transcription

# ---- 5-matching-by-transcription-agreement
data("transcription_distances")

transcription_distances %<>%
  left_join(select(transcription_frequencies, message_id, text, n))

transcription_agreement <- transcription_distances %>%
  group_by(message_id) %>%
  summarize(agreement = 1 - weighted.mean(distance, n))

matching_summary <- transcription_matches %>%
  group_by(message_id, seed_id, generation, question_type) %>%
  summarize(matching_accuracy = mean(is_correct))

matching_by_agreement <- left_join(matching_summary, transcription_agreement) %>%
  recode_message_type

gg_matching_by_agreement <- matching_by_agreement %>%
  ggplot(aes(agreement, matching_accuracy)) +
  geom_point()

mod1 <- lm(matching_accuracy ~ agreement, data = matching_by_agreement)
tidy(mod1) %>%
  kable(caption = "Overall relationship between agreement predicting matching accuracy.")

gg_matching_by_agreement

mod2 <- lm(matching_accuracy ~ agreement * question_type, data = matching_by_agreement)
tidy(mod2) %>%
  kable(caption = "Model results with an agreement x question type (true seed or category match) interaciton term.")

gg_matching_by_agreement +
  facet_wrap("question_type") +
  geom_smooth(method = "lm")

mod3 <- lm(matching_accuracy ~ agreement * message_type, data = matching_by_agreement)
tidy(mod3) %>%
  kable(caption = "Model results allowing an interaction between agreement x message type (first or last generation).")

gg_matching_by_agreement +
  facet_wrap("message_type") +
  geom_smooth(method = "lm")

mod4 <- lm(matching_accuracy ~ agreement * message_type * question_type, data = matching_by_agreement)
tidy(mod4) %>%
  kable(caption = "Model results with three way interaction.")

gg_matching_by_agreement +
  facet_grid(message_type ~ question_type) +
  geom_smooth(method = "lm")

# ----- 5-transcriptions-of-seeds
(gg %+% all_transcription_matches) +
  geom_bar(stat = "summary", fun.y = "mean", width = 0.99, alpha = 0.6) +
  geom_point(aes(group = message_id), stat = "summary", fun.y = "mean",
             position = position_jitter(width = 0.1), alpha = 0.6, shape = 1) +
  facet_wrap("message_type") +
  coord_cartesian(ylim = c(0, 1))
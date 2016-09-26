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
         !(subj_id %in% bad_subj_ids),
         message_type != "sound_effect")

scale_x_message <- scale_x_continuous("Transcriptions", breaks = c(-0.5, 0.5), labels = c("First generation", "Last generation"))
scale_x_question <- scale_x_continuous("Question type", breaks = c(-0.5, 0.5), labels = c("Match to exact sound", "Match to same category"))
scale_y_accuracy <- scale_y_continuous("Match to seed accuracy", labels = percent,
                                       breaks = c(0, 1, by = 0.25))

gg <- ggplot(transcription_matches, aes(x = question_c, y = is_correct)) +
  geom_hline(yintercept = 0.25, lty = 2, alpha = 0.6) +
  scale_x_question +
  scale_y_accuracy +
  coord_cartesian(ylim = c(0.0, 0.61)) +
  theme_minimal(base_size = 12) +
  theme(axis.ticks = element_blank())

# ---- 5-num-sounds-transcribed-and-matched
data("imitatons")
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
  theme_minimal()

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
                            width = 0.99, alpha = 0.6)
means_plot + 
  facet_wrap("message_type") +
  ggtitle("Match accuracy by origin of transcription")

# ---- 5-model
acc_mod <- glmer(is_correct ~ question_c * message_c + (question_c * message_c|subj_id),
                 family = binomial, data = transcription_matches)
tidy(acc_mod, effects = "fixed")

# ---- 5-model-preds
x_preds <- expand.grid(question_c = c(-0.5, 0.5), message_c = c(-0.5, 0.5))
y_preds <- predictSE(acc_mod, x_preds, se = TRUE)
preds <- cbind(x_preds, y_preds) %>%
  rename(is_correct = fit, se = se.fit) %>%
  recode_question_type %>%
  recode_message_type

model_plot <- (gg %+% preds) +
  geom_bar(stat = "identity", width = 0.99, alpha = 0.6) +
  geom_linerange(aes(ymin = is_correct - se, ymax = is_correct + se)) +
  facet_wrap("message_label")
model_plot + ggtitle("GLM point estimates with standard error bars")

model_plot +
  geom_point(data = transcription_matches, stat = "summary", fun.y = "mean") +
  ggtitle("GLM predictions with overlayed sample means")

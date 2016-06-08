# ---- setup
library(dplyr)
library(magrittr)
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

# ---- data
bad_subj_ids <- transcription_matches %>%
  filter(question_type == "catch_trial", is_correct == 0) %>%
  .$subj_id %>% unique

transcription_matches <- transcription_matches %>%
  filter(question_type != "catch_trial", !(subj_id %in% bad_subj_ids))

# ---- plot-template
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

# ---- plot-means
means_plot <- gg + geom_bar(stat = "summary", fun.y = "mean",
                            width = 0.99, alpha = 0.6)
means_plot + ggtitle("Match accuracy by type of match")
means_plot + 
  facet_wrap("message_label") +
  ggtitle("Match accuracy by origin of transcription")
means_plot +
  facet_grid(version_label ~ message_label) +
  ggtitle("Match accuracy over experiment versions")

# ---- model
acc_mod <- glmer(is_correct ~ question_c * message_c + (question_c * question_c|subj_id),
                 family = binomial, data = transcription_matches)
tidy(acc_mod, effects = "fixed")

# ---- model-preds
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

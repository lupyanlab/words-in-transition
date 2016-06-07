# ---- setup
library(dplyr)
library(ggplot2)
library(lme4)

library(wordsintransition)
data("transcription_matches")

# ---- data
bad_subj_ids <- transcription_matches %>%
  filter(question_type == "catch_trial", is_correct == 0) %>%
  .$subj_id %>% unique

transcription_matches <- transcription_matches %>%
  filter(question_type != "catch_trial", !(subj_id %in% bad_subj_ids))

# ---- model
#acc_mod <- glmer(is_correct ~)

# ---- model-preds

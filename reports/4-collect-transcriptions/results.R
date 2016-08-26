# ---- 4-setup
library(ggplot2)
library(scales)
library(dplyr)
library(magrittr)

library(wordsintransition)
data("imitations")
data("transcriptions")
data("transcription_frequencies")

imitations %<>%
  filter(game_name == "words-in-transition")

transcriptions %<>%
  filter(is_catch_trial == 0) %>%
  # label the generation of the imitations being transcribed
  left_join(imitations[, c("imitation_id", "generation")])


base <- ggplot() +
  theme_minimal()

scale_x_generation <- scale_x_continuous(breaks = 0:8)

hist <- base +
  geom_histogram(aes(x = generation), binwidth = 1,
                 color = "black", fill = "white", alpha = 0.6) +
  geom_text(aes(x = generation, label = ..count..),
            stat = "bin", binwidth = 1, vjust = -0.6) +
  scale_x_generation

# ---- 4-num-sounds-transcribed
transcribed_imitations <- imitations %>%
  filter(imitation_id %in% transcriptions$imitation_id)

(hist %+% transcribed_imitations) +
  ggtitle("Number of transcribed sounds")

hist_no_labels <- hist
hist_no_labels$layers[[2]] <- NULL

(hist_no_labels %+% transcribed_imitations) +
  geom_histogram(aes(x = generation), data = imitations,
                 binwidth = 1, fill = "black", alpha = 0.2) +
  ggtitle("Proportion of sounds transcribed")

# ---- 4-num-transcriptions-per-imitation
decr_imitation_ids <- count(transcriptions, imitation_id) %>%
  arrange(-n) %>% 
  .$imitation_id
transcriptions$imitation_id_decr <- factor(transcriptions$imitation_id,
                                           levels = decr_imitation_ids)
ylim_upr <- (transcriptions %>% count(imitation_id) %>% .$n %>% max) + 4

(base %+% transcriptions) +
  geom_bar(aes(x = imitation_id_decr, fill = generation), stat = "count",
           width = 1.0, color = "white", alpha = 0.8) +
  scale_x_discrete("Imitation ID") +
  scale_y_continuous(expand = c(0, 0)) +
  ggtitle("Transcriptions per sound") +
  coord_cartesian(ylim = c(0, ylim_upr)) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1.0, vjust = 0.5))

# ---- 4-transcription-agreement
transcription_frequencies %<>%
  mutate(message_id = imitation_id) %>%
  recode_message_type

transcription_uniqueness <- transcription_frequencies %>%
  group_by(message_type, imitation_id) %>%
  summarize(
    num_words = sum(n),
    num_unique = n_distinct(text),
    perct_unique = num_unique/num_words,
    perct_agreement = 1 - perct_unique
  )

set.seed(752)  # for replicable position_jitter
ggplot(transcription_uniqueness, aes(x = message_type, y = perct_agreement)) +
  geom_point(position = position_jitter(0.1, 0.0), shape = 1) +
  geom_point(stat = "summary", fun.y = "mean", size = 2) +
  scale_y_continuous("Transcription agreement", labels = percent)

# ---- 4-transcription-agreement-and-match-accuracy
data("transcription_matches")

transcription_matches %<>%
  filter(question_type != "catch_trial", version != "pilot") %>%
  mutate(imitation_id = message_id) %>%
  recode_message_type

transcription_match_accuracies <- transcription_matches %>%
  group_by(imitation_id, message_type, question_type) %>%
  summarize(
    match_accuracy = mean(is_correct)
  )

transcription_agreement_and_uniqueness <- transcription_uniqueness %>%
  select(message_type, imitation_id, perct_agreement) %>%
  left_join(transcription_match_accuracies) %>%
  filter(!is.na(question_type))

base <- ggplot(transcription_agreement_and_uniqueness,
               aes(x = perct_agreement, y = match_accuracy, color = message_type))
base +
  geom_point(stat = "summary", fun.y = "mean") +
  ggtitle("Relationship betwen transcription agreement and match accuracy\nacross both question types")

base +
  geom_point() +
  facet_wrap("question_type") +
  ggtitle("Relationship between transcription agreement and match accuracy\nby question type")
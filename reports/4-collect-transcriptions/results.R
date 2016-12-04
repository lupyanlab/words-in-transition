library(ggplot2)
global_theme <- theme_minimal() +
  theme(axis.ticks = element_blank())

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

gen_labels <- imitations %>%
  select(message_id, generation)

transcriptions %<>%
  filter(is_catch_trial == 0) %>%
  # label the generation of the imitations being transcribed
  left_join(gen_labels) %>%
  recode_message_type

transcription_frequencies %<>%
  left_join(gen_labels)

base <- ggplot() +
  global_theme

scale_x_generation <- scale_x_continuous(breaks = 0:8)

hist <- base +
  geom_histogram(aes(x = generation), binwidth = 1,
                 color = "black", fill = "white", alpha = 0.6) +
  geom_text(aes(x = generation, label = ..count..),
            stat = "bin", binwidth = 1, vjust = -0.6) +
  scale_x_generation

# ---- 4-num-sounds
hist %+% imitations

# ---- 4-num-sounds-transcribed
transcribed_imitations <- imitations %>%
  filter(message_id %in% transcriptions$message_id)

(hist %+% transcribed_imitations) +
  ggtitle("Number of transcribed sounds")

hist_no_labels <- hist
hist_no_labels$layers[[2]] <- NULL

(hist_no_labels %+% transcribed_imitations) +
  geom_histogram(aes(x = generation), data = imitations,
                 binwidth = 1, fill = "black", alpha = 0.2) +
  ggtitle("Proportion of sounds transcribed")

# ---- 4-num-transcriptions-per-imitation
decr_message_ids <- count(transcriptions, message_id) %>%
  arrange(-n) %>% 
  .$message_id
transcriptions$message_id_decr <- factor(transcriptions$message_id,
                                           levels = decr_message_ids)
ylim_upr <- (transcriptions %>% count(message_id) %>% .$n %>% max) + 4

(base %+% transcriptions) +
  geom_bar(aes(x = message_id_decr, fill = message_type), stat = "count",
           width = 1.0, color = "white", alpha = 0.8) +
  scale_x_discrete("Imitation ID") +
  scale_y_continuous(expand = c(0, 0)) +
  ggtitle("Transcriptions per sound") +
  coord_cartesian(ylim = c(0, ylim_upr)) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1.0, vjust = 0.5))

# ---- 4-transcription-agreement-exact
transcription_frequencies %<>%
  recode_message_type %>%
  filter(message_type != "sound_effect")

transcription_uniqueness <- transcription_frequencies %>%
  group_by(message_type, message_label, message_id) %>%
  summarize(
    num_words = sum(n),
    num_unique = n_distinct(text),
    perct_unique = num_unique/num_words,
    perct_agreement = 1 - perct_unique
  ) %>%
  ungroup %>%
  mutate(
    no_agreement = as.integer(perct_agreement == 0)
  ) %>%
  recode_transcription_frequency

set.seed(752)  # for replicable position_jitter
ggplot(transcription_uniqueness, aes(x = message_label, y = perct_agreement)) +
  geom_point(aes(color = frequency_type),
             position = position_jitter(0.1, 0.01), shape = 1) +
  geom_point(stat = "summary", fun.y = "mean", size = 3, alpha = 0.6) +
  geom_point(aes(color = frequency_type), stat = "summary", fun.y = "mean",
             size = 3, alpha = 0.6) +
  scale_y_continuous("Transcription agreement", labels = percent) +
  global_theme

# ---- 4-transcription-agreement-distance
data("transcription_distances")

message_id_map <- select(imitations, message_id, seed_id, generation)

transcription_distances %<>%
  left_join(message_id_map) %>%
  recode_transcription_frequency %>%
  recode_message_type %>%
  filter(message_type != "sound_effect")

distance_plot <- ggplot(transcription_distances, aes(message_label, distance)) +
  labs(x = "", y = "Average distance to most frequent transcription") +
  global_theme

gg_distance <- distance_plot +
  geom_bar(stat = "summary", fun.y = "mean",
           alpha = 0.6, width = 0.96) +
  geom_point(aes(group = message_id), stat = "summary", fun.y = "mean",
             shape = 1, position = position_jitter(0.3, 0.01)) +
  labs(title = "Distances get shorter")
gg_distance

# ---- 4-transcription-agreement-distance-separate
distance_plot + 
  geom_bar(aes(fill = frequency_type, width = 0.96), stat = "summary", fun.y = "mean",
           alpha = 0.6) +
  geom_point(aes(color = frequency_type, group = message_id), stat = "summary", fun.y = "mean",
             shape = 1, position = position_jitter(0.3, 0.01)) +
  facet_wrap("frequency_type") +
  guides(color = "none", fill = "none")

# ---- 4-transcription-length
length_plot <- ggplot(transcription_distances, aes(message_label, length)) +
  geom_point(aes(group = message_id, color = frequency_type), stat = "summary", fun.y = "mean",
             shape = 1, position = position_jitter(0.3, 0.1)) +
  geom_line(aes(group = frequency_type, color = frequency_type), stat = "summary", fun.y = "mean") +
  labs(x = "", y = "Average longest substr match length",
       title = "Matches get longer") + 
  global_theme
length_plot
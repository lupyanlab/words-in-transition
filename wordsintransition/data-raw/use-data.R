# Load all csvs in the data-raw directory and save them to the R package

library(devtools)
library(readr)
library(dplyr)
library(stringr)
library(magrittr)
library(lazyeval)

data_files <- list.files("data-raw", pattern = "*.csv", full.names = TRUE,
                         recursive = TRUE)
stem <- function(path) strsplit(basename(path), "\\.")[[1]][1]

for(path in data_files) {
  frame <- read_csv(path)
  name <- stem(path)
  assign(name, frame)
}

# Read these in separately because they are named the same.
sound_similarity_6 <- read_csv("data-raw/sound_similarity_6/odd_one_out.csv")
sound_similarity_4 <- read_csv("data-raw/sound_similarity_4/odd_one_out.csv")

generation_map <- imitations[, c("message_id", "generation")]

# Label generation of message being transcribed
transcription_matches %<>%
  left_join(generation_map)

# Label generation of linear messages
label_edge <- function(frame, edge_col) {
  generation_col_name <- paste(edge_col, "generation", sep = "_")
  generation_map %>%
    plyr::rename(c("message_id" = edge_col, "generation" = generation_col_name)) %>%
    left_join(frame, .)
}

label_edge_generation <- function(frame) {
  edge_combinations <- frame %>%
    select(contains("generation")) %>%
    unique %>%
    arrange(sound_x_generation) %>%
    mutate(
      edge_generations = paste(sound_x_generation, sound_y_generation, sep = "-")
    )
  frame %>%
    left_join(edge_combinations)
}

acoustic_similarity_linear <- linear %>%
  label_edge("sound_x") %>%
  label_edge("sound_y") %>%
  label_edge_generation

acoustic_similarity_judgments <- judgments %>%
  label_edge("sound_x") %>%
  label_edge("sound_y") %>%
  label_edge_generation

# Shorten long csv names
lsn_questionnaire <- learning_sound_names_questionnaire_v1
lsn_subj_info <- learning_sound_names_subject_info

use_data(
  subjects,
  sound_similarity_6,
  sound_similarity_4,
  final_seeds,
  imitations,
  imitation_matches,
  transcriptions,
  transcription_frequencies,
  transcription_distances,
  transcription_matches,
  acoustic_similarity_linear,
  acoustic_similarity_judgments,
  learning_sound_names,
  lsn_questionnaire,
  lsn_subj_info,
  overwrite = TRUE
)

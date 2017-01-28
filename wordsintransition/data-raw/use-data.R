# Load all csvs in the data-raw directory and save them to the R package

library(devtools)
library(readr)
library(dplyr)
library(stringr)
library(magrittr)
library(lazyeval)

data_files <- list.files("data-raw", pattern = "*.csv", full.names = TRUE,
                         recursive = FALSE)
stem <- function(path) strsplit(basename(path), "\\.")[[1]][1]

for(path in data_files) {
  frame <- read_csv(path)
  name <- stem(path)
  assign(name, frame)
}

label_subjects <- function(frame, experiment, response_col = "response_id", drop_na_subjs = TRUE) {
  subjects_in_experiment <- subjects[subjects$experiment == experiment, c("subj_id", "response_id")]

  if (response_col != "response_id") {
    subjects_in_experiment[response_col] <- subjects_in_experiment$response_id
    subjects_in_experiment$response_id <- NULL
  }

  if (drop_na_subjs) {
    subjects_in_experiment %<>% na.omit()
    labeled <- inner_join(frame, subjects_in_experiment)
  } else {
    labeled <- left_join(frame, subjects_in_experiment)
  }

  labeled
}

# Seed selection ---------------------------------------------------------------
# Read these in separately because they are named the same.
sound_similarity_6 <- read_csv("data-raw/sound_similarity_6/odd_one_out.csv")
sound_similarity_4 <- read_csv("data-raw/sound_similarity_4/odd_one_out.csv")

# Imitations -------------------------------------------------------------------
# Label generations for all messages, then drop those from unknown subjects.
imitations %<>%
  label_subjects("imitations", "message_id", drop_na_subj = FALSE)
generation_map <- imitations[, c("message_id", "generation")]
imitations %<>% filter(!is.na(subj_id))

# Acoustic similarity measures -------------------------------------------------
# Label generation of linear messages.
label_edge <- function(frame, edge_col) {
  generation_col_name <- paste(edge_col, "generation", sep = "_")
  generation_map %>%
    plyr::rename(c("message_id" = edge_col, "generation" = generation_col_name)) %>%
    left_join(frame, .)
}

label_edge_generation <- function(frame) {
  edge_combinations <- frame %>%
    select(contains("generation")) %>%
    unique() %>%
    arrange(sound_x_generation) %>%
    mutate(
      edge_generations = paste(sound_x_generation, sound_y_generation, sep = "-")
    )
  frame %>%
    left_join(edge_combinations)
}

acoustic_similarity_linear <- read_csv("data-raw/acoustic-similarity/linear.csv") %>%
  label_edge("sound_x") %>%
  label_edge("sound_y") %>%
  label_edge_generation()

acoustic_similarity_judgments <- read_csv("data-raw/acoustic-similarity/judgments.csv") %>%
  label_edge("sound_x") %>%
  label_edge("sound_y") %>%
  label_edge_generation()

# Imitation matches ------------------------------------------------------------
imitation_matches %<>%
  label_subjects("imitation_matches") %>%
  left_join(generation_map)

# Transcriptions ---------------------------------------------------------------
transcriptions %<>%
  label_subjects("transcriptions", "transcription_id")

# Transcription matches --------------------------------------------------------
transcription_matches %<>%
  # Subjects are already labeled because transcription matches
  # was conducted both on Qualtrics and on the Telephone app.
  filter(!is.na(subj_id)) %>%
  # Label generation of message being transcribed
  left_join(generation_map)

# Learning sound names ---------------------------------------------------------

# Shorten long csv names
lsn_questionnaire <- learning_sound_names_questionnaire_v1
lsn_subj_info <- learning_sound_names_subject_info

# Use data in "wordsintransition" package --------------------------------------
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

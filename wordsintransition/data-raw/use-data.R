# Load all csvs in the data-raw directory and save them to the R package

library(devtools)
library(readr)
library(dplyr)
library(stringr)

sound_similarity_6 <- read_csv("data-raw/sound_similarity_6/odd_one_out.csv")
sound_similarity_4 <- read_csv("data-raw/sound_similarity_4/odd_one_out.csv")

data_files <- list.files("data-raw", pattern = "*.csv", full.names = TRUE)
stem <- function(path) strsplit(basename(path), "\\.")[[1]][1]

for(path in data_files) {
  frame <- read_csv(path)
  name <- stem(path)
  assign(name, frame)
}

use_data(
  subjects,
  sound_similarity_6,
  sound_similarity_4,
  final_seeds,
  imitations,
  imitation_matches,
  transcriptions,
  transcription_frequencies,
  transcription_matches,
  overwrite = TRUE
)

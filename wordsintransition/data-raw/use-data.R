# Load all csvs in the data-raw directory and save them to the R package

library(devtools)
library(readr)
library(dplyr)
library(stringr)

data_files <- list.files("data-raw", pattern = "*.csv", full.names = TRUE)
stem <- function(path) strsplit(basename(path), "\\.")[[1]][1]

for(path in data_files) {
  frame <- read_csv(path)
  name <- stem(path)
  assign(name, frame)
}

# Tidy responses data
# TODO: Move these functions to invoke tasks.
responses <- mutate(responses,
                    is_correct = as.numeric(selection == answer),
                    chance = 0.25)

use_data(messages, questions, responses, subjects, surveys, overwrite = TRUE)

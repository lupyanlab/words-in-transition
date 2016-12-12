library(wordsintransition)
library(dplyr)

context("Bin trials")

test_that("bin trials creates new col", {
  frame <- data_frame(trial_ix = 1:50)
  new_col_name <- "new_bin"
  result <- bin_trials(frame, new_col_name, first_trial = 1)
  expect_true((new_col_name %in% colnames(result)))
})

test_that("new col contains trial labels", {
  frame <- data_frame(trial_ix = 1:50)
  new_col_name <- "new_bin"
  result <- bin_trials(frame, new_col_name, first_trial = 1)
  expect_true("first_trial" %in% unique(result[[new_col_name]]))
})

test_that("trial bins are correct length", {
  frame <- data_frame(trial_ix = 1:50)
  new_col_name <- "new_bin"
  test_bin <- 1:10
  expected_bin_length <- length(1:10)
  result <- bin_trials(frame, new_col_name, test_bin = test_bin)
  expect_equal(sum(result[new_col_name] == "test_bin", na.rm = TRUE), expected_bin_length)
})

test_that("multiple trial bins", {
  frame <- data_frame(trial_ix = 1:50)
  new_col_name <- "new_bin"
  result <- bin_trials(frame, new_col_name, first_bin = 1, last_bin = 50)
  unique_vals <- unique(result[[new_col_name]])
  expect_true("first_bin" %in% unique_vals)
  expect_true("last_bin" %in% unique_vals)
})

context("Label trial number in block")

test_that("trials within blocks are labeled correctly", {
  frame <- data_frame(subj_id = c("a", "b"), trial_ix = 1:2, block_ix = 1:2)
  result <- label_trial_in_block(frame)
  expected <- c(1, 1)  # both trials are first in their block
  expect_equal(result$trial_in_block, expected)
})

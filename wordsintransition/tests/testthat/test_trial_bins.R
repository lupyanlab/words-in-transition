library(wordsintransition)

context("Bin trials")

test_that("bin trials creates new col", {
  frame <- data_frame(trial_ix = 1:50)
  new_col_name <- "new_bin"
  result <- bin_trials(frame, new_col_name, first_trial = 1)
  expect_true((new_col_name %in% colnames(result)))
})

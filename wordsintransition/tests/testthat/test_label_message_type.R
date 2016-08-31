library(wordsintransition)

library(dplyr)
library(magrittr)

context("Recode message type correctly")

test_that("recoding messages works as expected", {
  messages <- data_frame(
    message_id = c(1, 2),
    seed_id = c(1, 1)
  )

  recoded <- recode_message_type(messages)
  expect_equal(recoded$message_type, c("sound_effect", "imitation"))
})

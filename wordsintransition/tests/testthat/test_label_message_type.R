library(wordsintransition)

library(dplyr)
library(magrittr)

context("Recode message type correctly")

test_that("recoding messages works as expected", {
  messages <- data_frame(
    message_id = c(1, 2),
    seed_id = c(1, 1),
    generation = c(0, 1)
  )

  recoded <- recode_message_type(messages)
  expect_equal(recoded$message_type, c("sound_effect", "first_gen_imitation"))
})

test_that("recoding messages by generation", {
  messages <- data_frame(
    message_id = c(1, 2, 3),
    seed_id = c(1, 1, 1),
    generation = c(0, 1, 2)
  )

  recoded <- recode_message_type(messages)
  expect_equal(recoded$message_type, c("sound_effect", "first_gen_imitation", "last_gen_imitation"))
})

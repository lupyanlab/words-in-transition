
#' @export
count_valid_responses <- function(frame) {
  frame <- filter(frame,
                  failed_catch_trial == 0,
                  problem_with_audio == 0)

  counts <- frame %>%
    count(category, filename) %>%
    arrange(desc(n))
}

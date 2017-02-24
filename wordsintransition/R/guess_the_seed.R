#' Label chance for 4AFC "Guess the seed" task
#' @import dplyr
#' @export
add_chance <- function(frame) {
  frame %>%
    mutate(
      chance = 0.25,
      chance_log = log(chance)
    )
}

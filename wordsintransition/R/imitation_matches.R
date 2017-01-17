#' Recode survey type for modeling.
#' @import dplyr
#' @export
recode_survey_type <- function(frame) {
  survey_map <- data_frame(
    survey_type = c("between", "same", "within"),
    # Treatment contrasts
    same_v_between = c(1, 0, 0),
    same_v_within = c(0, 0, 1)
  )
  left_join(frame, survey_map)
}


#' Recode generation to have a meaningful 0 value.
#'
#' Where generation_1 == 0, generation == 1.
#'
#' @import dplyr
#' @export
recode_generation <- function(frame) {
  frame %>% mutate(generation_1 = generation - 1)
}

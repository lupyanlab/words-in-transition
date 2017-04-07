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
  if (missing(frame)) return(survey_map)
  left_join(frame, survey_map)
}


#' Recode generation to have a meaningful 0 value.
#'
#' Where generation_1 == 0, generation == 1.
#'
#' @import dplyr
#' @export
recode_generation <- function(frame) {
  generation_map <- data_frame(
    generation = 1:8,
    generation_1 = generation - 1
  )
  if (missing(frame)) return(generation_map)
  frame %>% left_join(generation_map)
}

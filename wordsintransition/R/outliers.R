
#' Label outlier subjects based on catch trial performance.
#'
#' @import dplyr
#' @export
label_outliers <- function(transcription_matches) {
  bad_subj_ids <- transcription_matches %>%
    filter(question_type == "catch_trial", is_correct == 0) %>%
    .$subj_id %>% unique

  mutate(transcription_matches, is_outlier = subj_id %in% bad_subj_ids)
}

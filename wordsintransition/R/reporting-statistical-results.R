#' Present the results of a hierarchical linear model as in a results section.
#' @import dplyr
#' @export
lmer_mod_results <- function(lmer_mod, param) {
  results <- broom::tidy(lmer_mod, effects = "fixed") %>%
    filter(term == param) %>%
    as.list()
  sprintf("_b_ = %.2f (%.2f), _t_ = %.2f", results$estimate, results$std.error, results$statistic)
}

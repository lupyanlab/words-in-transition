#' Present the results of a hierarchical linear model as in a results section.
#' @import dplyr
#' @export
lmer_mod_results <- function(lmer_mod, param) {
  results <- broom::tidy(lmer_mod, effects = "fixed") %>%
    filter(term == param) %>%
    as.list()
  sprintf("_b_ = %.2f (%.2f), _t_ = %.2f", results$estimate, results$std.error, results$statistic)
}


#' Present the results of a hierarchical generalized linear model as in a results section.
#' @import dplyr
#' @export
glmer_mod_results <- function(glmer_mod, param) {
  results <- broom::tidy(glmer_mod, effects = "fixed") %>%
    filter(term == param) %>%
    as.list()
  results["odds"] <- log(results$estimate)
  sprintf("_b_ = %.2f (%.2f) log-odds, odds = %.2f, _z_ = %.2f, _p_ = %.2f",
          results$estimate, results$std.error, results$odds, results$statistic, results$p.value)
}

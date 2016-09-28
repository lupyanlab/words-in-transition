# ---- 1-final-seeds
library(dplyr)
library(pander)
library(wordsintransition)
data("final_seeds")

# The audio only works with html obviously but whatever goes between
# the audio tags will be rendered in pdf/word outputs.
player <- '<audio src="%s" controls>%s</audio>'

final_seeds %>%
  mutate(
    url = paste0('http://sapir.psych.wisc.edu/telephone/seeds/', filename),
    # A markdown link is required in order to render properly in pdf/word.
    link = sprintf('[%s](%s)', filename, url),
    play = sprintf(player, url, link)
  ) %>%
  select(Category = category, Exemplar = play) %>%
  arrange(Category) %>%
  pandoc.table(justify = "left", split.tables = Inf,
               caption = "Environmental sounds used as \"seed messages\" in the experiment.")
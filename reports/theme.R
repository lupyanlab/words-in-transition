# ---- theme
library(ggplot2)

global_theme <- theme_minimal() +
  theme(
    axis.ticks = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

colors <- RColorBrewer::brewer.pal(4, "Set2")
names(colors) <- c("blue", "orange", "green", "pink")
question_type_colors <- unname(colors[c("green", "orange", "blue")])
imitation_gen_colors <- unname(colors[c("green", "blue")])
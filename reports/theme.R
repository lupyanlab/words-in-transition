library(ggplot2)

# ---- global-theme
global_theme <- theme_minimal() +
  theme(
    axis.ticks = element_blank(),
    legend.position = "none"
  )

colors <- RColorBrewer::brewer.pal(4, "Set2")
names(colors) <- c("blue", "orange", "green", "pink")
question_type_colors <- unname(colors[c("green", "orange", "blue")])

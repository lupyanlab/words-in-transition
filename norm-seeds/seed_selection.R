library(dplyr)
library(ggplot2)
options(stringsAsFactors = FALSE)

odd_one_out <- read.csv("survey-1/odd_one_out.csv")

odd_one_out <- filter(odd_one_out,
                      failed_catch_trial == 0,
                      problem_with_audio == 0)

# label the two most frequently selected sounds per category
odd_one_out_counts <- odd_one_out %>%
  count(category, filename) %>%
  arrange(desc(n)) %>%
  mutate(odd_one_out = ifelse(n >= n[2], "odd", "normal"))

ggplot(odd_one_out_counts, aes(x = filename, y = n)) +
  geom_bar(aes(fill = odd_one_out), stat = "identity") +
  facet_wrap("category", scales = "free_x", ncol = 2) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Odd one out (6 per category)")

ggsave("survey-1/odd_one_out.png", height = 10)

odd_sounds <- odd_one_out_counts %>%
  filter(odd_one_out == "odd") %>%
  select(category, filename)

write.csv(odd_sounds, "survey-1/odd_sounds.csv", row.names = FALSE)

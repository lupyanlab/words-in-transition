library(dplyr)
library(ggplot2)
options(stringsAsFactors = FALSE)

count_valid_responses <- function(frame) {
  frame <- filter(frame,
                  failed_catch_trial == 0,
                  problem_with_audio == 0)
  
  counts <- frame %>%
    count(category, filename) %>%
    arrange(desc(n))
}

sound_similarity_6 <- read.csv("survey-1/odd_one_out.csv") %>%
  count_valid_responses

# label the two most frequently selected sounds per category
sound_similarity_6 <- sound_similarity_6 %>%
  group_by(category) %>%
  mutate(odd_one_out = ifelse(n >= n[2], "odd", "normal"))

ggplot(sound_similarity_6, aes(x = filename, y = n)) +
  geom_bar(aes(fill = odd_one_out), stat = "identity") +
  facet_wrap("category", scales = "free_x", ncol = 2) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Odd one out (6 per category)")

ggsave("survey-1/odd_one_out.png", height = 10)

odd_sounds <- odd_one_out_counts %>%
  filter(odd_one_out == "odd") %>%
  select(category, filename)

write.csv(odd_sounds, "survey-1/odd_sounds.csv", row.names = FALSE)

# survey-2

sound_similarity_4 <- read.csv("survey-2/odd_one_out.csv") %>%
  count_valid_responses

ggplot(sound_similarity_4, aes(x = filename, y = n)) +
  geom_bar(stat = "identity") +
  facet_wrap("category", scales = "free_x", ncol = 2) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Odd one out (4 per category)")

ggsave("survey-2/odd_one_out.png", height = 10)

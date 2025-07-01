library(tidyverse)
library(matsim)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)

setwd("C:/Users/Eduardo Lima/Documents/TUB/Studium/Masterarbeit_git/matsim-berlin/src/main/R")

path_run_base <- "../../../../outputs-1pct/output-Base_Case+Bus/berlin-v6.4-1pct"
path_run_siba <- "../../../../outputs-1pct/output-SiBa+Bus/berlin-v6.4-1pct"
path_run_siba_v1 <- "../../../../outputs-1pct/output-SiBa_v1+Bus/berlin-v6.4-1pct"
path_run_siba_v2 <- "../../../../outputs-1pct/output-SiBa_v2+Bus/berlin-v6.4-1pct"

# Function for transfers count
count_transfers <- function(mode_sequence) {
  if (is.na(mode_sequence)) return(NA)
  segments <- unlist(strsplit(mode_sequence, ";"))
  sum(map_int(segments, ~ {
    modes <- unlist(strsplit(.x, "-"))
    max(0, sum(modes == "pt") - 1)
  }))
}

### Base Case ###

persons_base_case <- read_output_persons(paste(path_run_base, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_base_case <- read_output_trips(paste(path_run_base, "/berlin-v6.4.output_trips.csv.gz", sep=""))

# Average income
average_income <- persons_base_case %>% filter(!is.na(income)) %>% summarise(average_income = mean(income))

# Travel time
base_case_trav_time <- trips_base_case %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person), 
    main_mode == "pt") %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    person_trav_time = trav_time + wait_time)

### SiBa ###

persons_siba <- read_output_persons(paste(path_run_siba, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_siba <- read_output_trips(paste(path_run_siba, "/berlin-v6.4.output_trips.csv.gz", sep=""))

siba_persons_joined <- persons_base_case %>% 
  left_join(persons_siba, by=c("person"), suffix=c(".base_case", ".siba")) %>% 
  filter(grepl("^berlin.+", person) | grepl("^dng.+", person) | grepl("^bb.+", person)) %>% # filter out freight drivers
  mutate(score_diff = executed_score.siba - executed_score.base_case)

siba_persons_joined <- siba_persons_joined %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income.base_case) %>% 
  mutate(score_diff_monetarized = score_diff / marginal_utility_of_money)

siba_persons_joined %>% summarise(score_diff_avg = mean(score_diff)) # soll >0 sein

siba_persons_joined %>% summarise(score_diff_avg = mean(score_diff_monetarized)) 

# benefit for cost-benefit analysis (* sample upscale factor 10 or 100)
siba_persons_joined %>% summarise(score_diff_sum = sum(score_diff_monetarized)) 

# * 365: benefit ca. 9,7 Mio. Euro / year
siba_persons_joined %>% summarise(score_diff_sum = sum(score_diff_monetarized)) * 365 * 100

# Verteilungskurven und Mittelwerte Score-Differenz. Hier für alle Agenten, besser zusätzlich noch für die Agenten im Untersuchungsgebiet
siba_persons_joined %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf() +
  labs(title = "Distribution curve of scoring - Siemensbahn",
       x = "Score Difference", y = "Frequency") 

# Outliers (-100 and +200 score_diff): no such outliers with Bus on both Basce Case and SiBa scenarios! None of them used the new pt line.
siba_persons_joined_outliers <- siba_persons_joined %>% 
  filter(score_diff == max(score_diff, na.rm = TRUE) | score_diff == min(score_diff, na.rm = TRUE)) %>% 
  select(person,score_diff) %>% 
  inner_join(bind_rows(
    "Base Case" = trips_base_case,
    "SiBa" = trips_siba,
    .id = "source"), by = "person")
             

siba_persons_joined %>% filter(score_diff < 5 & score_diff > -5) %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf() +
  labs(title = "Distribution curve of scoring - Siemensbahn - from -5 to +5",
       x = "Score Difference", y = "Frequency") 

siba_persons_joined %>% filter(score_diff < 5 & score_diff > -5 & score_diff!=0) %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf() +
  labs(title = "Distribution curve of scoring - Siemensbahn - from -5 to +5, diff. than 0",
       x = "Score Difference", y = "Frequency") 

# Gewinne und Verluste scheinbar ähnlich verteilt (viele haben kleine Änderung, wenige haben größere Änderung)
boxplot(siba_persons_joined$score_diff, na.rm = TRUE)

# Travel time Difference SiBa vs Base Case: for pt users remaining and for new pt users 
siba_trav_time <- trips_siba %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person), 
    main_mode == "pt") %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    person_trav_time = trav_time + wait_time)

siba_trav_time_diff <- base_case_trav_time %>% 
  right_join(siba_trav_time, by=c("person"), suffix=c(".base_case", ".siba")) %>% 
  select(person,person_trav_time.base_case,person_trav_time.siba) %>% 
  mutate(trav_time_diff = person_trav_time.siba - person_trav_time.base_case)

siba_trav_time_diff %>% summarise(total_trav_time_diff = sum(trav_time_diff, na.rm = TRUE)) 

boxplot(siba_trav_time_diff$trav_time_diff, na.rm = TRUE)

# Transfers Difference SiBa vs Base Case: for pt users remaining
siba_transfer_diff <- base_case_trav_time %>% 
  left_join(siba_trav_time, by=c("person"), suffix=c(".base_case", ".siba")) %>% 
  select(person,modes.base_case,modes.siba) %>%
  filter(!is.na(modes.siba)) %>% 
  mutate(
    num_transfers.base_case = map_int(modes.base_case, count_transfers),
    num_transfers.siba = map_int(modes.siba, count_transfers)
  ) %>% 
  mutate(transfer_diff = num_transfers.siba - num_transfers.base_case)

siba_transfer_diff %>% summarise(total_transfer_diff = sum(transfer_diff, na.rm = TRUE)) 

### SiBa_v1 ###

persons_siba_v1 <- read_output_persons(paste(path_run_siba_v1, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_siba_v1 <- read_output_trips(paste(path_run_siba_v1, "/berlin-v6.4.output_trips.csv.gz", sep=""))

siba_v1_persons_joined <- persons_base_case %>% 
  left_join(persons_siba_v1, by=c("person"), suffix=c(".base_case", ".siba_v1")) %>% 
  filter(grepl("^berlin.+", person) | grepl("^dng.+", person) | grepl("^bb.+", person)) %>% # filter out freight drivers
  mutate(score_diff = executed_score.siba_v1 - executed_score.base_case)

siba_v1_persons_joined <- siba_v1_persons_joined %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income.base_case) %>% 
  mutate(score_diff_monetarized = score_diff / marginal_utility_of_money)

siba_v1_persons_joined %>% summarise(score_diff_avg = mean(score_diff)) # soll >0 sein

siba_v1_persons_joined %>% summarise(score_diff_avg = mean(score_diff_monetarized)) 

# benefit for cost-benefit analysis (* sample upscale factor 10 or 100)
siba_v1_persons_joined %>% summarise(score_diff_sum = sum(score_diff_monetarized)) 

# * 365: benefit ca. 35,1 Mio. Euro / year
siba_v1_persons_joined %>% summarise(score_diff_sum = sum(score_diff_monetarized)) * 365 * 100

# Verteilungskurven und Mittelwerte Score-Differenz. Hier für alle Agenten, besser zusätzlich noch für die Agenten im Untersuchungsgebiet
siba_v1_persons_joined %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf() +
  labs(title = "Distribution curve of scoring - Siemensbahn (Extension 1)",
       x = "Score Difference", y = "Frequency") 

# Outliers check: no considerable outliers! The most negative value is the same as from the SiBa scenario. 
siba_v1_persons_joined_outliers <- siba_v1_persons_joined %>% 
  filter(score_diff == max(score_diff, na.rm = TRUE) | score_diff == min(score_diff, na.rm = TRUE)) %>% 
  select(person,score_diff) %>% 
  inner_join(bind_rows(
    "Base Case" = trips_base_case,
    "SiBa_v1" = trips_siba_v1,
    .id = "source"), by = "person")

siba_v1_persons_joined %>% filter(score_diff < 5 & score_diff > -5) %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf() +
  labs(title = "Distribution curve of scoring - Siemensbahn (Extension 1) - from -5 to +5",
       x = "Score Difference", y = "Frequency") 

siba_v1_persons_joined %>% filter(score_diff < 5 & score_diff > -5 & score_diff!=0) %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf() +
  labs(title = "Distribution curve of scoring - Siemensbahn (Extension 1) - from -5 to +5, diff. than 0",
       x = "Score Difference", y = "Frequency") 

# Gewinne und Verluste scheinbar ähnlich verteilt (viele haben kleine Änderung, wenige haben größere Änderung)
boxplot(siba_v1_persons_joined$score_diff, na.rm = TRUE)

# Travel time Difference SiBa_v1 vs Base Case: for pt users remaining and for new pt users 
siba_v1_trav_time <- trips_siba_v1 %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person), 
    main_mode == "pt") %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    person_trav_time = trav_time + wait_time)

siba_v1_trav_time_diff <- base_case_trav_time %>% 
  right_join(siba_v1_trav_time, by=c("person"), suffix=c(".base_case", ".siba_v1")) %>% 
  select(person,person_trav_time.base_case,person_trav_time.siba_v1) %>% 
  mutate(trav_time_diff = person_trav_time.siba_v1 - person_trav_time.base_case)

siba_v1_trav_time_diff %>% summarise(total_trav_time_diff = sum(trav_time_diff, na.rm = TRUE)) 

# Transfers Difference SiBa_v1 vs Base Case: for pt users remaining
siba_v1_transfer_diff <- base_case_trav_time %>% 
  left_join(siba_v1_trav_time, by=c("person"), suffix=c(".base_case", ".siba_v1")) %>% 
  select(person,modes.base_case,modes.siba_v1) %>%
  filter(!is.na(modes.siba_v1)) %>% 
  mutate(
    num_transfers.base_case = map_int(modes.base_case, count_transfers),
    num_transfers.siba_v1 = map_int(modes.siba_v1, count_transfers)
  ) %>% 
  mutate(transfer_diff = num_transfers.siba_v1 - num_transfers.base_case)

siba_v1_transfer_diff %>% summarise(total_transfer_diff = sum(transfer_diff, na.rm = TRUE)) 

### SiBa_v2 ###

persons_siba_v2 <- read_output_persons(paste(path_run_siba_v2, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_siba_v2 <- read_output_trips(paste(path_run_siba_v2, "/berlin-v6.4.output_trips.csv.gz", sep=""))

siba_v2_persons_joined <- persons_base_case %>% 
  left_join(persons_siba_v2, by=c("person"), suffix=c(".base_case", ".siba_v2")) %>% 
  filter(grepl("^berlin.+", person) | grepl("^dng.+", person) | grepl("^bb.+", person)) %>% # filter out freight drivers
  mutate(score_diff = executed_score.siba_v2 - executed_score.base_case)

siba_v2_persons_joined <- siba_v2_persons_joined %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income.base_case) %>% 
  mutate(score_diff_monetarized = score_diff / marginal_utility_of_money)

siba_v2_persons_joined %>% summarise(score_diff_avg = mean(score_diff)) # soll >0 sein

siba_v2_persons_joined %>% summarise(score_diff_avg = mean(score_diff_monetarized)) 

# benefit for cost-benefit analysis (* sample upscale factor 10 or 100)
siba_v2_persons_joined %>% summarise(score_diff_sum = sum(score_diff_monetarized)) 

# * 365: benefit ca. 19,5 Mio. Euro / year
siba_v2_persons_joined %>% summarise(score_diff_sum = sum(score_diff_monetarized)) * 365 * 100

# Verteilungskurven und Mittelwerte Score-Differenz. Hier für alle Agenten, besser zusätzlich noch für die Agenten im Untersuchungsgebiet
siba_v2_persons_joined %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf() +
  labs(title = "Distribution curve of scoring - Siemensbahn (Extension 2)",
       x = "Score Difference", y = "Frequency") 

# Outliers check: no considerable outliers! Why the table is empty, if the max and min do exist?
siba_v2_persons_joined_outliers <- siba_v2_persons_joined %>% 
  filter(score_diff == max(score_diff, na.rm = TRUE) | score_diff == min(score_diff, na.rm = TRUE)) %>% 
  select(person,score_diff) %>% 
  inner_join(bind_rows(
    "Base Case" = trips_base_case,
    "SiBa_v2" = trips_siba_v2,
    .id = "source"), by = "person")

#siba_v2_persons_joined_outliers <- trips_base_case %>% filter(person == "bb_1b126ce9" | person == "bb_e6258d55")

siba_v2_persons_joined %>% filter(score_diff < 5 & score_diff > -5) %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf() +
  labs(title = "Distribution curve of scoring - Siemensbahn (Extension 2) - from -5 to +5",
       x = "Score Difference", y = "Frequency") 

siba_v2_persons_joined %>% filter(score_diff < 5 & score_diff > -5 & score_diff!=0) %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf() +
  labs(title = "Distribution curve of scoring - Siemensbahn (Extension 2) - from -5 to +5, diff. than 0",
       x = "Score Difference", y = "Frequency") 

# Gewinne und Verluste scheinbar ähnlich verteilt (viele haben kleine Änderung, wenige haben größere Änderung)
boxplot(siba_v2_persons_joined$score_diff, na.rm = TRUE)

# Travel time Difference SiBa_v2 vs Base Case: for pt users remaining and for new pt users 
siba_v2_trav_time <- trips_siba_v2 %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person), 
    main_mode == "pt") %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    person_trav_time = trav_time + wait_time)

siba_v2_trav_time_diff <- base_case_trav_time %>% 
  right_join(siba_v2_trav_time, by=c("person"), suffix=c(".base_case", ".siba_v2")) %>% 
  select(person,person_trav_time.base_case,person_trav_time.siba_v2) %>% 
  mutate(trav_time_diff = person_trav_time.siba_v2 - person_trav_time.base_case)

siba_v2_trav_time_diff %>% summarise(total_trav_time_diff = sum(trav_time_diff, na.rm = TRUE)) 

# Transfers Difference SiBa_v2 vs Base Case: for pt users remaining
siba_v2_transfer_diff <- base_case_trav_time %>% 
  left_join(siba_v2_trav_time, by=c("person"), suffix=c(".base_case", ".siba_v2")) %>% 
  select(person,modes.base_case,modes.siba_v2) %>%
  filter(!is.na(modes.siba_v2)) %>% 
  mutate(
    num_transfers.base_case = map_int(modes.base_case, count_transfers),
    num_transfers.siba_v2 = map_int(modes.siba_v2, count_transfers)
  ) %>% 
  mutate(transfer_diff = num_transfers.siba_v2 - num_transfers.base_case)

siba_v2_transfer_diff %>% summarise(total_transfer_diff = sum(transfer_diff, na.rm = TRUE))
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


persons_base_case <- read_output_persons(paste(path_run_base, "/berlin-v6.4.output_persons.csv.gz", sep=""))
persons_policy_case <- read_output_persons(paste(path_run_siba, "/berlin-v6.4.output_persons.csv.gz", sep=""))

persons_joined <- persons_base_case %>% 
  left_join(persons_policy_case, by=c("person"), suffix=c(".base", ".policy")) %>% 
  filter(grepl("^berlin.+", person) | grepl("^dng.+", person) | grepl("^bb.+", person)) %>% # filter out freight drivers
  mutate(score_diff = executed_score.policy - executed_score.base)

average_income <- persons_joined %>% filter(!is.na(income.base)) %>% summarise(average_income = mean(income.base))

persons_joined <- persons_joined %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income.base) %>% 
  mutate(score_diff_monetarized = score_diff / marginal_utility_of_money)

persons_joined %>% summarise(score_diff_avg = mean(score_diff)) # soll >0 sein

persons_joined %>% summarise(score_diff_avg = mean(score_diff_monetarized)) 

# benefit for cost-benefit analysis (* sample upscale factor 10 or 100)
persons_joined %>% summarise(score_diff_sum = sum(score_diff_monetarized)) 

# * 365: benefit ca. 34 Mio. Euro / year --> Working days?
persons_joined %>% summarise(score_diff_sum = sum(score_diff_monetarized)) * 365 * 100

# Verteilungskurven und Mittelwerte Score-Differenz. Hier für alle Agenten, besser zusätzlich noch für die Agenten im Untersuchungsgebiet

persons_joined %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf()

# TODO: explain outliers (-100 and +200 score_diff)

persons_joined %>% filter(score_diff < 5 & score_diff > -5) %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf()

persons_joined %>% filter(score_diff < 5 & score_diff > -5 & score_diff!=0) %>% 
  ggplot(aes(x=score_diff)) + stat_ecdf()

# Gewinne und Verluste scheinbar ähnlich verteilt (viele haben kleine Änderung, wenige haben größere Änderung)

boxplot(persons_joined$score_diff, na.rm = TRUE)

# TODO: wait+travel time diff policy case vs base case: for pt users remaining and for new pt users. 

# Trips (Base Case + Bus)
base_case_trips <- read_output_trips(paste(path_run_base, "/berlin-v6.4.output_trips.csv.gz", sep=""))

base_case_trav_time <- base_case_trips %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person), 
    main_mode == "pt") %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    total_trav_time = trav_time + wait_time)

# Trips (SiBa + Bus)
siba_trips <- read_output_trips(paste(path_run_siba, "/berlin-v6.4.output_trips.csv.gz", sep=""))

siba_trav_time <- siba_trips %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person), 
    main_mode == "pt") %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    total_trav_time = trav_time + wait_time)

trips_joined <- base_case_trav_time %>% 
  full_join(siba_trav_time, by=c("person"), suffix=c(".base_case", ".siba")) %>% 
  select(person,modes.base_case,total_trav_time.base_case,modes.siba,total_trav_time.siba) %>% 
  mutate(trav_time_diff = total_trav_time.siba - total_trav_time.base_case)

boxplot(trips_joined$trav_time_diff, na.rm = TRUE)

# TODO: number of transfers policy case vs base case: for pt users remaining

count_transfers <- function(mode_sequence) {
  if (is.na(mode_sequence)) return(NA)
  segments <- unlist(strsplit(mode_sequence, ";"))
  sum(map_int(segments, ~ {
    modes <- unlist(strsplit(.x, "-"))
    max(0, sum(modes == "pt") - 1)
  }))
}

transfer_counts <- trips_joined %>%
  mutate(
    num_transfers.base_case = map_int(modes.base_case, count_transfers),
    num_transfers.siba = map_int(modes.siba, count_transfers)
  ) %>% 
  mutate(transfer_diff = num_transfers.siba - num_transfers.base_case)
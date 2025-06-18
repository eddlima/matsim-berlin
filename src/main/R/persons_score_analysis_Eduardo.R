library(tidyverse)
library(matsim)

path_run_base <- "/Users/gleich/Volumes/math-cluster/lima/output-Base_Case/berlin-v6.4-1pct"
path_run_policy <- "/Users/gleich/Volumes/math-cluster/lima/output-SiBa+Bus/berlin-v6.4-1pct"


persons_base_case <- read_output_persons(paste(path_run_base, "/berlin-v6.4.output_persons.csv.gz", sep=""))
persons_policy_case <- read_output_persons(paste(path_run_policy, "/berlin-v6.4.output_persons.csv.gz", sep=""))

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

# * 365: benefit ca. 34 Mio. Euro / year
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
# TODO: number of transfers policy case vs base case: for pt users remaining

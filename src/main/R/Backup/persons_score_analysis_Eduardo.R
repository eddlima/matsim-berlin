library(tidyverse)
library(matsim)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(tibble)
library(writexl)
library(sf)
library(tmap)

setwd("C:/Users/Eduardo Lima/Documents/TUB/Studium/Masterarbeit_git/matsim-berlin/src/main/R")

path_run_base_a <- "../../../../outputs-10pct/output-Base_Case-10pct"
path_run_siba_a <- "../../../../outputs-10pct/output-SiBa-10pct"
# path_run_siba_v1_a <- "../../../../outputs-10pct/output-SiBa_v1-10pct"
# path_run_siba_v2_a <- "../../../../outputs-10pct/output-SiBa_v2-10pct"

# Function for transfers count
count_transfers <- function(mode_sequence) {
  if (is.na(mode_sequence)) return(NA)
  segments <- unlist(strsplit(mode_sequence, ";"))
  sum(map_int(segments, ~ {
    modes <- unlist(strsplit(.x, "-"))
    max(0, sum(modes == "pt") - 1)
  }))
}

# Neighborhoods
ortsteile_shp <- st_read("lor_ortsteile.shp//lor_ortsteile.shp") %>% 
  st_transform(25832)

neighborhoods_siba_shp <- ortsteile_shp %>% 
  filter(OTEIL %in% c("Siemensstadt", "Haselhorst", "Hakenfelde", "Charlottenburg-Nord"))

tmap_mode("view")
tm_shape(neighborhoods_siba_shp) + 
  tm_polygons()

### Base Case ###

persons_base_case_a <- read_output_persons(paste(path_run_base_a, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_base_case_a <- read_output_trips(paste(path_run_base_a, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_base_case_a <- "../../../../outputs-10pct/output-Base_Case-10pct/berlin-v6.4.output_legs.csv.gz"
legs_base_case_a <- read_delim(gzfile(output_legs_base_case_a))

# Average income
average_income <- persons_base_case_a %>% filter(!is.na(income)) %>% summarise(average_income = mean(income))

# Monetized score
base_case_a_score_monetized <- persons_base_case_a %>%
  filter(grepl("^(berlin|dng|bb).+", person)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

base_case_a_total_score_monetized <- base_case_a_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Filtering out the agents that start or end a leg on the main neighborhoods affected by the Siemensbahn
legs_base_case_a_sf <- legs_base_case_a  %>%
  filter(!is.na(start_x) & !is.na(start_y) & !is.na(end_x) & !is.na(end_y)) 

legs_base_case_a_start_sf <- legs_base_case_a_sf %>%
  st_as_sf(coords = c("start_x","start_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

legs_base_case_a_end_sf <- legs_base_case_a_sf %>%
  st_as_sf(coords = c("end_x","end_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

persons_base_case_a_affected_by_siba <- unique(legs_base_case_a_start_sf$person,legs_base_case_a_end_sf$person)

# Monetized score for agents affected by SiBa
base_case_a_score_monetized_affected_by_siba <- persons_base_case_a %>%
  filter(person %in% persons_base_case_a_affected_by_siba) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

base_case_a_total_score_monetized_affected_by_siba <- base_case_a_score_monetized_affected_by_siba %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Travel time
base_case_a_trav_time <- trips_base_case_a %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person), 
    main_mode == "pt") %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    person_trav_time = trav_time + wait_time)

base_case_a_total_trav_time <- base_case_a_trav_time %>% 
  summarise(total_trav_time = sum(person_trav_time)) / 3600 

# Transfers
base_case_a_transfers <- base_case_a_trav_time %>%
  select(person,modes) %>%
  filter(!is.na(modes)) %>%
  mutate(num_transfers = map_int(modes, count_transfers))

base_case_a_total_transfers <- base_case_a_transfers %>% 
  summarise(total_transfers = sum(num_transfers, na.rm = TRUE))

# Car-km
base_case_a_car_km <- legs_base_case_a %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person),
    mode == "car") %>% 
  group_by(person) %>%
  summarise(person_car_km = sum(distance) / 1000)

base_case_a_total_car_km <- base_case_a_car_km %>% 
  summarise(total_car_km = sum(person_car_km))

# Results
base_case_a_results <- data.frame(
  Scenario = "Base Case",
  'Total Monetized Score [EUR/day]' = as.numeric(base_case_a_total_score_monetized),
  'Total Monetized Score Delimited Region [EUR/day]' = as.numeric(base_case_a_total_score_monetized_affected_by_siba),
  'Total Travel Time for PT-Users [h/day]' = as.numeric(base_case_a_total_trav_time),
  'Total Transfers [1/day]' =  as.numeric(base_case_a_total_transfers),
  'Total Car-km [km/day]' = as.numeric(base_case_a_total_car_km),
  check.names = FALSE)

### Siemensbahn ###

persons_siba_a <- read_output_persons(paste(path_run_siba_a, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_siba_a <- read_output_trips(paste(path_run_siba_a, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_siba_a <- "../../../../outputs-10pct/output-SiBa-10pct/berlin-v6.4.output_legs.csv.gz"
legs_siba_a <- read_delim(gzfile(output_legs_siba_a))

# Monetized score
siba_a_score_monetized <- persons_siba_a %>%
  filter(grepl("^(berlin|dng|bb).+", person)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_a_total_score_monetized <- siba_a_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Filtering out the agents that start or end a leg on the main neighborhoods affected by the Siemensbahn
legs_siba_a_sf <- legs_siba_a  %>%
  filter(!is.na(start_x) & !is.na(start_y) & !is.na(end_x) & !is.na(end_y)) 

legs_siba_a_start_sf <- legs_siba_a_sf %>%
  st_as_sf(coords = c("start_x","start_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

legs_siba_a_end_sf <- legs_siba_a_sf %>%
  st_as_sf(coords = c("end_x","end_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

persons_siba_a_affected_by_siba <- unique(legs_siba_a_start_sf$person,legs_siba_a_end_sf$person)

# Monetized score for agents affected by SiBa
siba_a_score_monetized_affected_by_siba <- persons_siba_a %>%
  filter(person %in% persons_siba_a_affected_by_siba) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_a_total_score_monetized_affected_by_siba <- siba_a_score_monetized_affected_by_siba %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Travel time 
siba_a_trav_time <- trips_siba_a %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person), 
    main_mode == "pt") %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    person_trav_time = trav_time + wait_time)

siba_a_total_trav_time <- siba_a_trav_time %>% 
  summarise(total_trav_time = sum(person_trav_time)) / 3600 

# Transfers
siba_a_transfers <- siba_a_trav_time %>%
  select(person,modes) %>%
  filter(!is.na(modes)) %>%
  mutate(num_transfers = map_int(modes, count_transfers))

siba_a_total_transfers <- siba_a_transfers %>% 
  summarise(total_transfers = sum(num_transfers, na.rm = TRUE))

# Car-km
siba_a_car_km <- legs_siba_a %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person),
    mode == "car") %>% 
  group_by(person) %>%
  summarise(person_car_km = sum(distance) / 1000)

siba_a_total_car_km <- siba_a_car_km %>% 
  summarise(total_car_km = sum(person_car_km))

# Results
siba_a_results <- data.frame(
  Scenario = "Siemensbahn",
  'Total Monetized Score [EUR/day]' = as.numeric(siba_a_total_score_monetized),
  'Total Monetized Score Delimited Region [EUR/day]' = as.numeric(siba_a_total_score_monetized_affected_by_siba),
  'Total Travel Time for PT-Users [h/day]' = as.numeric(siba_a_total_trav_time),
  'Total Transfers [1/day]' =  as.numeric(siba_a_total_transfers),
  'Total Car-km [km/day]' = as.numeric(siba_a_total_car_km),
  check.names = FALSE)

# ### Siemensbahn_v1 ###
# 
# persons_siba_v1_a <- read_output_persons(paste(path_run_siba_v1_a, "/berlin-v6.4.output_persons.csv.gz", sep=""))
# trips_siba_v1_a <- read_output_trips(paste(path_run_siba_v1_a, "/berlin-v6.4.output_trips.csv.gz", sep=""))
# output_legs_siba_v1_a <- "../../../../outputs-10pct/output-SiBa_v1-10pct/berlin-v6.4.output_legs.csv.gz"
# legs_siba_v1_a <- read_delim(gzfile(output_legs_siba_v1_a))
# 
# # Monetized score
# siba_v1_a_score_monetized <- persons_siba_v1_a %>%
#   filter(grepl("^(berlin|dng|bb).+", person)) %>% 
#   mutate(marginal_utility_of_money = average_income$average_income / income) %>%
#   mutate(score_monetized = executed_score / marginal_utility_of_money)
# 
# siba_v1_a_total_score_monetized <- siba_v1_a_score_monetized %>% 
#   summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)
# 
# # Travel time 
# siba_v1_a_trav_time <- trips_siba_v1_a %>% 
#   filter(
#     grepl("^(berlin|dng|bb).+", person), 
#     main_mode == "pt") %>% 
#   group_by(person) %>%
#   summarise(
#     trav_time = sum(trav_time, na.rm = TRUE),
#     wait_time = sum(wait_time, na.rm = TRUE),
#     modes = paste(modes, collapse = ";"),
#     person_trav_time = trav_time + wait_time)
# 
# siba_v1_a_total_trav_time <- siba_v1_a_trav_time %>% 
#   summarise(total_trav_time = sum(person_trav_time)) / 3600 
# 
# # Transfers
# siba_v1_a_transfers <- siba_v1_a_trav_time %>%
#   select(person,modes) %>%
#   filter(!is.na(modes)) %>%
#   mutate(num_transfers = map_int(modes, count_transfers))
# 
# siba_v1_a_total_transfers <- siba_v1_a_transfers %>% 
#   summarise(total_transfers = sum(num_transfers, na.rm = TRUE))
# 
# # Car-km
# siba_v1_a_car_km <- legs_siba_v1_a %>% 
#   filter(
#     grepl("^(berlin|dng|bb).+", person),
#     mode == "car") %>% 
#   group_by(person) %>%
#   summarise(person_car_km = sum(distance) / 1000)
# 
# siba_v1_a_total_car_km <- siba_v1_a_car_km %>% 
#   summarise(total_car_km = sum(person_car_km))
# 
# # Results
# siba_v1_a_results <- data.frame(
#   Scenario = "SiBa_v1",
#   'Total Monetized Score [EUR/day]' = as.numeric(siba_v1_a_total_score_monetized), 
#   'Total Travel Time for PT-Users [h/day]' = as.numeric(siba_v1_a_total_trav_time),
#   'Total Transfers [1/day]' =  as.numeric(siba_v1_a_total_transfers),
#   'Total Car-km [km/day]' = as.numeric(siba_v1_a_total_car_km),
#   check.names = FALSE)

# ### Siemensbahn_v2 ###
# 
# persons_siba_v2_a <- read_output_persons(paste(path_run_siba_v2_a, "/berlin-v6.4.output_persons.csv.gz", sep=""))
# trips_siba_v2_a <- read_output_trips(paste(path_run_siba_v2_a, "/berlin-v6.4.output_trips.csv.gz", sep=""))
# output_legs_siba_v2_a <- "../../../../outputs-10pct/output-SiBa_v2-10pct/berlin-v6.4.output_legs.csv.gz"
# legs_siba_v2_a <- read_delim(gzfile(output_legs_siba_v2_a))
# 
# # Monetized score
# siba_v2_a_score_monetized <- persons_siba_v2_a %>%
#   filter(grepl("^(berlin|dng|bb).+", person)) %>% 
#   mutate(marginal_utility_of_money = average_income$average_income / income) %>%
#   mutate(score_monetized = executed_score / marginal_utility_of_money)
# 
# siba_v2_a_total_score_monetized <- siba_v2_a_score_monetized %>% 
#   summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)
# 
# # Travel time 
# siba_v2_a_trav_time <- trips_siba_v2_a %>% 
#   filter(
#     grepl("^(berlin|dng|bb).+", person), 
#     main_mode == "pt") %>% 
#   group_by(person) %>%
#   summarise(
#     trav_time = sum(trav_time, na.rm = TRUE),
#     wait_time = sum(wait_time, na.rm = TRUE),
#     modes = paste(modes, collapse = ";"),
#     person_trav_time = trav_time + wait_time)
# 
# siba_v2_a_total_trav_time <- siba_v2_a_trav_time %>% 
#   summarise(total_trav_time = sum(person_trav_time)) / 3600  
# 
# # Transfers
# siba_v2_a_transfers <- siba_v2_a_trav_time %>%
#   select(person,modes) %>%
#   filter(!is.na(modes)) %>%
#   mutate(num_transfers = map_int(modes, count_transfers))
# 
# siba_v2_a_total_transfers <- siba_v2_a_transfers %>% 
#   summarise(total_transfers = sum(num_transfers, na.rm = TRUE))
# 
# # Car-km
# siba_v2_a_car_km <- legs_siba_v2_a %>% 
#   filter(
#     grepl("^(berlin|dng|bb).+", person),
#     mode == "car") %>% 
#   group_by(person) %>%
#   summarise(person_car_km = sum(distance) / 1000)
# 
# siba_v2_a_total_car_km <- siba_v2_a_car_km %>% 
#   summarise(total_car_km = sum(person_car_km))
# 
# # Results
# siba_v2_a_results <- data.frame(
#   Scenario = "SiBa_v2",
#   'Total Monetized Score [EUR/day]' = as.numeric(siba_v2_a_total_score_monetized), 
#   'Total Travel Time for PT-Users [h/day]' = as.numeric(siba_v2_a_total_trav_time),
#   'Total Transfers [1/day]' =  as.numeric(siba_v2_a_total_transfers),
#   'Total Car-km [km/day]' = as.numeric(siba_v2_a_total_car_km),
#   check.names = FALSE)

### Total Results ###

results <- bind_rows(
  base_case_a_results, 
  siba_a_results,
  # siba_v1_a_results,
  # siba_v2_a_results
)

write_xlsx(results, "results-person_score_analysis_Eduardo.xlsx")

### Comparison ###

# Agents switching to pt, [Siemensbahn] vs [Base Case]
base_case_a_car_users <- unique(base_case_a_car_km$person)

siba_a_former_car_users <- trips_siba_a %>% 
  filter(person %in% base_case_a_car_users) %>% 
  filter(main_mode == "pt")

siba_a_new_pt_users <- unique(siba_a_former_car_users$person)

base_case_a_car_km_new_pt_users <- base_case_a_car_km %>% 
  filter(person %in% siba_a_new_pt_users)

base_case_a_siba_a_total_car_km_new_pt_users <- base_case_a_car_km_new_pt_users %>% 
  summarise(total_car_km_new_pt_users = sum(person_car_km))

siba_a_former_car_users_trav_time_pt <- siba_a_former_car_users %>%
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    person_trav_time = trav_time + wait_time)
  
siba_a_former_car_users_total_trav_time_pt <- siba_a_former_car_users_trav_time_pt %>% 
  summarise(total_trav_time = sum(person_trav_time)) / 3600 # (results may show [secs], but it's [hours]!!)

# Agents remaining in pt, [Siemensbahn] vs [Base Case]
base_case_a_pt_users <- unique(base_case_a_trav_time$person)

siba_a_former_pt_users <- trips_siba_a %>% 
  filter(person %in% base_case_a_pt_users) %>% 
  filter(main_mode == "pt")

siba_a_former_pt_users_trav_time_pt <- siba_a_former_pt_users %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    person_trav_time = trav_time + wait_time)

siba_a_former_pt_users_total_trav_time_pt <- siba_a_former_pt_users_trav_time_pt %>% 
  summarise(total_trav_time = sum(person_trav_time)) / 3600 # (results may show [secs], but it's [hours]!!)

# Agents switching to SiBa, [Siemensbahn] vs [Base Case]
base_case_a_car_users <- unique(base_case_a_car_km$person)

siba_a_former_car_users <- legs_siba_a %>% 
  filter(person %in% base_case_a_car_users) %>% 
  filter(grepl("^SiBa", transit_line, ignore.case = TRUE))

siba_a_new_siba_users <- unique(siba_a_former_car_users$person)

base_case_a_car_km_new_siba_users <- base_case_a_car_km %>% 
  filter(person %in% siba_a_new_siba_users)

base_case_a_siba_a_total_car_km_new_siba_users <- base_case_a_car_km_new_siba_users %>% 
  summarise(total_car_km_new_siba_users = sum(person_car_km))

# Travel time Difference [Siemensbahn] vs [Base Case]: for pt users remaining and for new pt users
siba_a_base_case_a_trav_time_diff <- base_case_a_trav_time %>% 
  left_join(siba_a_trav_time, by=c("person"), suffix=c(".base_case_a", ".siba_a")) %>% 
  select(person,person_trav_time.base_case_a,person_trav_time.siba_a)

siba_a_base_case_a_trav_time_diff %>% summarise(person_total_trav_time_base_case_a = sum(person_trav_time.base_case_a, na.rm = TRUE),
                                                person_total_trav_time_siba_a = sum(person_trav_time.siba_a, na.rm = TRUE))
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

path_run_base <- "../../../../outputs-10pct/output-Base_Case-10pct"
path_run_siba <- "../../../../outputs-10pct/output-SiBa-10pct"
path_run_siba_v1 <- "../../../../outputs-10pct/output-SiBa_v1-10pct"
path_run_siba_v2 <- "../../../../outputs-10pct/output-SiBa_v2-10pct"

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

persons_base_case <- read_output_persons(paste(path_run_base, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_base_case <- read_output_trips(paste(path_run_base, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_base_case <- "../../../../outputs-10pct/output-Base_Case-10pct/berlin-v6.4.output_legs.csv.gz"
legs_base_case <- read_delim(gzfile(output_legs_base_case))

# Average income
average_income <- persons_base_case %>% filter(!is.na(income)) %>% summarise(average_income = mean(income))

# Monetized score
base_case_score_monetized <- persons_base_case %>%
  filter(grepl("^(berlin|dng|bb).+", person)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

base_case_total_score_monetized <- base_case_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Filtering out the agents that start or end a trip on the main neighborhoods affected by the Siemensbahn
trips_base_case_sf <- trips_base_case  %>%
  filter(!is.na(start_x) & !is.na(start_y) & !is.na(end_x) & !is.na(end_y)) 

trips_base_case_start_sf <- trips_base_case_sf %>%
  st_as_sf(coords = c("start_x","start_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

trips_base_case_end_sf <- trips_base_case_sf %>%
  st_as_sf(coords = c("end_x","end_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

persons_base_case_affected_by_siba <- unique(trips_base_case_start_sf$person,trips_base_case_end_sf$person)

# Monetized score for agents affected by SiBa
base_case_score_monetized_affected_by_siba <- persons_base_case %>%
  filter(person %in% persons_base_case_affected_by_siba) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

base_case_total_score_monetized_affected_by_siba <- base_case_score_monetized_affected_by_siba %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

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

base_case_total_trav_time <- base_case_trav_time %>% 
  summarise(total_trav_time = sum(person_trav_time)) / 3600

# Car trips
base_case_car_trips <- trips_base_case %>%
  filter(
    grepl("^(berlin|dng|bb).+", person),
    main_mode == "car")

# PT trips
base_case_pt_trips <- trips_base_case %>%
  filter(
    grepl("^(berlin|dng|bb).+", person),
    main_mode == "pt")

# Transfers
base_case_transfers <- base_case_trav_time %>%
  select(person,modes) %>%
  filter(!is.na(modes)) %>%
  mutate(num_transfers = map_int(modes, count_transfers))

base_case_total_transfers <- base_case_transfers %>% 
  summarise(total_transfers = sum(num_transfers, na.rm = TRUE))

# Car-km
base_case_car_km <- trips_base_case %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person),
    main_mode == "car") %>% 
  group_by(person) %>%
  summarise(person_car_km = sum(traveled_distance) / 1000)

base_case_total_car_km <- base_case_car_km %>% 
  summarise(total_car_km = sum(person_car_km))

# Results
base_case_results <- data.frame(
  Scenario = "Base Case",
  'Total Monetized Score [EUR/day]' = as.numeric(base_case_total_score_monetized),
  'Total Monetized Score Delimited Region [EUR/day]' = as.numeric(base_case_total_score_monetized_affected_by_siba),
  'Total Travel Time for PT-Users [h/day]' = as.numeric(base_case_total_trav_time),
  'Total Transfers [1/day]' =  as.numeric(base_case_total_transfers),
  'Total Car-km [km/day]' = as.numeric(base_case_total_car_km),
  check.names = FALSE)

### Siemensbahn ###

persons_siba <- read_output_persons(paste(path_run_siba, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_siba <- read_output_trips(paste(path_run_siba, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_siba <- "../../../../outputs-10pct/output-SiBa-10pct/berlin-v6.4.output_legs.csv.gz"
legs_siba <- read_delim(gzfile(output_legs_siba))

# Monetized score
siba_score_monetized <- persons_siba %>%
  filter(grepl("^(berlin|dng|bb).+", person)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_total_score_monetized <- siba_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Filtering out the agents that start or end a trip on the main neighborhoods affected by the Siemensbahn
trips_siba_sf <- trips_siba  %>%
  filter(!is.na(start_x) & !is.na(start_y) & !is.na(end_x) & !is.na(end_y)) 

trips_siba_start_sf <- trips_siba_sf %>%
  st_as_sf(coords = c("start_x","start_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

trips_siba_end_sf <- trips_siba_sf %>%
  st_as_sf(coords = c("end_x","end_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

persons_siba_affected_by_siba <- unique(trips_siba_start_sf$person,trips_siba_end_sf$person)

# Monetized score for agents affected by SiBa
siba_score_monetized_affected_by_siba <- persons_siba %>%
  filter(person %in% persons_siba_affected_by_siba) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_total_score_monetized_affected_by_siba <- siba_score_monetized_affected_by_siba %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Travel time 
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

siba_total_trav_time <- siba_trav_time %>% 
  summarise(total_trav_time = sum(person_trav_time)) / 3600 

# PT trips
siba_pt_trips <- trips_siba %>%
  filter(
    grepl("^(berlin|dng|bb).+", person),
    main_mode == "pt")

# Transfers
siba_transfers <- siba_trav_time %>%
  select(person,modes) %>%
  filter(!is.na(modes)) %>%
  mutate(num_transfers = map_int(modes, count_transfers))

siba_total_transfers <- siba_transfers %>% 
  summarise(total_transfers = sum(num_transfers, na.rm = TRUE))

# Car-km
siba_car_km <- trips_siba %>% 
  filter(
    grepl("^(berlin|dng|bb).+", person),
    main_mode == "car") %>% 
  group_by(person) %>%
  summarise(person_car_km = sum(traveled_distance) / 1000)

siba_total_car_km <- siba_car_km %>% 
  summarise(total_car_km = sum(person_car_km))

# Results
siba_results <- data.frame(
  Scenario = "Siemensbahn",
  'Total Monetized Score [EUR/day]' = as.numeric(siba_total_score_monetized),
  'Total Monetized Score Delimited Region [EUR/day]' = as.numeric(siba_total_score_monetized_affected_by_siba),
  'Total Travel Time for PT-Users [h/day]' = as.numeric(siba_total_trav_time),
  'Total Transfers [1/day]' =  as.numeric(siba_total_transfers),
  'Total Car-km [km/day]' = as.numeric(siba_total_car_km),
  check.names = FALSE)

### Siemensbahn+v1 ###

persons_siba_v1 <- read_output_persons(paste(path_run_siba_v1, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_siba_v1 <- read_output_trips(paste(path_run_siba_v1, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_siba_v1 <- "../../../../outputs-10pct/output-SiBa+v1-10pct/berlin-v6.4.output_legs.csv.gz"
legs_siba_v1 <- read_delim(gzfile(output_legs_siba_v1))

# Monetized score
siba_v1_score_monetized <- persons_siba_v1 %>%
  filter(grepl("^(berlin|dng|bb).+", person)) %>%
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_v1_total_score_monetized <- siba_v1_score_monetized %>%
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Filtering out the agents that start or end a trip on the main neighborhoods affected by the Siemensbahn
trips_siba_v1_sf <- trips_siba_v1  %>%
  filter(!is.na(start_x) & !is.na(start_y) & !is.na(end_x) & !is.na(end_y)) 

trips_siba_v1_start_sf <- trips_siba_v1_sf %>%
  st_as_sf(coords = c("start_x","start_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

trips_siba_v1_end_sf <- trips_siba_v1_sf %>%
  st_as_sf(coords = c("end_x","end_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

persons_siba_v1_affected_by_siba <- unique(trips_siba_v1_start_sf$person,trips_siba_v1_end_sf$person)

# Monetized score for agents affected by SiBa+v1
siba_v1_score_monetized_affected_by_siba <- persons_siba_v1 %>%
  filter(person %in% persons_siba_v1_affected_by_siba) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_v1_total_score_monetized_affected_by_siba <- siba_v1_score_monetized_affected_by_siba %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Travel time
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

siba_v1_total_trav_time <- siba_v1_trav_time %>%
  summarise(total_trav_time = sum(person_trav_time)) / 3600

# PT trips
siba_v1_pt_trips <- trips_siba_v1 %>%
  filter(
    grepl("^(berlin|dng|bb).+", person),
    main_mode == "pt")

# Transfers
siba_v1_transfers <- siba_v1_trav_time %>%
  select(person,modes) %>%
  filter(!is.na(modes)) %>%
  mutate(num_transfers = map_int(modes, count_transfers))

siba_v1_total_transfers <- siba_v1_transfers %>%
  summarise(total_transfers = sum(num_transfers, na.rm = TRUE))

# Car-km
siba_v1_car_km <- trips_siba_v1 %>%
  filter(
    grepl("^(berlin|dng|bb).+", person),
    main_mode == "car") %>%
  group_by(person) %>%
  summarise(person_car_km = sum(traveled_distance) / 1000)

siba_v1_total_car_km <- siba_v1_car_km %>%
  summarise(total_car_km = sum(person_car_km))

# Results
siba_v1_results <- data.frame(
  Scenario = "Siemensbahn+v1",
  'Total Monetized Score [EUR/day]' = as.numeric(siba_v1_total_score_monetized),
  'Total Monetized Score Delimited Region [EUR/day]' = as.numeric(siba_v1_total_score_monetized_affected_by_siba),
  'Total Travel Time for PT-Users [h/day]' = as.numeric(siba_v1_total_trav_time),
  'Total Transfers [1/day]' =  as.numeric(siba_v1_total_transfers),
  'Total Car-km [km/day]' = as.numeric(siba_v1_total_car_km),
  check.names = FALSE)

### Siemensbahn+v2 ###

persons_siba_v2 <- read_output_persons(paste(path_run_siba_v2, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_siba_v2 <- read_output_trips(paste(path_run_siba_v2, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_siba_v2 <- "../../../../outputs-10pct/output-SiBa+v2-10pct/berlin-v6.4.output_legs.csv.gz"
legs_siba_v2 <- read_delim(gzfile(output_legs_siba_v2))

# Monetized score
siba_v2_score_monetized <- persons_siba_v2 %>%
  filter(grepl("^(berlin|dng|bb).+", person)) %>%
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_v2_total_score_monetized <- siba_v2_score_monetized %>%
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Filtering out the agents that start or end a trip on the main neighborhoods affected by the Siemensbahn
trips_siba_v2_sf <- trips_siba_v2  %>%
  filter(!is.na(start_x) & !is.na(start_y) & !is.na(end_x) & !is.na(end_y)) 

trips_siba_v2_start_sf <- trips_siba_v2_sf %>%
  st_as_sf(coords = c("start_x","start_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

trips_siba_v2_end_sf <- trips_siba_v2_sf %>%
  st_as_sf(coords = c("end_x","end_y"), crs = 25832) %>% 
  st_intersection(neighborhoods_siba_shp)

persons_siba_v2_affected_by_siba <- unique(trips_siba_v2_start_sf$person,trips_siba_v2_end_sf$person)

# Monetized score for agents affected by SiBa+v2
siba_v2_score_monetized_affected_by_siba <- persons_siba_v2 %>%
  filter(person %in% persons_siba_v2_affected_by_siba) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_v2_total_score_monetized_affected_by_siba <- siba_v2_score_monetized_affected_by_siba %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# Travel time
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

siba_v2_total_trav_time <- siba_v2_trav_time %>%
  summarise(total_trav_time = sum(person_trav_time)) / 3600

# PT trips
siba_v2_pt_trips <- trips_siba_v2 %>%
  filter(
    grepl("^(berlin|dng|bb).+", person),
    main_mode == "pt")

# Transfers
siba_v2_transfers <- siba_v2_trav_time %>%
  select(person,modes) %>%
  filter(!is.na(modes)) %>%
  mutate(num_transfers = map_int(modes, count_transfers))

siba_v2_total_transfers <- siba_v2_transfers %>%
  summarise(total_transfers = sum(num_transfers, na.rm = TRUE))

# Car-km
siba_v2_car_km <- trips_siba_v2 %>%
  filter(
    grepl("^(berlin|dng|bb).+", person),
    main_mode == "car") %>%
  group_by(person) %>%
  summarise(person_car_km = sum(traveled_distance) / 1000)

siba_v2_total_car_km <- siba_v2_car_km %>%
  summarise(total_car_km = sum(person_car_km))

# Results
siba_v2_results <- data.frame(
  Scenario = "Siemensbahn+v2",
  'Total Monetized Score [EUR/day]' = as.numeric(siba_v2_total_score_monetized),
  'Total Monetized Score Delimited Region [EUR/day]' = as.numeric(siba_v2_total_score_monetized_affected_by_siba),
  'Total Travel Time for PT-Users [h/day]' = as.numeric(siba_v2_total_trav_time),
  'Total Transfers [1/day]' =  as.numeric(siba_v2_total_transfers),
  'Total Car-km [km/day]' = as.numeric(siba_v2_total_car_km),
  check.names = FALSE)

### Total Results ###

results <- bind_rows(
  base_case_results, 
  siba_results,
  #siba_v1_results,
  #siba_v2_results
)

write_xlsx(results, "results-analysis_Siemensbahn.xlsx")

### Comparison ###

# Agents switching to pt, [Siemensbahn] vs [Base Case] - Total travel time for former car users in [Base Case] in pt in [Siemensbahn] in [hours]
siba_base_case_switching_pt <- base_case_car_trips %>% 
  inner_join(siba_pt_trips, by=c("person", "trip_id"), suffix=c(".base_case", ".siba")) %>% 
  select(person,trip_id,trav_time.base_case,wait_time.base_case,traveled_distance.base_case,main_mode.base_case,trav_time.siba,wait_time.siba,traveled_distance.siba,main_mode.siba)

siba_base_case_total_trav_time_switching_pt <- siba_base_case_switching_pt %>%   
  group_by(person) %>%
  summarise(
    trav_time.base_case = sum(trav_time.base_case, na.rm = TRUE),
    wait_time.base_case = sum(wait_time.base_case, na.rm = TRUE),
    person_trav_time.base_case = trav_time.base_case + wait_time.base_case,
    trav_time.siba = sum(trav_time.siba, na.rm = TRUE),
    wait_time.siba = sum(wait_time.siba, na.rm = TRUE),
    person_trav_time.siba = trav_time.siba + wait_time.siba) %>% 
  summarise(total_car_trav_time.base_case = sum(person_trav_time.base_case) / 3600,
            total_pt_trav_time.siba = sum(person_trav_time.siba) / 3600) # (results may show [secs], but it's [hours]!!)

# Agents switching to pt, [Siemensbahn] vs [Base Case] - Total car-km in [Base Case] for new pt-users in [Siemensbahn] in [km]
siba_base_case_former_car_km <- siba_base_case_switching_pt %>% 
  summarise(total_car_km.base_case = sum(traveled_distance.base_case) / 1000)

# Agents remaining in pt, [Siemensbahn] vs [Base Case] - Total travel time in pt for remaining pt users in [Siemensbahn] in [hours]
siba_base_case_remaining_pt <- base_case_pt_trips %>% 
  inner_join(siba_pt_trips, by=c("person", "trip_id"), suffix=c(".base_case", ".siba")) %>% 
  select(person,trip_id,trav_time.base_case,wait_time.base_case,traveled_distance.base_case,main_mode.base_case,trav_time.siba,wait_time.siba,traveled_distance.siba,main_mode.siba)

siba_base_case_total_trav_time_remaining_pt <- siba_base_case_remaining_pt %>%   
  group_by(person) %>%
  summarise(
    trav_time.base_case = sum(trav_time.base_case, na.rm = TRUE),
    wait_time.base_case = sum(wait_time.base_case, na.rm = TRUE),
    person_trav_time.base_case = trav_time.base_case + wait_time.base_case,
    trav_time.siba = sum(trav_time.siba, na.rm = TRUE),
    wait_time.siba = sum(wait_time.siba, na.rm = TRUE),
    person_trav_time.siba = trav_time.siba + wait_time.siba) %>% 
  summarise(total_pt_trav_time.base_case = sum(person_trav_time.base_case) / 3600,
            total_pt_trav_time.siba = sum(person_trav_time.siba) / 3600) # (results may show [secs], but it's [hours]!!)

# Agents switching to SiBa, [Siemensbahn] vs [Base Case] - Former car users in [Base Case] using SiBa-Line in [Siemensbahn]
siba_base_case_switching_pt_list <- unique(siba_base_case_switching_pt$person)

siba_base_case_switching_siba <- legs_siba %>% 
  filter(person %in% siba_base_case_switching_pt_list) %>% 
  filter(grepl("^SiBa", transit_line, ignore.case = TRUE))
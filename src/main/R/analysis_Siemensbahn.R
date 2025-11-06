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
library(ggplot2)

setwd("C:/Users/Eduardo Lima/Documents/TUB/Studium/Masterarbeit_git/matsim-berlin/src/main/R")

path_run_base <- "../../../../outputs-10pct/output-Base_Case-10pct"
path_run_base_seed1234 <- "../../../../outputs-10pct/output-Base_Case-10pct_seed1234"
path_run_base_seed2345 <- "../../../../outputs-10pct/output-Base_Case-10pct_seed2345"
path_run_siba <- "../../../../outputs-10pct/output-SiBa-10pct"
path_run_siba_v1 <- "../../../../outputs-10pct/output-SiBa+v1-10pct"
path_run_siba_v2 <- "../../../../outputs-10pct/output-SiBa+v2-10pct"

# Function for transfers count
count_transfers <- function(mode_sequence) {
  if (is.na(mode_sequence)) return(NA)
  segments <- unlist(strsplit(mode_sequence, ";"))
  sum(map_int(segments, ~ {
    modes <- unlist(strsplit(.x, "-"))
    max(0, sum(modes == "pt") - 1)
  }))
}

# Delimited Region: Charlottenburg-Nord, Siemensstadt, Haselhorst, Hakenfelde
ortsteile_shp <- st_read("lor_ortsteile.shp//lor_ortsteile.shp") %>% 
  st_transform(25832)

delimited_region_shp <- ortsteile_shp %>% 
  filter(OTEIL %in% c("Charlottenburg-Nord", "Siemensstadt", "Haselhorst", "Hakenfelde"))

tmap_mode("view")
tm_shape(delimited_region_shp) + 
  tm_polygons()

### Base Case ###

persons_base_case <- read_output_persons(paste(path_run_base, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_base_case <- read_output_trips(paste(path_run_base, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_base_case <- "../../../../outputs-10pct/output-Base_Case-10pct/berlin-v6.4.output_legs.csv.gz"
legs_base_case <- read_delim(gzfile(output_legs_base_case))

# Seed 1234
persons_base_case_seed1234 <- read_output_persons(paste(path_run_base_seed1234, "/berlin-v6.4.output_persons.csv.gz", sep=""))

# Seed 2345
persons_base_case_seed2345 <- read_output_persons(paste(path_run_base_seed2345, "/berlin-v6.4.output_persons.csv.gz", sep=""))

# Total Score
base_case_total_score <- persons_base_case %>% 
  filter(grepl("^(berlin|dng|bb).+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_seed1234 <- persons_base_case_seed1234 %>% 
  filter(grepl("^(berlin|dng|bb).+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_seed2345 <- persons_base_case_seed2345 %>% 
  filter(grepl("^(berlin|dng|bb).+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for DNG-Agents
base_case_total_score_dng <- persons_base_case %>% 
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_seed1234_dng <- persons_base_case_seed1234 %>% 
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_seed2345_dng <- persons_base_case_seed2345 %>% 
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for Berlin-Agents
base_case_total_score_berlin <- persons_base_case %>% 
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_seed1234_berlin <- persons_base_case_seed1234 %>% 
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_seed2345_berlin <- persons_base_case_seed2345 %>% 
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for BB-Agents
base_case_total_score_bb <- persons_base_case %>% 
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_seed1234_bb <- persons_base_case_seed1234 %>% 
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_seed2345_bb <- persons_base_case_seed2345 %>% 
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score Results
base_case_total_score_results <- data.frame(
  Scenario = "Base Case",
  'Total Score' = as.numeric(base_case_total_score),
  'Total Score DNG-Agents' = as.numeric(base_case_total_score_dng),
  'Total Score Berlin-Agents' = as.numeric(base_case_total_score_berlin),
  'Total Score BB-Agents' =  as.numeric(base_case_total_score_bb),
  check.names = FALSE)

base_case_total_score_seed1234_results <- data.frame(
  Scenario = "Base Case_seed1234",
  'Total Score' = as.numeric(base_case_total_score_seed1234),
  'Total Score DNG-Agents' = as.numeric(base_case_total_score_seed1234_dng),
  'Total Score Berlin-Agents' = as.numeric(base_case_total_score_seed1234_berlin),
  'Total Score BB-Agents' =  as.numeric(base_case_total_score_seed1234_bb),
  check.names = FALSE)

base_case_total_score_seed2345_results <- data.frame(
  Scenario = "Base Case_seed2345",
  'Total Score' = as.numeric(base_case_total_score_seed2345),
  'Total Score DNG-Agents' = as.numeric(base_case_total_score_seed2345_dng),
  'Total Score Berlin-Agents' = as.numeric(base_case_total_score_seed2345_berlin),
  'Total Score BB-Agents' =  as.numeric(base_case_total_score_seed2345_bb),
  check.names = FALSE)

base_case_total_score_results_binded <- bind_rows(
  base_case_total_score_results, 
  base_case_total_score_seed1234_results,
  base_case_total_score_seed2345_results
)

# Filtering out the agents that start or end a trip within the Delimited Region
trips_base_case_sf <- trips_base_case  %>%
  filter(grepl("^(berlin|dng|bb).+", person), 
         !is.na(start_x) & !is.na(start_y) & !is.na(end_x) & !is.na(end_y)) 

trips_base_case_start_sf <- trips_base_case_sf %>%
  st_as_sf(coords = c("start_x","start_y"), crs = 25832) %>% 
  st_intersection(delimited_region_shp)

trips_base_case_end_sf <- trips_base_case_sf %>%
  st_as_sf(coords = c("end_x","end_y"), crs = 25832) %>% 
  st_intersection(delimited_region_shp)

persons_delimited_region <- unique(trips_base_case_start_sf$person,trips_base_case_end_sf$person)

# Average income
average_income <- persons_base_case %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(!is.na(income)) %>%
  summarise(average_income = mean(income))

# Monetized score for agents with trips starting or ending within the Delimited Region
base_case_score_monetized <- persons_base_case %>%
  filter(person %in% persons_delimited_region) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

base_case_total_score_monetized <- base_case_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# PT trips
base_case_pt_trips <- trips_base_case %>%
  filter(person %in% persons_delimited_region,
         main_mode == "pt")

# Car trips
base_case_car_trips <- trips_base_case %>%
  filter(person %in% persons_delimited_region,
    main_mode == "car")

# Other trips (non-car, non-PT trips)
base_case_other_modes_trips <- trips_base_case %>%
  filter(person %in% persons_delimited_region,
    main_mode != "car" & main_mode != "pt")

# Travel time
base_case_trav_time <- base_case_pt_trips %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    person_trav_time = trav_time + wait_time)

base_case_total_trav_time <- base_case_trav_time %>% 
  summarise(total_trav_time = sum(person_trav_time)) * 10 / 3600 # (* sample upscale factor 10)

# Traveled distance PT
base_case_total_trav_distance <- base_case_pt_trips %>% 
  summarise(total_trav_distance = sum(traveled_distance) * 10 / 1000) # (* sample upscale factor 10)

# Transfers
base_case_transfers <- base_case_pt_trips %>%
  filter(!is.na(modes)) %>%
  mutate(num_transfers = map_int(modes, count_transfers))

base_case_total_transfers <- base_case_transfers %>% 
  summarise(total_transfers = sum(num_transfers, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# Car-km
base_case_car_km <- base_case_car_trips %>% 
  group_by(person) %>%
  summarise(person_car_km = sum(traveled_distance) / 1000)

base_case_total_car_km <- base_case_car_km %>% 
  summarise(total_car_km = sum(person_car_km)) * 10 # (* sample upscale factor 10)

# Results
base_case_results <- data.frame(
  Scenario = "Base Case",
  'Total Monetized Score Delimited Region [EUR/day]' = as.numeric(base_case_total_score_monetized),
  'Total Travel Time for PT-Users [h/day]' = as.numeric(base_case_total_trav_time),
  'Total Travel Distance for PT-Users [km/day]' = as.numeric(base_case_total_trav_distance),
  'Total Transfers [1/day]' =  as.numeric(base_case_total_transfers),
  'Total Car-km [km/day]' = as.numeric(base_case_total_car_km),
  check.names = FALSE)

### Siemensbahn ###

persons_siba <- read_output_persons(paste(path_run_siba, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_siba <- read_output_trips(paste(path_run_siba, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_siba <- "../../../../outputs-10pct/output-SiBa-10pct/berlin-v6.4.output_legs.csv.gz"
legs_siba <- read_delim(gzfile(output_legs_siba))

# Total Score
siba_total_score <- persons_siba %>% 
  filter(grepl("^(berlin|dng|bb).+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for DNG-Agents
siba_total_score_dng <- persons_siba %>% 
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for Berlin-Agents
siba_total_score_berlin <- persons_siba %>% 
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for BB-Agents
siba_total_score_bb <- persons_siba %>% 
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score Results
siba_total_score_results <- data.frame(
  Scenario = "Siemensbahn",
  'Total Score' = as.numeric(siba_total_score),
  'Total Score DNG-Agents' = as.numeric(siba_total_score_dng),
  'Total Score Berlin-Agents' = as.numeric(siba_total_score_berlin),
  'Total Score BB-Agents' =  as.numeric(siba_total_score_bb),
  check.names = FALSE)

# Monetized score for agents with trips starting or ending within the Delimited Region
siba_score_monetized <- persons_siba %>%
  filter(person %in% persons_delimited_region) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_total_score_monetized <- siba_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# PT trips
siba_pt_trips <- trips_siba %>%
  filter(person %in% persons_delimited_region,
         main_mode == "pt")

# Car trips
siba_car_trips <- trips_siba %>%
  filter(person %in% persons_delimited_region,
         main_mode == "car")

# Travel time 
siba_trav_time <- siba_pt_trips %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    person_trav_time = trav_time + wait_time)

siba_total_trav_time <- siba_trav_time %>% 
  summarise(total_trav_time = sum(person_trav_time)) * 10 / 3600 # (* sample upscale factor 10) 

# Traveled distance PT
siba_total_trav_distance <- siba_pt_trips %>% 
  summarise(total_trav_distance = sum(traveled_distance) * 10 / 1000) # (* sample upscale factor 10)

# Transfers
siba_transfers <- siba_pt_trips %>%
  select(trip_id,modes) %>%
  filter(!is.na(modes)) %>%
  mutate(num_transfers = map_int(modes, count_transfers))

siba_total_transfers <- siba_transfers %>% 
  summarise(total_transfers = sum(num_transfers, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# Car-km
siba_car_km <- siba_car_trips %>% 
  group_by(person) %>%
  summarise(person_car_km = sum(traveled_distance) / 1000)

siba_total_car_km <- siba_car_km %>% 
  summarise(total_car_km = sum(person_car_km)) * 10 # (* sample upscale factor 10)

# Results
siba_results <- data.frame(
  Scenario = "Siemensbahn",
  'Total Monetized Score Delimited Region [EUR/day]' = as.numeric(siba_total_score_monetized),
  'Total Travel Time for PT-Users [h/day]' = as.numeric(siba_total_trav_time),
  'Total Travel Distance for PT-Users [km/day]' = as.numeric(siba_total_trav_distance),
  'Total Transfers [1/day]' =  as.numeric(siba_total_transfers),
  'Total Car-km [km/day]' = as.numeric(siba_total_car_km),
  check.names = FALSE)

### Siemensbahn+v1 ###

persons_siba_v1 <- read_output_persons(paste(path_run_siba_v1, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_siba_v1 <- read_output_trips(paste(path_run_siba_v1, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_siba_v1 <- "../../../../outputs-10pct/output-SiBa+v1-10pct/berlin-v6.4.output_legs.csv.gz"
legs_siba_v1 <- read_delim(gzfile(output_legs_siba_v1))

# Total Score
siba_v1_total_score <- persons_siba_v1 %>% 
  filter(grepl("^(berlin|dng|bb).+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for DNG-Agents
siba_v1_total_score_dng <- persons_siba_v1 %>% 
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for Berlin-Agents
siba_v1_total_score_berlin <- persons_siba_v1 %>% 
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for BB-Agents
siba_v1_total_score_bb <- persons_siba_v1 %>% 
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score Results
siba_v1_total_score_results <- data.frame(
  Scenario = "Siemensbahn+v1",
  'Total Score' = as.numeric(siba_v1_total_score),
  'Total Score DNG-Agents' = as.numeric(siba_v1_total_score_dng),
  'Total Score Berlin-Agents' = as.numeric(siba_v1_total_score_berlin),
  'Total Score BB-Agents' =  as.numeric(siba_v1_total_score_bb),
  check.names = FALSE)

# Monetized score for agents with trips starting or ending within the Delimited Region
siba_v1_score_monetized <- persons_siba_v1 %>%
  filter(person %in% persons_delimited_region) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_v1_total_score_monetized <- siba_v1_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# PT trips
siba_v1_pt_trips <- trips_siba_v1 %>%
  filter(person %in% persons_delimited_region,
         main_mode == "pt")

# Car trips
siba_v1_car_trips <- trips_siba_v1 %>%
  filter(person %in% persons_delimited_region,
         main_mode == "car")

# Travel time 
siba_v1_trav_time <- siba_v1_pt_trips %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    person_trav_time = trav_time + wait_time)

siba_v1_total_trav_time <- siba_v1_trav_time %>% 
  summarise(total_trav_time = sum(person_trav_time)) * 10 / 3600 # (* sample upscale factor 10) 

# Traveled distance PT
siba_v1_total_trav_distance <- siba_v1_pt_trips %>% 
  summarise(total_trav_distance = sum(traveled_distance) * 10 / 1000) # (* sample upscale factor 10)

# Transfers
siba_v1_transfers <- siba_v1_pt_trips %>%
  select(trip_id,modes) %>%
  filter(!is.na(modes)) %>%
  mutate(num_transfers = map_int(modes, count_transfers))

siba_v1_total_transfers <- siba_v1_transfers %>% 
  summarise(total_transfers = sum(num_transfers, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# Car-km
siba_v1_car_km <- siba_v1_car_trips %>% 
  group_by(person) %>%
  summarise(person_car_km = sum(traveled_distance) / 1000)

siba_v1_total_car_km <- siba_v1_car_km %>% 
  summarise(total_car_km = sum(person_car_km)) * 10 # (* sample upscale factor 10)

# Results
siba_v1_results <- data.frame(
  Scenario = "Siemensbahn+v1",
  'Total Monetized Score Delimited Region [EUR/day]' = as.numeric(siba_v1_total_score_monetized),
  'Total Travel Time for PT-Users [h/day]' = as.numeric(siba_v1_total_trav_time),
  'Total Travel Distance for PT-Users [km/day]' = as.numeric(siba_v1_total_trav_distance),
  'Total Transfers [1/day]' =  as.numeric(siba_v1_total_transfers),
  'Total Car-km [km/day]' = as.numeric(siba_v1_total_car_km),
  check.names = FALSE)

### Siemensbahn+v2 ###

persons_siba_v2 <- read_output_persons(paste(path_run_siba_v2, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_siba_v2 <- read_output_trips(paste(path_run_siba_v2, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_siba_v2 <- "../../../../outputs-10pct/output-SiBa+v2-10pct/berlin-v6.4.output_legs.csv.gz"
legs_siba_v2 <- read_delim(gzfile(output_legs_siba_v2))

# Total Score
siba_v2_total_score <- persons_siba_v2 %>% 
  filter(grepl("^(berlin|dng|bb).+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for DNG-Agents
siba_v2_total_score_dng <- persons_siba_v2 %>% 
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for Berlin-Agents
siba_v2_total_score_berlin <- persons_siba_v2 %>% 
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for BB-Agents
siba_v2_total_score_bb <- persons_siba_v2 %>% 
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score Results
siba_v2_total_score_results <- data.frame(
  Scenario = "Siemensbahn+v2",
  'Total Score' = as.numeric(siba_v2_total_score),
  'Total Score DNG-Agents' = as.numeric(siba_v2_total_score_dng),
  'Total Score Berlin-Agents' = as.numeric(siba_v2_total_score_berlin),
  'Total Score BB-Agents' =  as.numeric(siba_v2_total_score_bb),
  check.names = FALSE)

# Monetized score for agents with trips starting or ending within the Delimited Region
siba_v2_score_monetized <- persons_siba_v2 %>%
  filter(person %in% persons_delimited_region) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_v2_total_score_monetized <- siba_v2_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# PT trips
siba_v2_pt_trips <- trips_siba_v2 %>%
  filter(person %in% persons_delimited_region,
         main_mode == "pt")

# Car trips
siba_v2_car_trips <- trips_siba_v2 %>%
  filter(person %in% persons_delimited_region,
         main_mode == "car")

# Travel time 
siba_v2_trav_time <- siba_v2_pt_trips %>% 
  group_by(person) %>%
  summarise(
    trav_time = sum(trav_time, na.rm = TRUE),
    wait_time = sum(wait_time, na.rm = TRUE),
    modes = paste(modes, collapse = ";"),
    person_trav_time = trav_time + wait_time)

siba_v2_total_trav_time <- siba_v2_trav_time %>% 
  summarise(total_trav_time = sum(person_trav_time)) * 10 / 3600 # (* sample upscale factor 10) 

# Traveled distance PT
siba_v2_total_trav_distance <- siba_v2_pt_trips %>% 
  summarise(total_trav_distance = sum(traveled_distance) * 10 / 1000) # (* sample upscale factor 10)

# Transfers
siba_v2_transfers <- siba_v2_pt_trips %>%
  select(trip_id,modes) %>%
  filter(!is.na(modes)) %>%
  mutate(num_transfers = map_int(modes, count_transfers))

siba_v2_total_transfers <- siba_v2_transfers %>% 
  summarise(total_transfers = sum(num_transfers, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# Car-km
siba_v2_car_km <- siba_v2_car_trips %>% 
  group_by(person) %>%
  summarise(person_car_km = sum(traveled_distance) / 1000)

siba_v2_total_car_km <- siba_v2_car_km %>% 
  summarise(total_car_km = sum(person_car_km)) * 10 # (* sample upscale factor 10)

# Results
siba_v2_results <- data.frame(
  Scenario = "Siemensbahn+v2",
  'Total Monetized Score Delimited Region [EUR/day]' = as.numeric(siba_v2_total_score_monetized),
  'Total Travel Time for PT-Users [h/day]' = as.numeric(siba_v2_total_trav_time),
  'Total Travel Distance for PT-Users [km/day]' = as.numeric(siba_v2_total_trav_distance),
  'Total Transfers [1/day]' =  as.numeric(siba_v2_total_transfers),
  'Total Car-km [km/day]' = as.numeric(siba_v2_total_car_km),
  check.names = FALSE)

### Total Results ###

results <- bind_rows(
  base_case_results, 
  siba_results,
  siba_v1_results,
  siba_v2_results
)

write_xlsx(results, "results-analysis_Siemensbahn.xlsx")

### Total Score Results ###

total_score_results_binded <- bind_rows(
  base_case_total_score_results_binded, 
  siba_total_score_results,
  siba_v1_total_score_results,
  siba_v2_total_score_results
)

write_xlsx(total_score_results_binded, "total_score_results_binded-analysis_Siemensbahn.xlsx")

### Comparison ###

## Travel Time ##

# Agents switching to pt, [Siemensbahn] vs [Base Case] - Total travel time for former car users in [Base Case] in pt in [Siemensbahn] in [hours]
siba_base_case_switching_pt <- base_case_car_trips %>% 
  inner_join(siba_pt_trips, by=c("person", "trip_id"), suffix=c(".base_case", ".siba")) %>% 
  select(person,trip_id,trav_time.base_case,wait_time.base_case,traveled_distance.base_case,main_mode.base_case,trav_time.siba,wait_time.siba,traveled_distance.siba,main_mode.siba)

siba_base_case_switching_pt_list <- unique(siba_base_case_switching_pt$person)

siba_base_case_total_trav_time_switching_pt <- siba_base_case_switching_pt %>%   
  group_by(person) %>%
  summarise(
    trav_time.base_case = sum(trav_time.base_case, na.rm = TRUE),
    wait_time.base_case = sum(wait_time.base_case, na.rm = TRUE),
    person_trav_time.base_case = trav_time.base_case + wait_time.base_case,
    trav_time.siba = sum(trav_time.siba, na.rm = TRUE),
    wait_time.siba = sum(wait_time.siba, na.rm = TRUE),
    person_trav_time.siba = trav_time.siba + wait_time.siba) %>% 
  summarise(total_car_trav_time.base_case = sum(person_trav_time.base_case) * 10 / 3600,
            total_pt_trav_time.siba = sum(person_trav_time.siba) * 10 / 3600) # (results may show [secs], but it's [hours]!!)
                                                                              # (* sample upscale factor 10)

# Agents switching to pt from other modes, [Siemensbahn] vs [Base Case] - Total travel time for non-car and non-pt users in [Base Case] in pt in [Siemensbahn] in [hours]
siba_base_case_switching_pt_from_other_modes <- base_case_other_modes_trips %>% 
  inner_join(siba_pt_trips, by=c("person", "trip_id"), suffix=c(".base_case", ".siba")) %>% 
  select(person,trip_id,trav_time.base_case,wait_time.base_case,traveled_distance.base_case,main_mode.base_case,trav_time.siba,wait_time.siba,traveled_distance.siba,main_mode.siba)

siba_base_case_switching_pt_from_other_modes_list <- unique(siba_base_case_switching_pt_from_other_modes$person)

siba_base_case_total_trav_time_switching_pt_from_other_modes <- siba_base_case_switching_pt_from_other_modes %>%   
  group_by(person) %>%
  summarise(
    trav_time.base_case = sum(trav_time.base_case, na.rm = TRUE),
    wait_time.base_case = sum(wait_time.base_case, na.rm = TRUE),
    person_trav_time.base_case = trav_time.base_case + wait_time.base_case,
    trav_time.siba = sum(trav_time.siba, na.rm = TRUE),
    wait_time.siba = sum(wait_time.siba, na.rm = TRUE),
    person_trav_time.siba = trav_time.siba + wait_time.siba) %>% 
  summarise(total_other_modes_trav_time.base_case = sum(person_trav_time.base_case) * 10 / 3600,
            total_pt_trav_time.siba = sum(person_trav_time.siba) * 10 / 3600) # (results may show [secs], but it's [hours]!!)
                                                                              # (* sample upscale factor 10)

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
  summarise(total_pt_trav_time.base_case = sum(person_trav_time.base_case) * 10 / 3600,
            total_pt_trav_time.siba = sum(person_trav_time.siba) * 10 / 3600) # (results may show [secs], but it's [hours]!!)
                                                                              # (* sample upscale factor 10)

# Agents switching to SiBa, [Siemensbahn] vs [Base Case] - Former car users in [Base Case] using SiBa-Line in [Siemensbahn]
siba_base_case_switching_siba <- legs_siba %>% 
  filter(person %in% siba_base_case_switching_pt_list) %>% 
  filter(grepl("^SiBa", transit_line, ignore.case = TRUE))

## Transfers ##

# Agents switching to pt, [Siemensbahn] vs [Base Case] - Total transfers for former car users in [Base Case] in pt in [Siemensbahn] in [unit]
siba_base_case_transfers_switching_pt <- base_case_car_trips %>% 
  inner_join(siba_transfers, by=c("trip_id"), suffix=c(".base_case", ".siba")) %>% 
  select(trip_id,modes.base_case,modes.siba) %>%
  mutate(num_transfers.siba = map_int(modes.siba, count_transfers))

siba_base_case_total_transfers_switching_pt <- siba_base_case_transfers_switching_pt %>% 
  summarise(total_transfers.siba = sum(num_transfers.siba, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# Agents switching to pt from other modes, [Siemensbahn] vs [Base Case] - Total transfers for non-car and non-pt users in [Base Case] in pt in [Siemensbahn] in [unit]
siba_base_case_transfers_switching_pt_from_other_modes <- base_case_other_modes_trips %>% 
  inner_join(siba_transfers, by=c("trip_id"), suffix=c(".base_case", ".siba")) %>% 
  select(trip_id,modes.base_case,modes.siba) %>%
  mutate(num_transfers.siba = map_int(modes.siba, count_transfers))

siba_base_case_total_transfers_switching_pt_from_other_modes <- siba_base_case_transfers_switching_pt_from_other_modes %>% 
  summarise(total_transfers.siba = sum(num_transfers.siba, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# Agents remaining in pt, [Siemensbahn] vs [Base Case] - Total transfers in pt for remaining pt users in [Siemensbahn] in [unit]
siba_base_case_transfers_remaining_pt <- base_case_pt_trips %>% 
  inner_join(siba_pt_trips, by=c("trip_id"), suffix=c(".base_case", ".siba")) %>% 
  select(trip_id,modes.base_case,modes.siba) %>%
  mutate(
    num_transfers.base_case = map_int(modes.base_case, count_transfers),
    num_transfers.siba = map_int(modes.siba, count_transfers))

siba_base_case_total_transfers_remaining_pt <- siba_base_case_transfers_remaining_pt %>% 
  summarise(
    total_transfers.base_case = sum(num_transfers.base_case, na.rm = TRUE) * 10,
    total_transfers.siba = sum(num_transfers.siba, na.rm = TRUE) * 10 ) # (* sample upscale factor 10)

## Car-km ##

# Agents switching to pt, [Siemensbahn] vs [Base Case] - Total car-km in [Base Case] for new pt-users in [Siemensbahn] in [km]
siba_base_case_former_car_km <- siba_base_case_switching_pt %>% 
  summarise(total_car_km.base_case = sum(traveled_distance.base_case) * 10 / 1000) # (* sample upscale factor 10)

## Validation of Simulation ##

# How many former car users in [Base Case] switching to pt in [Siemensbahn] do not use car anymore?
siba_base_case_former_car_users_persons_keeping_car <- trips_siba %>% 
  filter(
    person %in% siba_base_case_switching_pt_list,
    main_mode == "car") 

siba_base_case_former_car_users_persons_keeping_car_list <- 
  unique(siba_base_case_former_car_users_persons_keeping_car$person)

siba_base_case_former_car_users_persons_leaving_car_list <- 
  siba_base_case_switching_pt_list[!siba_base_case_switching_pt_list %in% 
                                     siba_base_case_former_car_users_persons_keeping_car_list]

# How many former car users in [Base Case] switching to pt in [Siemensbahn] already used pt before?
siba_base_case_former_car_users_persons_with_pt_abo <- trips_base_case %>% 
  filter(
    person %in% siba_base_case_switching_pt_list,
    main_mode == "pt") 

siba_base_case_former_car_users_persons_with_pt_abo_list <- 
  unique(siba_base_case_former_car_users_persons_with_pt_abo$person)

siba_base_case_former_car_users_persons_without_pt_abo_list <- 
  siba_base_case_switching_pt_list[!siba_base_case_switching_pt_list %in% 
                                     siba_base_case_former_car_users_persons_with_pt_abo_list]

'# How many former non-car non-pt users in [Base Case] switching to pt in [Siemensbahn] already used pt before?
siba_base_case_former_other_modes_users_persons_with_pt_abo <- trips_base_case %>% 
  filter(
    person %in% siba_base_case_switching_pt_from_other_modes_list,
    main_mode == "pt") 

siba_base_case_former_other_modes_users_persons_with_pt_abo_list <- 
  unique(siba_base_case_former_other_modes_users_persons_with_pt_abo$person)

siba_base_case_former_other_modes_users_persons_without_pt_abo_list <- 
  siba_base_case_switching_pt_list[!siba_base_case_switching_pt_from_other_modes_list %in% 
                                     siba_base_case_former_other_modes_users_persons_with_pt_abo_list]

rm(list=ls(pattern="siba_base_case_former_other_modes_users_persons"))'

## Outliers ##

siba_base_case_total_score_berlin_outliers <- persons_base_case %>% 
  full_join(persons_siba, by=c("person"), suffix=c(".base_case", ".siba")) %>% 
  filter(grepl("^berlin.+", person)) %>%
  select(person,executed_score.base_case,executed_score.siba) %>%
  mutate(score_diff = executed_score.siba - executed_score.base_case) %>% 
  filter(score_diff == max(score_diff, na.rm = TRUE) | score_diff == min(score_diff, na.rm = TRUE))

## Train Capacity ##

train_capacity_siba <- legs_siba %>% 
  filter(grepl("SiBa", transit_line)) %>% 
  mutate(hour = hour(dep_time)) %>% 
  count(hour, transit_line, person = "passengers") %>% 
  arrange(hour, transit_line) %>% 
  mutate(n = n * 10) # (* sample upscale factor 10)

ggplot(train_capacity_siba, aes(x = hour, y = n, fill = transit_line)) +
  geom_col(position = "dodge") +
  labs(
    title = "SiBa-Line - Usage by Hour",
    x = "Hour of Day",
    y = "Number of Passengers",
    fill = "Direction"
  ) +
  scale_fill_discrete(
    labels = c("SiBa_e_w" = "Hauptbahnhof > Gartenfeld", "SiBa_w_e" = "Gartenfeld > Hauptbahnhof")
    ) +
  theme_minimal() +
  scale_x_continuous(breaks = 0:23)

## DNG Agents ##

access_gartenfeld_dng_siba <- legs_siba %>% 
  filter(grepl("SiBa", transit_line)) %>%
  filter(grepl("^dng.+", person)) %>% 
  filter(access_stop_id == "Gartenfeld_e_w" | access_stop_id == "Gartenfeld_w_e")

trip_id_access_gartenfeld_dng_siba <- unique(access_gartenfeld_dng_siba$trip_id)

walk_mode_to_gartenfeld_dng_siba <- legs_siba %>% 
  filter(trip_id %in% trip_id_access_gartenfeld_dng_siba) %>% 
  filter(mode == "walk" & end_link == "pt_116440_SuburbanRailway")

egress_gartenfeld_dng_siba <- legs_siba %>% 
  filter(grepl("SiBa", transit_line)) %>%
  filter(grepl("^dng.+", person)) %>% 
  filter(egress_stop_id == "Gartenfeld_e_w" | egress_stop_id == "Gartenfeld_w_e")

trip_id_egress_gartenfeld_dng_siba <- unique(egress_gartenfeld_dng_siba$trip_id)

walk_mode_from_gartenfeld_dng_siba <- legs_siba %>% 
  filter(trip_id %in% trip_id_egress_gartenfeld_dng_siba) %>% 
  filter(mode == "walk" & start_link == "pt_116440_SuburbanRailway")

walk_mode_gartenfeld_dng_siba <- bind_rows(
  walk_mode_to_gartenfeld_dng_siba, 
  walk_mode_from_gartenfeld_dng_siba
  ) %>% 
  summarise(
    avg_walking_time = mean(trav_time),
    avg_walking_distance = mean(distance)
    )

pt_users_siba <- trips_siba %>% 
  filter(main_mode == "pt")

trip_id_pt_users_siba <- unique(pt_users_siba$trip_id)

walk_mode_to_pt_users_siba <- legs_siba %>% 
  filter(trip_id %in% trip_id_pt_users_siba) %>% 
  filter(mode == "walk") %>%
  filter(!grepl("^pt", start_link) & grepl("rail$|subway$|SuburbanRailway$|tram$", end_link))

walk_mode_from_pt_users_siba <- legs_siba %>% 
  filter(trip_id %in% trip_id_pt_users_siba) %>% 
  filter(mode == "walk") %>%
  filter(grepl("rail$|subway$|SuburbanRailway$|tram$", start_link) & !grepl("^pt", end_link))

walk_mode_pt_users_siba <- bind_rows(
  walk_mode_to_pt_users_siba, 
  walk_mode_from_pt_users_siba
  ) %>% 
  summarise(
    avg_walking_time = mean(trav_time),
    avg_walking_distance = mean(distance)
    )


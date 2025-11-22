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
library(readr)

setwd("C:/Users/Eduardo Lima/Documents/TUB/Studium/Masterarbeit_git/matsim-berlin/src/main/R")

path_run_base <- "../../../../outputs-10pct/output-Base_Case-10pct"
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

# Delimited Region: Charlottenburg-Nord, Siemensstadt, Haselhorst, Hakenfelde, Spandau, Falkenhagener Feld
ortsteile_shp <- st_read("lor_ortsteile.shp//lor_ortsteile.shp") %>% 
  st_transform(25832)

delimited_region_shp <- ortsteile_shp %>% 
  filter(OTEIL %in% c("Charlottenburg-Nord", "Siemensstadt", "Haselhorst", "Hakenfelde", "Spandau", "Falkenhagener Feld"))

unzip("Siemensbahn.kmz", exdir = "siemensbahn_kml")

siemensbahn_kml <- st_read("siemensbahn_kml//doc.kml") %>% 
  st_transform(25832)

track_names <- c("Base Case", "Siemensbahn", "Variant 1", "Variant 2")
colors <- c("yellow", "green", "red", "blue")

tmap_mode("view")

tm_shape(delimited_region_shp) + 
  tm_polygons(alpha = 0.3, col = "lightgreen") +
  tm_text("OTEIL",
          size = 1.2,             
          col = "black",        
          fontface = "bold",
          xmod = 1.0,
          ymod = -1.5) +
  # Base Case
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[1] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[1], lwd = 3) +
  # Siemensbahn
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[2] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[2], lwd = 3) +
  # Variant 1
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[3] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[3], lwd = 3) +
  # Variant 2
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[4] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[4], lwd = 3)

### Base Case ###

persons_base_case <- read_output_persons(paste(path_run_base, "/berlin-v6.4.output_persons.csv.gz", sep=""))
trips_base_case <- read_output_trips(paste(path_run_base, "/berlin-v6.4.output_trips.csv.gz", sep=""))
output_legs_base_case <- "../../../../outputs-10pct/output-Base_Case-10pct/berlin-v6.4.output_legs.csv.gz"
legs_base_case <- read_delim(gzfile(output_legs_base_case))

# Total Score
base_case_total_score <- persons_base_case %>% 
  filter(grepl("^(berlin|dng|bb).+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_delimited_region <- persons_base_case %>% 
  filter(person %in% persons_delimited_region) %>%
  summarise(total_score = sum(executed_score))

# Total Score for DNG-Agents
base_case_total_score_dng <- persons_base_case %>% 
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_dng_delimited_region <- persons_base_case %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for Berlin-Agents
base_case_total_score_berlin <- persons_base_case %>% 
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_berlin_delimited_region <- persons_base_case %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for BB-Agents
base_case_total_score_bb <- persons_base_case %>% 
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

base_case_total_score_bb_delimited_region <- persons_base_case %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score Results
base_case_total_score_results <- data.frame(
  Scenario = "Base Case",
  'Total Score' = as.numeric(base_case_total_score),
  'Total Score DNG-Agents' = as.numeric(base_case_total_score_dng),
  'Total Score Berlin-Agents' = as.numeric(base_case_total_score_berlin),
  'Total Score BB-Agents' =  as.numeric(base_case_total_score_bb),
  'Total Score - Delimited Region' = as.numeric(base_case_total_score_delimited_region),
  'Total Score DNG-Agents - Delimited Region' = as.numeric(base_case_total_score_dng_delimited_region),
  'Total Score Berlin-Agents - Delimited Region' = as.numeric(base_case_total_score_berlin_delimited_region),
  'Total Score BB-Agents - Delimited Region' =  as.numeric(base_case_total_score_bb_delimited_region),
  check.names = FALSE)

# Filtering out the agents that start or end a trip within the Delimited Region - Trips
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

# 10% Poorer and 10% Richer
cutoff_10pct_poorer <- quantile(base_case_score_monetized$marginal_utility_of_money,0.9)
cutoff_10pct_richer <- quantile(base_case_score_monetized$marginal_utility_of_money,0.1)

base_case_score_monetized_10pct_poorer <- base_case_score_monetized[base_case_score_monetized$marginal_utility_of_money >= cutoff_10pct_poorer, ]
cutoff_10pct_poorer_list <- unique(base_case_score_monetized_10pct_poorer$person)

base_case_score_monetized_10pct_richer <- base_case_score_monetized[base_case_score_monetized$marginal_utility_of_money <= cutoff_10pct_richer, ]
cutoff_10pct_richer_list <- unique(base_case_score_monetized_10pct_richer$person)

base_case_total_score_monetized_10pct_poorer <- base_case_score_monetized_10pct_poorer %>% 
  summarise(total_score_monetized_10pct_poorer = sum(score_monetized)) * 10 # (* sample upscale factor 10)

base_case_total_score_monetized_10pct_richer <- base_case_score_monetized_10pct_richer %>% 
  summarise(total_score_monetized_10pct_richer = sum(score_monetized)) * 10 # (* sample upscale factor 10)

base_case_score_monetized_sf <- st_as_sf(base_case_score_monetized, 
                                         coords = c("home_x", "home_y"), 
                                         crs = st_crs(delimited_region_shp))
base_case_score_monetized_10pct_poorer_sf <- st_as_sf(base_case_score_monetized_10pct_poorer, 
                                                      coords = c("home_x", "home_y"), 
                                                      crs = st_crs(delimited_region_shp))
base_case_score_monetized_10pct_richer_sf <- st_as_sf(base_case_score_monetized_10pct_richer, 
                                                      coords = c("home_x", "home_y"), 
                                                      crs = st_crs(delimited_region_shp))

tmap_mode("view")

tm_shape(delimited_region_shp) + 
  tm_polygons(alpha = 0.3, col = "lightgreen") +
  tm_text("OTEIL",
          size = 1.2,             
          col = "black",        
          fontface = "bold",
          xmod = 1.0,
          ymod = -1.5) +
  # Base Case
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[1] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[1], lwd = 3) +
  # Siemensbahn
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[2] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[2], lwd = 3) +
  # Variant 1
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[3] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[3], lwd = 3) +
  # Variant 2
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[4] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[4], lwd = 3) +
  # All other agents (gray)
  tm_shape(base_case_score_monetized_sf) +
  tm_bubbles(col = "gray", size = 0.01, alpha = 1, border.alpha = 0) +
  # 10% richer (lilac)
  tm_shape(base_case_score_monetized_10pct_richer_sf) +
  tm_bubbles(col = "mediumpurple", size = 0.01, alpha = 1, border.alpha = 0) +
  # 10% poorer (orange)
  tm_shape(base_case_score_monetized_10pct_poorer_sf) +
  tm_bubbles(col = "darkorange", size = 0.01, alpha = 1, border.alpha = 0) +
  # Title
  tm_layout(title = "Socioeconomical Distribution: 10% poorer (orange) and 10% richer (lilac)")

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

base_case_mean_trav_distance <- base_case_pt_trips %>% 
  group_by(person) %>% 
  summarise(trav_distance_person = sum(traveled_distance)) %>% 
  summarise(mean_trav_distance_person = mean(trav_distance_person) / 1000)

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

siba_total_score_delimited_region <- persons_siba %>% 
  filter(person %in% persons_delimited_region) %>%
  summarise(total_score = sum(executed_score))

# Total Score for DNG-Agents
siba_total_score_dng <- persons_siba %>% 
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

siba_total_score_dng_delimited_region <- persons_siba %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for Berlin-Agents
siba_total_score_berlin <- persons_siba %>% 
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

siba_total_score_berlin_delimited_region <- persons_siba %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for BB-Agents
siba_total_score_bb <- persons_siba %>% 
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

siba_total_score_bb_delimited_region <- persons_siba %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score Results
siba_total_score_results <- data.frame(
  Scenario = "Siemensbahn",
  'Total Score' = as.numeric(siba_total_score),
  'Total Score DNG-Agents' = as.numeric(siba_total_score_dng),
  'Total Score Berlin-Agents' = as.numeric(siba_total_score_berlin),
  'Total Score BB-Agents' =  as.numeric(siba_total_score_bb),
  'Total Score - Delimited Region' = as.numeric(siba_total_score_delimited_region),
  'Total Score DNG-Agents - Delimited Region' = as.numeric(siba_total_score_dng_delimited_region),
  'Total Score Berlin-Agents - Delimited Region' = as.numeric(siba_total_score_berlin_delimited_region),
  'Total Score BB-Agents - Delimited Region' =  as.numeric(siba_total_score_bb_delimited_region),
  check.names = FALSE)

# Monetized score for agents with trips starting or ending within the Delimited Region
siba_score_monetized <- persons_siba %>%
  filter(person %in% persons_delimited_region) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_total_score_monetized <- siba_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# 10% Poorer and 10% Richer
siba_total_score_monetized_10pct_poorer <- siba_score_monetized %>%
  filter(person %in% cutoff_10pct_poorer_list) %>% 
  summarise(total_score_monetized_10pct_poorer = sum(score_monetized)) * 10 # (* sample upscale factor 10)

siba_total_score_monetized_10pct_richer <- siba_score_monetized %>%
  filter(person %in% cutoff_10pct_richer_list) %>% 
  summarise(total_score_monetized_10pct_richer = sum(score_monetized)) * 10 # (* sample upscale factor 10)

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

siba_mean_trav_distance <- siba_pt_trips %>% 
  group_by(person) %>% 
  summarise(trav_distance_person = sum(traveled_distance)) %>% 
  summarise(mean_trav_distance_person = mean(trav_distance_person) / 1000)

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

siba_v1_total_score_delimited_region <- persons_siba_v1 %>% 
  filter(person %in% persons_delimited_region) %>%
  summarise(total_score = sum(executed_score))

# Total Score for DNG-Agents
siba_v1_total_score_dng <- persons_siba_v1 %>% 
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

siba_v1_total_score_dng_delimited_region <- persons_siba_v1 %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for Berlin-Agents
siba_v1_total_score_berlin <- persons_siba_v1 %>% 
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

siba_v1_total_score_berlin_delimited_region <- persons_siba_v1 %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for BB-Agents
siba_v1_total_score_bb <- persons_siba_v1 %>% 
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

siba_v1_total_score_bb_delimited_region <- persons_siba_v1 %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score Results
siba_v1_total_score_results <- data.frame(
  Scenario = "Siemensbahn+v1",
  'Total Score' = as.numeric(siba_v1_total_score),
  'Total Score DNG-Agents' = as.numeric(siba_v1_total_score_dng),
  'Total Score Berlin-Agents' = as.numeric(siba_v1_total_score_berlin),
  'Total Score BB-Agents' =  as.numeric(siba_v1_total_score_bb),
  'Total Score - Delimited Region' = as.numeric(siba_v1_total_score_delimited_region),
  'Total Score DNG-Agents - Delimited Region' = as.numeric(siba_v1_total_score_dng_delimited_region),
  'Total Score Berlin-Agents - Delimited Region' = as.numeric(siba_v1_total_score_berlin_delimited_region),
  'Total Score BB-Agents - Delimited Region' =  as.numeric(siba_v1_total_score_bb_delimited_region),
  check.names = FALSE)

# Monetized score for agents with trips starting or ending within the Delimited Region
siba_v1_score_monetized <- persons_siba_v1 %>%
  filter(person %in% persons_delimited_region) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_v1_total_score_monetized <- siba_v1_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# 10% Poorer and 10% Richer
siba_v1_total_score_monetized_10pct_poorer <- siba_v1_score_monetized %>%
  filter(person %in% cutoff_10pct_poorer_list) %>% 
  summarise(total_score_monetized_10pct_poorer = sum(score_monetized)) * 10 # (* sample upscale factor 10)

siba_v1_total_score_monetized_10pct_richer <- siba_v1_score_monetized %>%
  filter(person %in% cutoff_10pct_richer_list) %>% 
  summarise(total_score_monetized_10pct_richer = sum(score_monetized)) * 10 # (* sample upscale factor 10)

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

siba_v1_mean_trav_distance <- siba_v1_pt_trips %>% 
  group_by(person) %>% 
  summarise(trav_distance_person = sum(traveled_distance)) %>% 
  summarise(mean_trav_distance_person = mean(trav_distance_person) / 1000)

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

siba_v2_total_score_delimited_region <- persons_siba_v2 %>% 
  filter(person %in% persons_delimited_region) %>%
  summarise(total_score = sum(executed_score))

# Total Score for DNG-Agents
siba_v2_total_score_dng <- persons_siba_v2 %>% 
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

siba_v2_total_score_dng_delimited_region <- persons_siba_v2 %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^dng.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for Berlin-Agents
siba_v2_total_score_berlin <- persons_siba_v2 %>% 
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

siba_v2_total_score_berlin_delimited_region <- persons_siba_v2 %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^berlin.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score for BB-Agents
siba_v2_total_score_bb <- persons_siba_v2 %>% 
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

siba_v2_total_score_bb_delimited_region <- persons_siba_v2 %>% 
  filter(person %in% persons_delimited_region) %>%
  filter(grepl("^bb.+", person)) %>%
  summarise(total_score = sum(executed_score))

# Total Score Results
siba_v2_total_score_results <- data.frame(
  Scenario = "Siemensbahn+v2",
  'Total Score' = as.numeric(siba_v2_total_score),
  'Total Score DNG-Agents' = as.numeric(siba_v2_total_score_dng),
  'Total Score Berlin-Agents' = as.numeric(siba_v2_total_score_berlin),
  'Total Score BB-Agents' =  as.numeric(siba_v2_total_score_bb),
  'Total Score - Delimited Region' = as.numeric(siba_v2_total_score_delimited_region),
  'Total Score DNG-Agents - Delimited Region' = as.numeric(siba_v2_total_score_dng_delimited_region),
  'Total Score Berlin-Agents - Delimited Region' = as.numeric(siba_v2_total_score_berlin_delimited_region),
  'Total Score BB-Agents - Delimited Region' =  as.numeric(siba_v2_total_score_bb_delimited_region),
  check.names = FALSE)

# Monetized score for agents with trips starting or ending within the Delimited Region
siba_v2_score_monetized <- persons_siba_v2 %>%
  filter(person %in% persons_delimited_region) %>%
  filter(!is.na(income)) %>% 
  mutate(marginal_utility_of_money = average_income$average_income / income) %>%
  mutate(score_monetized = executed_score / marginal_utility_of_money)

siba_v2_total_score_monetized <- siba_v2_score_monetized %>% 
  summarise(total_score_monetized = sum(score_monetized)) * 10 # (* sample upscale factor 10)

# 10% Poorer and 10% Richer
siba_v2_total_score_monetized_10pct_poorer <- siba_v2_score_monetized %>%
  filter(person %in% cutoff_10pct_poorer_list) %>% 
  summarise(total_score_monetized_10pct_poorer = sum(score_monetized)) * 10 # (* sample upscale factor 10)

siba_v2_total_score_monetized_10pct_richer <- siba_v2_score_monetized %>%
  filter(person %in% cutoff_10pct_richer_list) %>% 
  summarise(total_score_monetized_10pct_richer = sum(score_monetized)) * 10 # (* sample upscale factor 10)

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

siba_v2_mean_trav_distance <- siba_v2_pt_trips %>% 
  group_by(person) %>% 
  summarise(trav_distance_person = sum(traveled_distance)) %>% 
  summarise(mean_trav_distance_person = mean(trav_distance_person) / 1000)

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
  base_case_total_score_results, 
  siba_total_score_results,
  siba_v1_total_score_results,
  siba_v2_total_score_results
)

write_xlsx(total_score_results_binded, "total_score_results_binded-analysis_Siemensbahn.xlsx")

### Comparison ###

## Travel Time ##

# Agents remaining in pt

# [Siemensbahn] vs [Base Case] - Total travel time in pt for remaining pt users in [Siemensbahn] in [hours]
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

# [Siemensbahn+v1] vs [Base Case] - Total travel time in pt for remaining pt users in [Siemensbahn+v1] in [hours]
siba_v1_base_case_remaining_pt <- base_case_pt_trips %>% 
  inner_join(siba_v1_pt_trips, by=c("person", "trip_id"), suffix=c(".base_case", ".siba_v1")) %>% 
  select(person,trip_id,trav_time.base_case,wait_time.base_case,traveled_distance.base_case,main_mode.base_case,trav_time.siba_v1,wait_time.siba_v1,traveled_distance.siba_v1,main_mode.siba_v1)

siba_v1_base_case_total_trav_time_remaining_pt <- siba_v1_base_case_remaining_pt %>%   
  group_by(person) %>%
  summarise(
    trav_time.base_case = sum(trav_time.base_case, na.rm = TRUE),
    wait_time.base_case = sum(wait_time.base_case, na.rm = TRUE),
    person_trav_time.base_case = trav_time.base_case + wait_time.base_case,
    trav_time.siba_v1 = sum(trav_time.siba_v1, na.rm = TRUE),
    wait_time.siba_v1 = sum(wait_time.siba_v1, na.rm = TRUE),
    person_trav_time.siba_v1 = trav_time.siba_v1 + wait_time.siba_v1) %>% 
  summarise(total_pt_trav_time.base_case = sum(person_trav_time.base_case) * 10 / 3600,
            total_pt_trav_time.siba_v1 = sum(person_trav_time.siba_v1) * 10 / 3600) # (results may show [secs], but it's [hours]!!)
                                                                                    # (* sample upscale factor 10)

# [Siemensbahn+v2] vs [Base Case] - Total travel time in pt for remaining pt users in [Siemensbahn+v2] in [hours]
siba_v2_base_case_remaining_pt <- base_case_pt_trips %>% 
  inner_join(siba_v2_pt_trips, by=c("person", "trip_id"), suffix=c(".base_case", ".siba_v2")) %>% 
  select(person,trip_id,trav_time.base_case,wait_time.base_case,traveled_distance.base_case,main_mode.base_case,trav_time.siba_v2,wait_time.siba_v2,traveled_distance.siba_v2,main_mode.siba_v2)

siba_v2_base_case_total_trav_time_remaining_pt <- siba_v2_base_case_remaining_pt %>%   
  group_by(person) %>%
  summarise(
    trav_time.base_case = sum(trav_time.base_case, na.rm = TRUE),
    wait_time.base_case = sum(wait_time.base_case, na.rm = TRUE),
    person_trav_time.base_case = trav_time.base_case + wait_time.base_case,
    trav_time.siba_v2 = sum(trav_time.siba_v2, na.rm = TRUE),
    wait_time.siba_v2 = sum(wait_time.siba_v2, na.rm = TRUE),
    person_trav_time.siba_v2 = trav_time.siba_v2 + wait_time.siba_v2) %>% 
  summarise(total_pt_trav_time.base_case = sum(person_trav_time.base_case) * 10 / 3600,
            total_pt_trav_time.siba_v2 = sum(person_trav_time.siba_v2) * 10 / 3600) # (results may show [secs], but it's [hours]!!)
                                                                                    # (* sample upscale factor 10)

# Agents switching to pt

# [Siemensbahn] vs [Base Case] - Total travel time for former car users in [Base Case] in pt in [Siemensbahn] in [hours]
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

# [Siemensbahn+v1] vs [Base Case] - Total travel time for former car users in [Base Case] in pt in [Siemensbahn+v1] in [hours]
siba_v1_base_case_switching_pt <- base_case_car_trips %>% 
  inner_join(siba_v1_pt_trips, by=c("person", "trip_id"), suffix=c(".base_case", ".siba_v1")) %>% 
  select(person,trip_id,trav_time.base_case,wait_time.base_case,traveled_distance.base_case,main_mode.base_case,trav_time.siba_v1,wait_time.siba_v1,traveled_distance.siba_v1,main_mode.siba_v1)

siba_v1_base_case_switching_pt_list <- unique(siba_v1_base_case_switching_pt$person)

siba_v1_base_case_total_trav_time_switching_pt <- siba_v1_base_case_switching_pt %>%   
  group_by(person) %>%
  summarise(
    trav_time.base_case = sum(trav_time.base_case, na.rm = TRUE),
    wait_time.base_case = sum(wait_time.base_case, na.rm = TRUE),
    person_trav_time.base_case = trav_time.base_case + wait_time.base_case,
    trav_time.siba_v1 = sum(trav_time.siba_v1, na.rm = TRUE),
    wait_time.siba_v1 = sum(wait_time.siba_v1, na.rm = TRUE),
    person_trav_time.siba_v1 = trav_time.siba_v1 + wait_time.siba_v1) %>% 
  summarise(total_car_trav_time.base_case = sum(person_trav_time.base_case) * 10 / 3600,
            total_pt_trav_time.siba_v1 = sum(person_trav_time.siba_v1) * 10 / 3600) # (results may show [secs], but it's [hours]!!)
                                                                                    # (* sample upscale factor 10)

# [Siemensbahn+v2] vs [Base Case] - Total travel time for former car users in [Base Case] in pt in [Siemensbahn+v2] in [hours]
siba_v2_base_case_switching_pt <- base_case_car_trips %>% 
  inner_join(siba_v2_pt_trips, by=c("person", "trip_id"), suffix=c(".base_case", ".siba_v2")) %>% 
  select(person,trip_id,trav_time.base_case,wait_time.base_case,traveled_distance.base_case,main_mode.base_case,trav_time.siba_v2,wait_time.siba_v2,traveled_distance.siba_v2,main_mode.siba_v2)

siba_v2_base_case_switching_pt_list <- unique(siba_v2_base_case_switching_pt$person)

siba_v2_base_case_total_trav_time_switching_pt <- siba_v2_base_case_switching_pt %>%   
  group_by(person) %>%
  summarise(
    trav_time.base_case = sum(trav_time.base_case, na.rm = TRUE),
    wait_time.base_case = sum(wait_time.base_case, na.rm = TRUE),
    person_trav_time.base_case = trav_time.base_case + wait_time.base_case,
    trav_time.siba_v2 = sum(trav_time.siba_v2, na.rm = TRUE),
    wait_time.siba_v2 = sum(wait_time.siba_v2, na.rm = TRUE),
    person_trav_time.siba_v2 = trav_time.siba_v2 + wait_time.siba_v2) %>% 
  summarise(total_car_trav_time.base_case = sum(person_trav_time.base_case) * 10 / 3600,
            total_pt_trav_time.siba_v2 = sum(person_trav_time.siba_v2) * 10 / 3600) # (results may show [secs], but it's [hours]!!)
                                                                                    # (* sample upscale factor 10)

# Agents switching to pt from other modes

# [Siemensbahn] vs [Base Case] - Total travel time for non-car and non-pt users in [Base Case] in pt in [Siemensbahn] in [hours]
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

# [Siemensbahn+v1] vs [Base Case] - Total travel time for non-car and non-pt users in [Base Case] in pt in [Siemensbahn+v1] in [hours]
siba_v1_base_case_switching_pt_from_other_modes <- base_case_other_modes_trips %>% 
  inner_join(siba_v1_pt_trips, by=c("person", "trip_id"), suffix=c(".base_case", ".siba_v1")) %>% 
  select(person,trip_id,trav_time.base_case,wait_time.base_case,traveled_distance.base_case,main_mode.base_case,trav_time.siba_v1,wait_time.siba_v1,traveled_distance.siba_v1,main_mode.siba_v1)

siba_v1_base_case_switching_pt_from_other_modes_list <- unique(siba_v1_base_case_switching_pt_from_other_modes$person)

siba_v1_base_case_total_trav_time_switching_pt_from_other_modes <- siba_v1_base_case_switching_pt_from_other_modes %>%   
  group_by(person) %>%
  summarise(
    trav_time.base_case = sum(trav_time.base_case, na.rm = TRUE),
    wait_time.base_case = sum(wait_time.base_case, na.rm = TRUE),
    person_trav_time.base_case = trav_time.base_case + wait_time.base_case,
    trav_time.siba_v1 = sum(trav_time.siba_v1, na.rm = TRUE),
    wait_time.siba_v1 = sum(wait_time.siba_v1, na.rm = TRUE),
    person_trav_time.siba_v1 = trav_time.siba_v1 + wait_time.siba_v1) %>% 
  summarise(total_other_modes_trav_time.base_case = sum(person_trav_time.base_case) * 10 / 3600,
            total_pt_trav_time.siba_v1 = sum(person_trav_time.siba_v1) * 10 / 3600) # (results may show [secs], but it's [hours]!!)
                                                                                    # (* sample upscale factor 10)

# [Siemensbahn+v2] vs [Base Case] - Total travel time for non-car and non-pt users in [Base Case] in pt in [Siemensbahn+v2] in [hours]
siba_v2_base_case_switching_pt_from_other_modes <- base_case_other_modes_trips %>% 
  inner_join(siba_v2_pt_trips, by=c("person", "trip_id"), suffix=c(".base_case", ".siba_v2")) %>% 
  select(person,trip_id,trav_time.base_case,wait_time.base_case,traveled_distance.base_case,main_mode.base_case,trav_time.siba_v2,wait_time.siba_v2,traveled_distance.siba_v2,main_mode.siba_v2)

siba_v2_base_case_switching_pt_from_other_modes_list <- unique(siba_v2_base_case_switching_pt_from_other_modes$person)

siba_v2_base_case_total_trav_time_switching_pt_from_other_modes <- siba_v2_base_case_switching_pt_from_other_modes %>%   
  group_by(person) %>%
  summarise(
    trav_time.base_case = sum(trav_time.base_case, na.rm = TRUE),
    wait_time.base_case = sum(wait_time.base_case, na.rm = TRUE),
    person_trav_time.base_case = trav_time.base_case + wait_time.base_case,
    trav_time.siba_v2 = sum(trav_time.siba_v2, na.rm = TRUE),
    wait_time.siba_v2 = sum(wait_time.siba_v2, na.rm = TRUE),
    person_trav_time.siba_v2 = trav_time.siba_v2 + wait_time.siba_v2) %>% 
  summarise(total_other_modes_trav_time.base_case = sum(person_trav_time.base_case) * 10 / 3600,
            total_pt_trav_time.siba_v2 = sum(person_trav_time.siba_v2) * 10 / 3600) # (results may show [secs], but it's [hours]!!)
                                                                                    # (* sample upscale factor 10)

## Transfers ##

# Agents remaining in pt

# [Siemensbahn] vs [Base Case] - Total transfers in pt for remaining pt users in [Siemensbahn] in [unit]
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

# [Siemensbahn+v1] vs [Base Case] - Total transfers in pt for remaining pt users in [Siemensbahn+v1] in [unit]
siba_v1_base_case_transfers_remaining_pt <- base_case_pt_trips %>% 
  inner_join(siba_v1_pt_trips, by=c("trip_id"), suffix=c(".base_case", ".siba_v1")) %>% 
  select(trip_id,modes.base_case,modes.siba_v1) %>%
  mutate(
    num_transfers.base_case = map_int(modes.base_case, count_transfers),
    num_transfers.siba_v1 = map_int(modes.siba_v1, count_transfers))

siba_v1_base_case_total_transfers_remaining_pt <- siba_v1_base_case_transfers_remaining_pt %>% 
  summarise(
    total_transfers.base_case = sum(num_transfers.base_case, na.rm = TRUE) * 10,
    total_transfers.siba_v1 = sum(num_transfers.siba_v1, na.rm = TRUE) * 10 ) # (* sample upscale factor 10)

# [Siemensbahn+v2] vs [Base Case] - Total transfers in pt for remaining pt users in [Siemensbahn+v2] in [unit]
siba_v2_base_case_transfers_remaining_pt <- base_case_pt_trips %>% 
  inner_join(siba_v2_pt_trips, by=c("trip_id"), suffix=c(".base_case", ".siba_v2")) %>% 
  select(trip_id,modes.base_case,modes.siba_v2) %>%
  mutate(
    num_transfers.base_case = map_int(modes.base_case, count_transfers),
    num_transfers.siba_v2 = map_int(modes.siba_v2, count_transfers))

siba_v2_base_case_total_transfers_remaining_pt <- siba_v2_base_case_transfers_remaining_pt %>% 
  summarise(
    total_transfers.base_case = sum(num_transfers.base_case, na.rm = TRUE) * 10,
    total_transfers.siba_v2 = sum(num_transfers.siba_v2, na.rm = TRUE) * 10 ) # (* sample upscale factor 10)

# Agents switching to pt

# [Siemensbahn] vs [Base Case] - Total transfers for former car users in [Base Case] in pt in [Siemensbahn] in [unit]
siba_base_case_transfers_switching_pt <- base_case_car_trips %>% 
  inner_join(siba_transfers, by=c("trip_id"), suffix=c(".base_case", ".siba")) %>% 
  select(trip_id,modes.base_case,modes.siba) %>%
  mutate(num_transfers.siba = map_int(modes.siba, count_transfers))

siba_base_case_total_transfers_switching_pt <- siba_base_case_transfers_switching_pt %>% 
  summarise(total_transfers.siba = sum(num_transfers.siba, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# [Siemensbahn+v1] vs [Base Case] - Total transfers for former car users in [Base Case] in pt in [Siemensbahn+v1] in [unit]
siba_v1_base_case_transfers_switching_pt <- base_case_car_trips %>% 
  inner_join(siba_v1_transfers, by=c("trip_id"), suffix=c(".base_case", ".siba_v1")) %>% 
  select(trip_id,modes.base_case,modes.siba_v1) %>%
  mutate(num_transfers.siba_v1 = map_int(modes.siba_v1, count_transfers))

siba_v1_base_case_total_transfers_switching_pt <- siba_v1_base_case_transfers_switching_pt %>% 
  summarise(total_transfers.siba_v1 = sum(num_transfers.siba_v1, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# [Siemensbahn+v2] vs [Base Case] - Total transfers for former car users in [Base Case] in pt in [Siemensbahn+v2] in [unit]
siba_v2_base_case_transfers_switching_pt <- base_case_car_trips %>% 
  inner_join(siba_v2_transfers, by=c("trip_id"), suffix=c(".base_case", ".siba_v2")) %>% 
  select(trip_id,modes.base_case,modes.siba_v2) %>%
  mutate(num_transfers.siba_v2 = map_int(modes.siba_v2, count_transfers))

siba_v2_base_case_total_transfers_switching_pt <- siba_v2_base_case_transfers_switching_pt %>% 
  summarise(total_transfers.siba_v2 = sum(num_transfers.siba_v2, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# Agents switching to pt from other modes

# [Siemensbahn] vs [Base Case] - Total transfers for non-car and non-pt users in [Base Case] in pt in [Siemensbahn] in [unit]
siba_base_case_transfers_switching_pt_from_other_modes <- base_case_other_modes_trips %>% 
  inner_join(siba_transfers, by=c("trip_id"), suffix=c(".base_case", ".siba")) %>% 
  select(trip_id,modes.base_case,modes.siba) %>%
  mutate(num_transfers.siba = map_int(modes.siba, count_transfers))

siba_base_case_total_transfers_switching_pt_from_other_modes <- siba_base_case_transfers_switching_pt_from_other_modes %>% 
  summarise(total_transfers.siba = sum(num_transfers.siba, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# [Siemensbahn+v1] vs [Base Case] - Total transfers for non-car and non-pt users in [Base Case] in pt in [Siemensbahn+v1] in [unit]
siba_v1_base_case_transfers_switching_pt_from_other_modes <- base_case_other_modes_trips %>% 
  inner_join(siba_v1_transfers, by=c("trip_id"), suffix=c(".base_case", ".siba_v1")) %>% 
  select(trip_id,modes.base_case,modes.siba_v1) %>%
  mutate(num_transfers.siba_v1 = map_int(modes.siba_v1, count_transfers))

siba_v1_base_case_total_transfers_switching_pt_from_other_modes <- siba_v1_base_case_transfers_switching_pt_from_other_modes %>% 
  summarise(total_transfers.siba_v1 = sum(num_transfers.siba_v1, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

# [Siemensbahn+v2] vs [Base Case] - Total transfers for non-car and non-pt users in [Base Case] in pt in [Siemensbahn+v2] in [unit]
siba_v2_base_case_transfers_switching_pt_from_other_modes <- base_case_other_modes_trips %>% 
  inner_join(siba_v2_transfers, by=c("trip_id"), suffix=c(".base_case", ".siba_v2")) %>% 
  select(trip_id,modes.base_case,modes.siba_v2) %>%
  mutate(num_transfers.siba_v2 = map_int(modes.siba_v2, count_transfers))

siba_v2_base_case_total_transfers_switching_pt_from_other_modes <- siba_v2_base_case_transfers_switching_pt_from_other_modes %>% 
  summarise(total_transfers.siba_v2 = sum(num_transfers.siba_v2, na.rm = TRUE)) * 10 # (* sample upscale factor 10)

## Car-km ##

# Agents switching to pt

# [Siemensbahn] vs [Base Case] - Total car-km in [Base Case] for new pt-users in [Siemensbahn] in [km]
siba_base_case_former_car_km <- siba_base_case_switching_pt %>% 
  summarise(total_car_km.base_case = sum(traveled_distance.base_case) * 10 / 1000) # (* sample upscale factor 10)

# [Siemensbahn+v1] vs [Base Case] - Total car-km in [Base Case] for new pt-users in [Siemensbahn+v1] in [km]
siba_v1_base_case_former_car_km <- siba_v1_base_case_switching_pt %>% 
  summarise(total_car_km.base_case = sum(traveled_distance.base_case) * 10 / 1000) # (* sample upscale factor 10)

# [Siemensbahn+v2] vs [Base Case] - Total car-km in [Base Case] for new pt-users in [Siemensbahn+v2] in [km]
siba_v2_base_case_former_car_km <- siba_v2_base_case_switching_pt %>% 
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

## Outliers ##

siba_base_case_total_score_berlin_outliers <- persons_base_case %>% 
  full_join(persons_siba, by=c("person"), suffix=c(".base_case", ".siba")) %>% 
  filter(grepl("^berlin.+", person)) %>%
  select(person,executed_score.base_case,executed_score.siba) %>%
  mutate(score_diff = executed_score.siba - executed_score.base_case) %>% 
  filter(score_diff == max(score_diff, na.rm = TRUE) | score_diff == min(score_diff, na.rm = TRUE))

## Train Occupancy ##

# PT pax volumes
pt_pax_volumes_base_case <- read_csv("../../../../outputs-10pct/output-Base_Case-10pct/pt_pax_volumes.csv.gz", show_col_types = FALSE, progress = TRUE)
pt_pax_volumes_siba <- read_csv("../../../../outputs-10pct/output-SiBa-10pct/pt_pax_volumes.csv.gz", show_col_types = FALSE, progress = TRUE)
pt_pax_volumes_siba_v1 <- read_csv("../../../../outputs-10pct/output-SiBa+v1-10pct/pt_pax_volumes.csv.gz", show_col_types = FALSE, progress = TRUE)
pt_pax_volumes_siba_v2 <- read_csv("../../../../outputs-10pct/output-SiBa+v2-10pct/pt_pax_volumes.csv.gz", show_col_types = FALSE, progress = TRUE)

train_occupancy_pax_sibalines_base_case <- pt_pax_volumes_base_case %>% 
  filter(grepl("Base_Case", transitLine)) %>% 
  summarise(max_ridership = max(passengersAtArrival)) 

train_occupancy_pax_sibalines_siba <- pt_pax_volumes_siba %>% 
  filter(grepl("SiBa", transitLine)) %>% 
  summarise(max_ridership = max(passengersAtArrival)) 

train_occupancy_pax_sibalines_siba_v1 <- pt_pax_volumes_siba_v1 %>% 
  filter(grepl("SiBa", transitLine)) %>% 
  summarise(max_ridership = max(passengersAtArrival)) 

train_occupancy_pax_sibalines_siba_v2 <- pt_pax_volumes_siba_v2 %>% 
  filter(grepl("SiBa", transitLine)) %>% 
  summarise(max_ridership = max(passengersAtArrival)) 

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
    avg_walking_time = mean(trav_time) / 60, # Results may show secs, but it's [min]!!
    avg_walking_distance = mean(distance)
    )

pt_users_siba <- trips_siba %>% 
  filter(main_mode == "pt")

trip_id_pt_users_siba <- unique(pt_users_siba$trip_id)

walk_mode_to_pt_users_siba <- legs_siba %>% 
  filter(trip_id %in% trip_id_pt_users_siba) %>% 
  filter(mode == "walk") %>%
  filter(!grepl("^pt", start_link) & grepl("rail$|subway$|SuburbanRailway$", end_link))

walk_mode_from_pt_users_siba <- legs_siba %>% 
  filter(trip_id %in% trip_id_pt_users_siba) %>% 
  filter(mode == "walk") %>%
  filter(grepl("rail$|subway$|SuburbanRailway$", start_link) & !grepl("^pt", end_link))

walk_mode_pt_users_siba <- bind_rows(
  walk_mode_to_pt_users_siba, 
  walk_mode_from_pt_users_siba
  ) %>% 
  summarise(
    avg_walking_time = mean(trav_time) / 60, # Results may show secs, but it's [min]!!
    avg_walking_distance = mean(distance)
    )

# SiBa Users in comparison to persons_delimited_region
pax_sibalines_base_case <- legs_base_case %>% 
  filter(grepl("Base_Case", transit_line))

pax_sibalines_base_case_persons <- unique(pax_sibalines_base_case$person)

pax_sibalines_siba <- legs_siba %>% 
  filter(grepl("SiBa", transit_line))

pax_sibalines_siba_persons <- unique(pax_sibalines_siba$person)

pax_sibalines_siba_v1 <- legs_siba_v1 %>% 
  filter(grepl("SiBa", transit_line))

pax_sibalines_siba_v1_persons <- unique(pax_sibalines_siba_v1$person)

pax_sibalines_siba_v2 <- legs_siba_v2 %>% 
  filter(grepl("SiBa", transit_line))

pax_sibalines_siba_v2_persons <- unique(pax_sibalines_siba_v2$person)

match_percentage <- function(char_list, reference_list) {
  char_vector <- unlist(char_list)
  ref_vector <- unlist(reference_list)
  
  matches <- sum(char_vector %in% ref_vector)
  percentage <- (matches / length(char_vector)) * 100
  return(round(percentage, 2))
}

percentages <- c(
  pax_sibalines_base_case_persons = match_percentage(pax_sibalines_base_case_persons, persons_delimited_region),
  pax_sibalines_siba_persons = match_percentage(pax_sibalines_siba_persons, persons_delimited_region),
  pax_sibalines_siba_v1_persons = match_percentage(pax_sibalines_siba_v1_persons, persons_delimited_region),
  pax_sibalines_siba_v2_persons = match_percentage(pax_sibalines_siba_v2_persons, persons_delimited_region)
)

print(percentages)

# Map with all agents

tmap_mode("view")

tm_shape(delimited_region_shp) + 
  tm_polygons(alpha = 0.3, col = "lightgreen") +
  tm_text("OTEIL",
          size = 1.2,             
          col = "black",        
          fontface = "bold",
          xmod = 1.0,
          ymod = -1.5) +
  # Base Case
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[1] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[1], lwd = 3) +
  # Siemensbahn
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[2] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[2], lwd = 3) +
  # Variant 1
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[3] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[3], lwd = 3) +
  # Variant 2
  tm_shape(siemensbahn_kml[siemensbahn_kml$Name == track_names[4] & st_geometry_type(siemensbahn_kml) == "LINESTRING", ]) +
  tm_lines(col = colors[4], lwd = 3) +
  # All agents
  tm_shape(base_case_score_monetized_sf) +
  tm_bubbles(col = "gray40", size = 0.005, alpha = 1, border.alpha = 0) +
  # Title
  tm_layout(title = "Agents Distribution")
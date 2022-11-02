# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# author: anna zanchetta
# name: trials.R
# aim: reproduce the code from https://github.com/creds2/CarbonCalculator/blob/master/R/prep_travel_to_work.R
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

library(sf)
library(stplanr)
library(dplyr)
library(tmap)         # map making (see Chapter 9)
library(ggplot2)      # data visualization package
library(sfnetworks)
library(tidyverse)

# A. Defining constants and importing input variables in R ----
OD_file_path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/Data/land_use/wu03ew_v2/wu03ew_v2.csv"

OD <- read.csv(OD_file_path)
View(OD)
colnames(OD)
# [1] "Area.of.residence"                       
# [2] "Area.of.workplace"                       
# [3] "All.categories..Method.of.travel.to.work"
# [4] "Work.mainly.at.or.from.home"             
# [5] "Underground..metro..light.rail..tram"    
# [6] "Train"                                   
# [7] "Bus..minibus.or.coach"                   
# [8] "Taxi"                                    
# [9] "Motorcycle..scooter.or.moped"            
# [10] "Driving.a.car.or.van"                    
# [11] "Passenger.in.a.car.or.van"               
# [12] "Bicycle"                                 
# [13] "On.foot"                                 
# [14] "Other.method.of.travel.to.work"
od <- OD[,c("Area.of.residence","Area.of.workplace",names(OD)[grepl("All.categories..Method.of.travel.to.work",names(OD))])]
# 2402201 obs.
names(od) <- gsub("_All.categories..Method.of.travel.to.work",
                  "",
                  names(od))

od<- OD
names(od)<- c("Origin","Destination", "individuals", "home", "u-m-l-t", "train", "bus", "taxi", "moto", "car", "passenger", "bike", "foot", "other")

length(unique(od$Origin))
length(unique(od$Destination))

MSOAcentroids_file_path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/Data/GeoSpatial/Middle_layer_Super_Output_Areas_(December_2011)_Population_Weighted_Centroids"
centroids <- read_sf(MSOAcentroids_file_path)
plot(centroids)

tynewear_MSOAs_filename <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/projects/LandUse/TyneWear_MSOAs_list.csv"


n_of_trips_daily <- 1.9 # number of commuting trips per person a day (from ...)
n_of_days_with_trips_yearly <- 220 # number of working days per year per person (from ...)

emission_factors_file <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/projects/LandUseDemonstrator/data/CO2_conversion_factors_list.csv"

emission_factors <- read.csv(emission_factors_file)

output_file_path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/projects/LandUseDemonstrator/output/"

# B. Actual work -----
## First cleaning up of the data ----
#  generate list of MSOAs for using later (only codes df)
centroids_list <- centroids[,"msoa11cd"] #centroids$msoa11cd #centroids[,"msoa11cd"]
#  generate list of the codes
centroids_codes <- centroids$msoa11cd
length(unique(centroids_codes)) # 7201

# which MSOAs are in od that are not in th e MSOAs list (centroids):
setdiff(od$Destination, centroids_codes) # "N92000002" "OD0000001" "OD0000002" "OD0000003" "OD0000004" "S92000003"

# selecting from OD flows only MSOA actually contained in the centroids file
# note: the file contains only England and Wales
od_sel_from <- od[od$Origin %in% centroids_codes,]
# length(unique(od_sel_from$Origin))
# length(unique(od_sel_from$Destination))
od_sel_to <- od_sel_from[od_sel_from$Destination %in% centroids_codes,]
# can we find a more elegant way of doing this?
# length(unique(od_sel_from$MSOA_to)) # 7207

# Select MSOAs for Tyne and Wear from the OD table
MSOAs_tyneawear_lut <- read.csv(tynewear_MSOAs_filename) # 145 obs
MSOAs_tinewear_list <- unique(MSOAs_tyneawear_lut$MSOA11CD)

od_tynewear <- od_sel_to %>%
  filter(Origin %in% MSOAs_tinewear_list & Destination %in% MSOAs_tinewear_list)

od_intra = filter(od_tynewear, Origin == Destination)
od_inter = filter(od_tynewear, Origin != Destination)

# Generating the o-d lines between centroids
od_line <- od2line(od_tynewear, centroids_list)
od_line_inter <- od2line(od_inter, centroids_list)

# plotting
qtm(od_line, lines.lwd = c("individuals", "bike", "car", "bus", "u-m-l-t", "train"))
plot(od_line_inter)


# calculating distance between centroids
# st_length : Compute Euclidian or great circle distance between pairs of geometries
od_line$dist_km <- round(as.numeric(st_length(od_line)) / 1000,
                         0)

# per each Origin MSOA, calculate the tot of individuals and tot of km per mode
# first drop the 'geometry' column from the sd object (https://r-spatial.github.io/sf/reference/st_geometry.html)
# or it'd enter in all the subsequent calculations (where it is not relevant anymore)
od_df <- od_line
st_geometry(od_df) <- NULL

write.csv(od_df,
          paste0(output_file_path, "OD_full_withKM_tynewear.csv"))

grouped_msoas <- od_df %>%
  group_by(Origin) %>%
  summarize(across(where(is.numeric), sum)) # summing up per each mode of transport the n. of individuals
write.csv(grouped_msoas,
          paste0(output_file_path, "OD_grouped_withKM_tynewear.csv"))


# checking that the number of individuals equals the sum of individuals per mode of transport:
# check <- setdiff(rowSums(grouped_msoas[ , c(3:13)]), grouped_msoas$individuals)
# check <- rowSums(grouped_msoas[ , c(3:13)]) -  grouped_msoas$individuals

# generate total km per msoas per mode of transport
msoas_with_km <- grouped_msoas %>%
  pivot_longer(home:other) %>% # generates one row per each mode of transport (long format)
  mutate(km = value*dist_km) %>% # generates a column "skm" with the results of the function applied to each considered column
  pivot_wider(values_from = c(value, km)) #%>% # returns to wide format generating new column per each mode
  # select_at(vars(-starts_with("value"))) # drop columns called "values" (they just repeat per each mode the n of individuals)
# found from here!!! https://stackoverflow.com/questions/60916841/generate-multiple-columns-of-variables-with-dplyr-and-function-in-a-vectorized

# multiplicate per number of trips and per emission factor
msoas_with_emissions_temp <- msoas_with_km %>%
  select(Origin, individuals, "km_u-m-l-t":km_car)%>%
  rename(msoa_cd = Origin)
# temporarily change column names by dropping "km" so we can use the look up table below
colnames(msoas_with_emissions_temp) <- gsub("km_","", colnames(msoas_with_emissions_temp)) 
# getting back to track
msoas_with_emissions_long <- msoas_with_emissions_temp %>%
  pivot_longer("u-m-l-t":car)
  
msoas_with_emissions_factor <- merge(msoas_with_emissions_long,
                                          emission_factors,
                                          by.x="name",
                                          by.y="mode")

msoas_with_emissions_long <- msoas_with_emissions_factor %>%
  mutate(emissions = case_when(
    unit=="passenger.km" ~ round(kgCO2perunit * individuals,0),
    unit=="km" ~ round(kgCO2perunit * value,0))) %>% # multiplying per number of people or per km depending on emis factor
  select(-c("unit","kgCO2perunit")) #%>% #  drop "unit" and "kgCO2perunit"

msoas_with_emissions_wide <- msoas_with_emissions_long %>%
  select(-value) %>%
  pivot_wider(values_from = emissions) %>%
  mutate(tot_emis = rowSums(across("bus":"u-m-l-t")))

write.csv2(msoas_with_emissions_wide,
          paste0(output_file_path, "emissions_commuting_msoas_tynewear.csv"))


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# original from carbuncalculator:
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

od <- od[,c("Area of usual residence","Area of Workplace",names(od)[grepl("AllSexes_Age16Plus",names(od))])]
names(od) <- gsub("_AllSexes_Age16Plus","",names(od))
names(od)[1:2] <- c("LSOA_from","LSOA_to")


cents <- cents[,"lsoa11cd"]
#  scot = ????   --> not used anywhere else in the project
scot <- scot[substr(scot$geo_code,1,1) == "S",]
scot <- st_centroid(scot)

# Note commuters outside England and Wales are excluded
od <- od[od$LSOA_from %in% cents$lsoa11cd,]
od <- od[od$LSOA_to %in% cents$lsoa11cd,]

# distance to work
od_line <- od2line(od, cents)
od_line$dist_km <- as.numeric(st_length(od_line)) / 1000
od_line$dist_km <- od_line$dist_km * 1.2 # average circuity was estimated around 1.2 (Newell, 1980)

od_line$km_Underground <- od_line$Underground * od_line$dist_km * 220 * 1.9 # DFT assumed commuting trips per year
od_line$km_Train <- od_line$Train * od_line$dist_km * 220 * 1.9 
od_line$km_Bus <- od_line$Bus * od_line$dist_km * 220 * 1.9 
od_line$km_Taxi <- od_line$Taxi * od_line$dist_km * 220 * 1.9 
od_line$km_Motorcycle <- od_line$Motorcycle * od_line$dist_km * 220 * 1.9 
od_line$km_CarOrVan <- od_line$CarOrVan * od_line$dist_km * 220 * 1.9 
od_line$km_Passenger <- od_line$Passenger * od_line$dist_km * 220 * 1.9 
od_line$km_Bicycle <- od_line$Bicycle * od_line$dist_km * 220 * 1.9 
od_line$km_OnFoot <- od_line$OnFoot * od_line$dist_km * 220 * 1.9
od_line$km_OtherMethod <- od_line$OtherMethod * od_line$dist_km * 220 * 1.9 

# DEFRA 2020 emissions factors for business travel
od_line$kgco2e_Underground <- od_line$km_Underground * 0.0275
od_line$kgco2e_Train <- od_line$km_Train * 0.03694
od_line$kgco2e_Bus <- od_line$km_Bus * 0.10312
od_line$kgco2e_Taxi <- od_line$km_Taxi * 0.20369
od_line$kgco2e_Motorcycle <- od_line$km_Motorcycle * 0.11337
od_line$kgco2e_CarOrVan <- od_line$km_CarOrVan * 0.16844  # could use local data
od_line$kgco2e_OtherMethod <- od_line$km_OtherMethod  * 0.16844

od_summary <- od_line %>%
  st_drop_geometry() %>%
  select(-LSOA_to) %>%
  group_by(LSOA_from) %>%
  summarise_all(sum)

#Suppress 0-3
od_summary$AllMethods[od_summary$AllMethods < 3] <- 0
od_summary$WorkAtHome[od_summary$WorkAtHome < 3] <- 0
od_summary$Underground[od_summary$Underground < 3] <- 0
od_summary$Train[od_summary$Train < 3] <- 0
od_summary$Bus[od_summary$Bus < 3] <- 0
od_summary$Taxi[od_summary$Taxi < 3] <- 0
od_summary$Motorcycle[od_summary$Motorcycle < 3] <- 0
od_summary$CarOrVan[od_summary$CarOrVan < 3] <- 0
od_summary$Passenger[od_summary$Passenger < 3] <- 0
od_summary$Bicycle[od_summary$Bicycle < 3] <- 0
od_summary$OnFoot[od_summary$OnFoot < 3] <- 0
od_summary$OtherMethod[od_summary$OtherMethod < 3] <- 0

saveRDS(od_summary,"data-prepared/travel2work_total_km_emissions.Rds")

od_line$AllMethods[od_line$AllMethods < 3] <- 0
od_line$WorkAtHome[od_line$WorkAtHome < 3] <- 0
od_line$Underground[od_line$Underground < 3] <- 0
od_line$Train[od_line$Train < 3] <- 0
od_line$Bus[od_line$Bus < 3] <- 0
od_line$Taxi[od_line$Taxi < 3] <- 0
od_line$Motorcycle[od_line$Motorcycle < 3] <- 0
od_line$CarOrVan[od_line$CarOrVan < 3] <- 0
od_line$Passenger[od_line$Passenger < 3] <- 0
od_line$Bicycle[od_line$Bicycle < 3] <- 0
od_line$OnFoot[od_line$OnFoot < 3] <- 0
od_line$OtherMethod[od_line$OtherMethod < 3] <- 0

nrow(od_line) #7615856
od_line <- od_line[od_line$AllMethods > 0,]
nrow(od_line) #1765485

od_line <- st_transform(od_line, 4326)

# Round data
od_line[] <- lapply(od_line[], function(x){
  if(is.numeric(x)){
    x <- signif(x, digits = 3)
  }
  x
})

write_sf(od_line,"data-prepared/travel2work_lines_suppressed2.geojson", delete_dsn = TRUE)
write_sf(od_line[od_line$AllMethods >= 10,],"data-prepared/travel2work_lines_suppressed_morethan10.geojson", delete_dsn = TRUE)

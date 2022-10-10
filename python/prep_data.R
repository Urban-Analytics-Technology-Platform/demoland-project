# Prep Data
library(sf)
library(dplyr)

source("R/secure_path.R")


# the data is separated in "just" data (then electric, gas, travel2work-school [PCT], wards)
# and "data_prepared" where I assum he dumps all the files generated in the several "prep_" files
# TO_DO: check for example gas and electricity...? are they prepared or not? we have a "prep_gas_elec" file

elec <- readRDS("data/electric/elec_total_2010_2019.Rds")
gas <- readRDS("data/gas/gas_total_2010_2019.Rds")

cars_km <- readRDS("data-prepared/car_van_km_09_18.Rds")
cars_emissions <- readRDS("data-prepared/car_historical_emissions.Rds")
population <- readRDS("data-prepared/LSOA_population_2011_2019.Rds")
flights <- readRDS("data-prepared/flight_emissions.Rds")
flights$pop_2018 <- NULL

lsoa_classif <- read.csv(paste0(substr(secure_path,1,39),"OA Bounadries/GB_OA_LSOA_MSOA_LAD_Classifications_2017.csv"))

# mot <- read.csv(paste0(secure_path,"/Tim Share/From Tim/MOT Data RACv9.3/MOT Data RACv9.3 LSOAoutputs_2011.csv"), stringsAsFactors = FALSE)
age <- readRDS("../Excess-Data-Exploration/data-prepared/age.Rds") # Not full UK
#census <- readRDS("../Excess-Data-Exploration/data-prepared/census_lsoa.Rds") # Not full UK
#names(census) <- gsub("[.]","",names(census))


school <- readRDS("data/travel2school.Rds")
t2wpct <- readRDS("data/travel2workPCT.Rds")
btype <- readRDS("data/building type/building_type.Rds")
t2w_trip <- readRDS("data/travel2workcenus.Rds")
wards <- readRDS("data/wards.Rds")

lsoa_classif <- lsoa_classif[,c("LSOA11CD","LSOA11NM","SOAC11NM","LAD17CD","LAD17NM")]
lsoa_classif <- lsoa_classif[!duplicated(lsoa_classif$LSOA11CD),]

age <- age[, c("lsoa","BP_PRE_1900","BP_1900_1918","BP_1919_1929",
                                          "BP_1930_1939","BP_1945_1954","BP_1955_1964",
                                          "BP_1965_1972","BP_1973_1982","BP_1983_1992",
                                          "BP_1993_1999","BP_2000_2009","BP_2010_2015",
                                          "BP_UNKNOWN")]
names(age) <- c("lsoa","pP1900","p1900_18","p1919_29",
                "p1930_39","p1945_54","p1955_64","p1965_72","p1973_82",
                "p1983_92","p1993_99","p2000_09","p2010_15","pUNKNOWN")

non_gas <- readRDS("data-prepared/non_gaselec_emissions.Rds")


heating <- readRDS("../Excess-Data-Exploration/data-prepared/central_heating.Rds") # Not full UK

heating$pHeating_None <- heating$`No CH`
heating$pHeating_Gas <- heating$Gas
heating$pHeating_Electric <- heating$Electric
heating$pHeating_Oil <- heating$Oil
heating$pHeating_Solid <- heating$`Solid fuel`
heating$pHeating_Other <- (heating$`Two or more` + heating$Other)

heating <- heating[,c("LSOA11","pHeating_None","pHeating_Gas","pHeating_Electric","pHeating_Oil","pHeating_Solid","pHeating_Other")]

# census$All_Dwelllings_2011 <- rowSums(census[,c("Whole_House_Detached","Whole_House_Semi",
#                                                 "Whole_House_Terraced","Flat_PurposeBuilt",
#                                                 "Flat_Converted","Flat_Commercial","Caravan")], 
#                                       na.rm = TRUE)
# census <- census[,c("CODE","Whole_House_Detached","Whole_House_Semi","Whole_House_Terraced","Flat_PurposeBuilt",
#                     "Flat_Converted","Flat_Commercial","Caravan",
#                     "T2W_Car","T2W_Cycle","T2W_Bus","T2W_Train","T2W_Foot")]

epc <- readRDS("../../creds2/EPC/epc_lsoa_summary.Rds")
epc <- epc[!is.na(epc$LSOA11),]
epc <- epc[substr(epc$LSOA11,1,1) == "E",]

epc <- epc[,c("LSOA11","epc_total","epc_newbuild",
              "epc_A","epc_B","epc_C","epc_D","epc_E","epc_F","epc_G",
              "epc_score_avg",
              "type_house_semi","type_house_midterrace","type_house_endterrace",
              "type_house_detached","type_flat","type_bungalow_semi","type_bungalow_midterrace",
              "type_bungalow_endterrace","type_bungalow_detached","type_maisonette","type_parkhome",
              "type_other","floor_area_avg","low_energy_light",
              "floor_verygood","floor_good","floor_average","floor_poor","floor_verypoor","floor_other","floor_below",
              "window_verygood","window_good","window_average","window_poor","window_verypoor","window_other",
              "wall_verygood","wall_good","wall_average","wall_poor","wall_verypoor","wall_other",
              "roof_verygood","roof_good","roof_average","roof_poor","roof_verypoor","roof_other","roof_above",
              "mainheat_verygood","mainheat_good","mainheat_average","mainheat_poor","mainheat_verypoor","mainheat_other",
              "mainheatdesc_gasboiler","mainheatdesc_oilboiler","mainheatdesc_storageheater",
              "mainheatdesc_portableheater","mainheatdesc_roomheater","mainheatdesc_heatpump",
              "mainheatdesc_community","mainheatdesc_other",
              "mainfuel_mainsgas","mainfuel_electric","mainfuel_oil","mainfuel_coal","mainfuel_lpg","mainfuel_biomass",
              "mainheatcontrol_verygood","mainheatcontrol_good","mainheatcontrol_average",
              "mainheatcontrol_poor","mainheatcontrol_verypoor","mainheatcontrol_other",
              "has_solarpv","has_solarthermal")]

epc$type_bungalow <- rowSums(epc[,c("type_bungalow_midterrace",
                                    "type_bungalow_endterrace",
                                    "type_bungalow_detached",
                                    "type_bungalow_semi")], na.rm = TRUE)

epc$type_bungalow_midterrace <- NULL
epc$type_bungalow_endterrace <- NULL
epc$type_bungalow_detached <- NULL
epc$type_bungalow_semi <- NULL

t2w <- readRDS("data-prepared/travel2work_total_km_emissions.Rds")
t2w <- t2w[,c("LSOA_from","km_Underground",
              "km_Train","km_Bus","km_Taxi","km_Motorcycle","km_CarOrVan",
              "km_Passenger","km_Bicycle","km_OnFoot","km_OtherMethod","kgco2e_Underground",
              "kgco2e_Train","kgco2e_Bus","kgco2e_Taxi","kgco2e_Motorcycle","kgco2e_CarOrVan",
              "kgco2e_OtherMethod")]
t2w$kgco2e_commute_noncar_total <- t2w$kgco2e_Underground +
  t2w$kgco2e_Train +
  t2w$kgco2e_Bus +
  t2w$kgco2e_Motorcycle +
  t2w$kgco2e_OtherMethod

t2w <- t2w[,c("LSOA_from","km_Underground",
              "km_Train","km_Bus","km_Taxi","km_Motorcycle","km_CarOrVan",
              "km_Passenger","km_Bicycle","km_OnFoot","km_OtherMethod",
              "kgco2e_commute_noncar_total")]

consumption <- readRDS("data-prepared/consumption_footprint.Rds")


# Join Togther
all <- left_join(elec, gas, by = "LSOA11")
all <- left_join(all, age, by = c("LSOA11" = "lsoa"))
#all <- left_join(all, census, by = c("LSOA11" = "CODE"))
all <- left_join(all, btype, by = c("LSOA11" = "LSOA11"))
all <- left_join(all, t2w_trip, by = c("LSOA11" = "LSOA11"))
all <- left_join(all, school, by = c("LSOA11" = "geo_code"))
all <- left_join(all, t2wpct, by = c("LSOA11" = "geo_code"))
all <- left_join(all, wards, by = c("LSOA11" = "LSOA11"))

all <- left_join(all, heating, by = c("LSOA11" = "LSOA11"))
all <- left_join(all, population, by = c("LSOA11" = "code"))

all <- left_join(all, cars_emissions, by = c("LSOA11" = "LSOA"))
all <- left_join(all, cars_km, by = c("LSOA11" = "LSOA11"))
all <- left_join(all, non_gas, by = c("LSOA11" = "LSOA11"))
all <- left_join(all, flights, by = c("LSOA11" = "LSOA11"))
all <- left_join(all, lsoa_classif, by = c("LSOA11" = "LSOA11CD"))

all <- left_join(all, epc, by = c("LSOA11" = "LSOA11"))
all <- left_join(all, t2w, by = c("LSOA11" = "LSOA_from"))
all <- left_join(all, consumption, by = c("LSOA11" = "LSOA11"))

all <- all[substr(all$LSOA11,1,1) == "E",]

all$kgco2e_commute_noncar_percap <- all$kgco2e_commute_noncar_total / all$pop_2018
all$kgco2e_commute_noncar_total <- NULL


rm(elec, gas, age, heating, population, school, cars_emissions, 
   cars_km, non_gas, flights, lsoa_classif, epc, t2w, consumption,
   btype, t2w_trip, t2wpct, wards)

saveRDS(all,"data/base_data_v6.Rds")


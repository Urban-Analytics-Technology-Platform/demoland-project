# Travel to work data
library(sf)
library(stplanr)
library(dplyr)


# Reading FLOW DATA - OD matrix

dir.create("tmp")
unzip("D:/OneDrive - University of Leeds/Data/LSOA Flow Data/Public/WM12EW[CT0489]_lsoa.zip",
      exdir = "tmp")
od <- readr::read_csv("tmp/WM12EW[CT0489]_lsoa.csv")
unlink("tmp", recursive = TRUE)

dir.create("tmp")
unzip("D:/OneDrive - University of Leeds/Data/OA Bounadries/EW_LSOA_2011_Centroids.zip",
      exdir = "tmp")
cents <- read_sf("tmp/Lower_Layer_Super_Output_Areas__December_2011__Population_Weighted_Centroids.shp")
unlink("tmp", recursive = TRUE)

# Selecting specific fields from OD data
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

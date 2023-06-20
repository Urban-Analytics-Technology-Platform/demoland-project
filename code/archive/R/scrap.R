
# scrapping data after running trials.R start


colnames(MSOAs_tyneawear_lut)

short_list <- MSOAs_tyneawear_lut %>%
  select(LAD20CD, LAD20NM) %>%
  distinct()
write.csv(short_list,
          "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/projects/LandUseDemonstrator/data/TyneWear_LADs_list.csv")

library(dplyr)

# 
# uploading lsoa centroids to select only tynewear list
lsoas_centroids_all <- read.csv("/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/Data/GeoSpatial/LLSOA_(Dec_2021)_PWC_for_England_and_Wales.csv")
# select only centroids for tynewear
tynewear_lsoas_list <- read.csv("/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/projects/LandUseDemonstrator/data/tynewear_lsoas_list.csv")
tynewear_lsoas_codes <- unique(tynewear_lsoas_list$LSOA.code)
lsoas_centroids_tynewear <- lsoas_centroids_all %>%
  filter(LSOA21CD %in% tynewear_lsoas_codes)
write.csv(lsoas_centroids_tynewear,
          "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/projects/LandUseDemonstrator/data/tynewear_lsoas_centroids.csv")

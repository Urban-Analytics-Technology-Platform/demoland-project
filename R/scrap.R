
# scrapping data after running trials.R start


colnames(MSOAs_tyneawear_lut)

short_list <- MSOAs_tyneawear_lut %>%
  select(LAD20CD, LAD20NM) %>%
  distinct()
write.csv(short_list,
          "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/projects/LandUseDemonstrator/data/TyneWear_LADs_list.csv")

# gas

library(tidyr)

dir.create("tmp")
unzip("data/gas/LSOA_Gas_csv.zip",
      exdir = "tmp")

gas <- list()
gas_files <- list.files("tmp/LSOA Gas csv", pattern = ".csv",
                        full.names = TRUE)

for(i in 1:length(gas_files)){
  sub <- read.csv(gas_files[i])
  sub <- sub[,c("Lower.Layer.Super.Output.Area..LSOA..Code",
                "Consumption..kWh.")]
  sub$year <- i + 9
  gas[[i]] <- sub
}

unlink("tmp", recursive = TRUE)

gas <- dplyr::bind_rows(gas)
names(gas) <- c("LSOA11","gas_total_kwh","year")
gas <- pivot_wider(gas, names_from = "year", values_from = "gas_total_kwh")
names(gas)[2:11] <- paste0("TotDomGas_", names(gas)[2:11],"_kWh")

saveRDS(gas,"data/gas/gas_total_2010_2019.Rds")


dir.create("tmp")
unzip("data/electric/LSOA_Elec_csv.zip",
      exdir = "tmp")

elec <- list()
elec_files <- list.files("tmp/LSOA csv", pattern = ".csv",
                        full.names = TRUE)

for(i in 1:length(elec_files)){
  sub <- read.csv(elec_files[i])
  sub <- sub[,c("Lower.Layer.Super.Output.Area..LSOA..Code",
                "Total.domestic.electricity.consumption..kWh.")]
  sub$year <- i + 9
  elec[[i]] <- sub
}

unlink("tmp", recursive = TRUE)

elec <- dplyr::bind_rows(elec)
names(elec) <- c("LSOA11","elec_total_kwh","year")
elec <- pivot_wider(elec, names_from = "year", values_from = "elec_total_kwh")
names(elec)[2:11] <- paste0("TotDomElec_", names(elec)[2:11],"_kWh")

saveRDS(elec,"data/electric/elec_total_2010_2019.Rds")


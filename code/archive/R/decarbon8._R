library(sf)
library(dplyr)
library(tmap)
library(tidyr)
library(ggplot2)
tmap_mode("view")
all <- all[,c("LSOA11","cars_percap_2010","cars_percap_2011",
              "cars_percap_2012","cars_percap_2013","cars_percap_2014",
              "cars_percap_2015",
              "cars_percap_2016","cars_percap_2017","cars_percap_2018")]

summary(all)

all$change <- (all$cars_percap_2018 - all$cars_percap_2010)/ all$cars_percap_2018
summary(all$change)

dir.create("tmp")
unzip("data/bounds/England_lsoa_2011_sgen_clipped.zip", exdir = "tmp")
bounds_super_gen  <- st_read("tmp/england_lsoa_2011_sgen_clipped.shp")
unlink("tmp", recursive = TRUE)

all <- left_join(bounds_super_gen, all, by = c("code" = "LSOA11"))
all$foo <- 1
qtm(all, fill = "change")

sub <- all[all$change < 0,]
sub <- sub[sub$cars_percap_2010 < 4,]

tm_shape(sub) +
  tm_fill(col = "change",
          style = "fisher",
          palette = "-viridis")


bar <- all %>%
  group_by(foo) %>%
  summarise(cars_percap_2010 = median(cars_percap_2010, na.rm = TRUE),
            cars_percap_2011 = median(cars_percap_2011, na.rm = TRUE),
            cars_percap_2012 = median(cars_percap_2012, na.rm = TRUE),
            cars_percap_2013 = median(cars_percap_2013, na.rm = TRUE),
            cars_percap_2014 = median(cars_percap_2014, na.rm = TRUE),
            cars_percap_2015 = median(cars_percap_2015, na.rm = TRUE),
            cars_percap_2016 = median(cars_percap_2016, na.rm = TRUE),
            cars_percap_2017 = median(cars_percap_2017, na.rm = TRUE),
            cars_percap_2018 = median(cars_percap_2018, na.rm = TRUE),
            
            )

bar <- st_drop_geometry(bar)
bar$name <- "England"
bar <- pivot_longer(bar, starts_with("cars_percap_"), names_to = "year")

foo <- all[all$name %in% c("Stockton-on-Tees 014C","Bradford 046D","Harrogate 018A"),]
foo <- st_drop_geometry(foo)
foo <- pivot_longer(foo, starts_with("cars_percap_"), names_to = "year")

fizz <- rbind(bar[,c("name","year","value")],foo[,c("name","year","value")])
fizz$year <- as.numeric(gsub("cars_percap_","", fizz$year))


ggplot(fizz, aes(x = year, y = value, color = name)) +
  geom_line() +
  ylab("Cars per person")


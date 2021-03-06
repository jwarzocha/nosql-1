library(dplyr)
library(readr)

# Update URL from

# http://www.faa.gov/licenses_certificates/aircraft_certification/aircraft_registry/releasable_aircraft_download/
# src <- "http://registry.faa.gov/database/AR062014.zip"

# https://www.faa.gov/licenses_certificates/aircraft_certification/aircraft_registry/releasable_aircraft_download/
src <- "http://registry.faa.gov/database/ReleasableAircraft.zip"
lcl <- "data-raw/planes"

if (!file.exists(lcl)) {
  tmp <- tempfile(fileext = ".zip")
  # tmp <- "~/tmp/ReleasableAircraft.zip"
  download.file(url = src, destfile = tmp, method = "wget") # libcurl does not work

  dir.create(lcl)
  unzip(tmp, exdir = lcl, junkpaths = TRUE)
}

master <- read.csv("data-raw/planes/MASTER.txt", stringsAsFactors = FALSE, strip.white = TRUE)
names(master) <- tolower(names(master))

keep <- master %>%
  tbl_df() %>%
  select(nnum = n.number, code = mfr.mdl.code, year = year.mfr)

ref <- read.csv("data-raw/planes/ACFTREF.txt", stringsAsFactors = FALSE, strip.white = TRUE)
names(ref) <- tolower(names(ref))

ref <- ref %>%
  tbl_df() %>%
  select(code, mfr, model, type.acft, type.eng, no.eng, no.seats, speed)

# Combine together

all <- keep %>%
  inner_join(ref) %>%
  select(-code)
all$speed[all$speed == 0] <- NA
all$no.eng[all$no.eng == 0] <- NA
all$no.seats[all$no.seats == 0] <- NA

engine <- c("None", "Reciprocating", "Turbo-prop", "Turbo-shaft", "Turbo-jet",
  "Turbo-fan", "Ramjet", "2 Cycle", "4 Cycle", "Unknown", "Electric", "Rotary")
all$engine <- engine[all$type.eng + 1]
all$type.eng <- NULL

acft <- c("Glider", "Balloon", "Blimp/Dirigible", "Fixed wing single engine",
  "Fixed wing multi engine", "Rotorcraft", "Weight-shift-control",
  "Powered Parachute", "Gyroplane")
all$type <- acft[all$type.acft]
all$type.acft <- NULL

all$tailnum <- paste0("N", all$nnum)

# load("data/flights.rda")
load("data/flights-2014.rda")
load("data/nycflights14.rda")

# Relational Data
#   http://r4ds.had.co.nz/relational-data.html#nycflights13-relational

planes <- all %>%
  select(
    tailnum, year, type, manufacturer = mfr, model = model,
    engines = no.eng, seats = no.seats, speed, engine
  ) %>%
  semi_join(flights, "tailnum") %>%
  arrange(tailnum)

write.csv(planes, gzfile("data-raw/planes.csv.gz"), row.names = FALSE, quote = FALSE, na = "")
save(planes, file = "data/planes.rda")

planes14 <- all %>%
  select(
    tailnum, year, type, manufacturer = mfr, model = model,
    engines = no.eng, seats = no.seats, speed, engine
  ) %>%
  semi_join(flights14, "tailnum") %>%
  arrange(tailnum)

write.csv(planes, gzfile("data-raw/planes14.csv.gz"), row.names = FALSE, quote = FALSE, na = "")
save(planes, file = "data/planes14.rda")

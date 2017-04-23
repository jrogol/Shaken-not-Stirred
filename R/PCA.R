source("R/PostgresFunctions.R")
library(RPostgreSQL)

#### Load in the Data ####

# Connect to the "bond" database
con <- connectDB("bond")

# Get the film names, in order!
film.names <- dbGetQuery(con,
                         "WITH x AS(SELECT film, yr
                         FROM films
                         ORDER BY yr)
                         SELECT film from x")

# The Spotify data
bond <- dbGetQuery(con,
                   "WITH x AS (
                     SELECT s.album_id, track_name, s.track_id, film, actor
                     FROM songs s JOIN films f ON s.album_id = f.album_id)
                   SELECT track_id, acousticness, danceability, duration_ms, energy,
                   instrumentalness, key, liveness, loudness, mode, speechiness, tempo,
                   time_signature, valence, track_name, film, actor
                   FROM tracks t JOIN x ON t.id = x.track_id;")

# Data on the keys - yes, we could've done this in SQL, but...
keys <- dbGetQuery(con,
                   "SELECT * from keys")


disconnectDB(con)

#### Data Cleaning ####

library(dplyr)
# Turn actor, film into factor variables
bond$actor <- as.factor(bond$actor)
bond$film <- factor(bond$film, levels= film.names$film)

# Keys are inherently circular, and not linear, so create a radial variable
# There are 12 keys so:
angle <- 2*pi/(12+1)
# Taking the cosine of the angle times the integer "key" will create a circular variable!

# Join the human-readable key names
bond.clean <- bond %>%
  # Join the two data frames
  inner_join(keys, by = c("key" = "Pitch class")) %>%
  # Rename Tonal counterparts (for ease of use)
  rename(key.name = `Tonal counterparts`) %>%
  # Create a human-readable mode feature
  mutate(mode.name = factor(bond$mode, labels = c("minor", "major")),
         # Create the radial "key" value
         key.circle = cos(angle*bond$key)) %>%
  # Create a human-readable key name
  mutate(full.key = paste(key.name, mode.name))
  

#### Principle Component Analysis ####
library(dplyr)

# Create a dataframe of the actors
bond.actor <- bond.clean %>%
  select(-track_id,-track_name,-film,-full.key, -mode.name,-key.name, -key)

# Do the same for the films
bond.film <- bond.clean %>%
  select(-track_id,-track_name,-actor,-full.key, -mode.name,-key.name, -key)



## Perform PCA
pr.out = prcomp(bond.actor %>% select(-actor), scale = TRUE)

## means and standard deviations used for scaling prior to PCA
pr.out$center # This is the mean for each variable, what as needed to center the data
pr.out$scale # the standard deviation - used in scaling (as the divisor)

## Provides PC loadings.  Each column contains the corresponding PC loading vector:
pr.out$rotation

## x holds the PC scores.  Here we check the dimensions of x:
dim(pr.out$x)

## Make biplot to look at scores and loadings:
biplot(pr.out,scale=0)

pr.var = pr.out$sdev^2
pve = pr.var/sum(pr.var)
plot(pve, xlab="Principal Component", ylab = "Proportion of Variance Explained", ylim=c(0,1), type='b')
plot(cumsum(pve),xlab = "Principal Component", ylab = "Cumulative Proportion of Variance Explained", ylim = c(0,1), type='b')



library(ggplot2)
library(ggfortify)
autoplot(prcomp(actor %>% select(-actor), scale = TRUE),
         data = bond.clean, shape = "actor",
         colour = "film",
         loadings = T, loadings.colour = 'black', loadings.label = T) +
  scale_shape_discrete(name = "Actor",
                       breaks = c("Sean Connery",
                                  "George Lazenby",
                                  "Roger Moore",
                                  "Pierce Brosnan",
                                  "Daniel Craig"),
                       labels = c("Connery",
                                  "Lazenby",
                                  "Moore",
                                  "Brosnan",
                                  "Craig"))

quickplot(1:length(pve), pve, geom = 'line')

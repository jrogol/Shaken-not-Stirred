source("R/PostgresFunctions.R")
library(RPostgreSQL)
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
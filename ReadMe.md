# Audio Analysis of James Bond Soundtracks
### SYS 6016 (Machine Learning) Final Project

## Project Description
With 24 movies (and counting) in the James Bond franchise, this project
 hypothesized that the films' soundtracks contained auditory markers which could
 potentially identify which actor portrayed Bond.


## Data
Data was collected and processed with help from the following sources:
* [Spotify API](https://developer.spotify.com)
* [Spotipy](https://github.com/plamere/spotipy)
  * Python library for the Spotify api
* [Internet Movie Database](http://www.imdb.com)
* [Wikipedia's List of Bond Films](https://en.wikipedia.org/wiki/List_of_James_Bond_films)
* [Wikipedia's List of Pitch Classes](https://en.wikipedia.org/wiki/Pitch_class)
* [PostgreSQL](https://www.postgresql.org/)
* [Psycopg2](http://initd.org/psycopg/docs/index.html)
  * Python library integrating PostgreSQL

## Workflow
Data was collected in Python, and then processed in R
* Python
  * keys.py - Not included in the repository. Stores values for 'client_ID',
    'client_secret' and 'oauth_token' required to access the Spotify API.
  * films_scrape.py - Fetches the list of films from Wikipedia and
    should be called first.
  * Album_IDs.py - Inserts the album_id into the database, and should be called
    second.
  * GetTracks.py - Inserts data for both Albums and individual tracks into the
    database. Must be run after above scripts.
  * PitchClass.py - May be called at anytime before processing in R
* R
  * Analysis.R - Calls all other necessary R scripts.
  * Packages Used:
    * RPostgreSQL
    * caret (and its dependencies)
    * klaR (for Kernel-based Naive Bayes Classification)
    * ggplot2
    * ggfortify
    * dplyr

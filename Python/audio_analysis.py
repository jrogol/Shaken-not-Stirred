from pandas.io import sql
import pandas as pd
from sqlalchemy import create_engine
import spotipy as s
from spotipy.oauth2 import SpotifyClientCredentials

from keys import client_ID,client_secret,oauth_token


client_credentials_manager = SpotifyClientCredentials(client_id=client_ID, client_secret=client_secret)
spotify = s.Spotify(client_credentials_manager=client_credentials_manager)

# Establish link to the database
engine = create_engine('postgresql://jamesrogol@localhost:5432/bond')

tracks = sql.read_sql("SELECT track_id FROM songs;",engine)
tid = tracks['track_id'][0]

analysis = spotify.audio_analysis(tid)

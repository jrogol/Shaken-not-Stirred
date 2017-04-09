import json
import psycopg2
import spotipy
import sys
import pandas as pd
sys.path.append('..')
from keys import *

conn = psycopg2.connect("dbname = 'XX' user=%s host=%s password=%s" % ("user", "localhost", "password"))


sp = spotipy.Spotify()

creds = spotipy.oauth2.SpotifyClientCredentials(client_id=client_ID,client_secret=client_secret)
sp = spotipy.Spotify(client_credentials_manager=creds)
sp.trace = True

for i in tracks['items']: print(i['id'])

TIDs = ['0fRLtGUlY9ZPzIjaCoGe7k',
'52N7Mm7y2UEoE2y1mH89PF',
'0WNTRoFmy3pZ9awsHyQLWc',
'4r2As71NXqQZjvjOLIEbhI',
'6bTFBxBNhiRxLLibE5fSai']
features = sp.audio_features(tracks=TIDs)
features

pd.DataFrame.from_dict(features)

from sqlalchemy import create_engine
engine = create_engine("postgresql+psycopg2://user:password@host:port/dbname[?key=value&key=value...]")
df.to_sql('table_name', engine,if_exists='append',index_label='id')

# This is the album ID
SID = '5yTx83u3qerZF7GRJu7eFk'
urn = 'spotify:album:' + SID

# This is a dictionary
album = sp.album(urn)


name = album['name']
tracks = album['tracks']
temp = tracks['items'][1]

# track duration in milliseconds
temp['duration_ms']
# track ID
temp['id']
temp['name']
temp['track_number']

# Artist name, the numeral is the artist
temp['artists'][0]['name']


import pandas as pd

pd_tracks = pd.DataFrame.from_dict(tracks['items'])

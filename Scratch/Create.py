''' This Script Grabs the most recent top 200 global tracks from Spotify'''

import pandas as pd
from io import StringIO
import requests
import re

import spotipy as s
from spotipy.oauth2 import SpotifyClientCredentials

from keys import client_ID,client_secret,oauth_token

# Spotify Handlers
client_credentials_manager = SpotifyClientCredentials(client_id=client_ID, client_secret=client_secret)
spotify = s.Spotify(client_credentials_manager=client_credentials_manager)

# Download the most recent chart to a dataframe and parse the sond IDs
url="https://spotifycharts.com/regional/global/daily/latest/download"
content = requests.get(url).content
data = pd.read_csv(StringIO(content.decode('utf-8')))
ids = [re.sub('https://open.spotify.com/track/','',x) for x in data.URL]

# Need to query at most 50 tracks. Results are concatenated
chunks = [ids[50*i:50*(i+1)] for i in range(round(len(ids)/50) + 1)]
out = map(lambda x: spotify.audio_features(x),chunks)
out2 = list(out)
dfs = [pd.DataFrame(chunk) for chunk in out2]
df = pd.concat(dfs)
df.drop(['analysis_url', 'track_href', 'type','uri'],1,inplace=True)

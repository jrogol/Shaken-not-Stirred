import json

data = open('../Samples/album_tracks.json').read()
d = json.loads(data)

d['items'][0]['artists'][0]['name']

tracks = [track['name'] for track in d['items']]
duration = [track['duration_ms'] for track in d['items']]
artists = [artist['name'] for track in d['items'] for artist in track['artists']]
artists = [ for track in [track['artists'] for track in d['items']]]


x = [track['artists'] for track in d['items']]
for track in x:
    print([artist['name'] for artist in track])

y

import pandas as pd
from pandas.io.json import json_normalize
pd.read_json(data, orient="index")
json_normalize(d['items'])
data

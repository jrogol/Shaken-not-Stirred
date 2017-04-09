import json
import pandas as pd
import re

# Parsing album_tracks for track information and artist
data = open('../Samples/album_tracks.json').read()
d = json.loads(data)

tracks = [re.sub('[\.\'"\(\)]','',track['name']) for track in d['items']]
duration = [track['duration_ms'] for track in d['items']]
ident = [track['id'] for track in d['items']]
artist = [track['artists'][0]['name'] for track in d['items']]
artistid = [track['artists'][0]['id'] for track in d['items']]

df = pd.DataFrame({"track_name":tracks,
                    #"duration_ms":duration,
                    "track_id":ident,
                    "artist":artist,
                    "artist_id":artistid})
df

# Parsing features for multiple tracks
data = open('../Samples/features.json').read()
d = json.loads(data)

ident = [x['id'] for x in d['audio_features']]
acoustic = [x['acousticness'] for x in d['audio_features']]
dance = [x['danceability'] for x in d['audio_features']]
energy = [x['energy'] for x in d['audio_features']]
inst = [x['instrumentalness'] for x in d['audio_features']]
key = [x['key'] for x in d['audio_features']]
live = [x['liveness'] for x in d['audio_features']]
loud = [x['loudness'] for x in d['audio_features']]
mode =[x['mode'] for x in d['audio_features']]
speech = [x['speechiness'] for x in d['audio_features']]
tempo = [x['tempo'] for x in d['audio_features']]
timesig = [x['time_signature'] for x in d['audio_features']]
valence = [x['valence'] for x in d['audio_features']]
df =pd.DataFrame({'track_id':ident, 'acousticness':acoustic, 'danceability':dance,
    'energy':energy, 'instrumentalness':inst, 'key':key, 'liveness':live,
    'loudness':loud, 'mode':mode, 'speechiness':speech, 'tempo':tempo,
    'time_signature':timesig, 'valence':valence})
df

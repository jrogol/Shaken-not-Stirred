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

# Query the database for album IDs that exist
ids = sql.read_sql("SELECT DISTINCT album_id FROM films WHERE album_id != ''", engine)

# This function accepts an album ID and returns the tracks, writing them to the
# table specified by the second argument.
def getTracks(album_id, table):
        from pandas.io import sql
        import pandas as pd
        from sqlalchemy import create_engine
        import spotipy as s

        spotify = s.Spotify()

        # Establish link to the database
        engine = create_engine('postgresql://jamesrogol@localhost:5432/bond')

        d = spotify.album_tracks(album_id)

        tracks = [re.sub('[\.\'"\(\)]','',track['name']) for track in d['items']]
        duration = [track['duration_ms'] for track in d['items']]
        ident = [track['id'] for track in d['items']]
        artist = [track['artists'][0]['name'] for track in d['items']]
        artistid = [track['artists'][0]['id'] for track in d['items']]
        album = [album_id for i in range(len(tracks))]


        df1 = pd.DataFrame({"album_id":album,
                            "track_name":tracks,
                            #"duration_ms":duration,
                            "track_id":ident,
                            "artist":artist,
                            "artist_id":artistid})
        df1.to_sql(table,engine, if_exists='append')

ids['album_id'].apply(lambda x: getTracks(x,'songs'))

# Sanity Check
sql.read_sql("SELECT * FROM songs", engine)

def getSongs(song_ids, table):

    if len(song_ids) < 50:
        d = spotify.audio_features(song_ids)
        df = pd.DataFrame(d).drop(['analysis_url', 'track_href', 'type','uri'],1)

    else:
        # Need to query at most 50 tracks, pausing 30 seconds between.
        chunks = [song_ids[50*i:50*(i+1)] for i in range(round(len(song_ids)/50) + 1)]
        out = map(lambda x: spotify.audio_features(x),chunks)
        out2 = list(out)
        dfs = [pd.DataFrame(chunk) for chunk in out2]
        df = pd.concat(dfs)
        df.drop(['analysis_url', 'track_href', 'type','uri'],1,inplace=True)

    df.to_sql(table, engine)


# Get the list of song IDs
tracks = sql.read_sql("SELECT track_id FROM songs;",engine)

getSongs(tracks['track_id'], "tracks")

# sanity Check
sql.read_sql("SELECT * FROM tracks", engine)

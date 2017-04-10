bestOfBond

from pandas.io import sql
import pandas as pd
from sqlalchemy import create_engine
import spotipy as s

spotify = s.Spotify()

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

def getSongs(song_ids):

    if len(song_ids) < 50:
        d = spotify.audio_features(song_ids)
    else:
        # Need to query at most 50 tracks, pausing 30 seconds between.



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

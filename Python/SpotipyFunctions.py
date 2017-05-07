def getTracks(album_id, table):
        from pandas.io import sql
        import pandas as pd
        from sqlalchemy import create_engine
        import spotipy as s
        import re

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

def getSongs(song_ids, table):
    from pandas.io import sql
    import pandas as pd
    from sqlalchemy import create_engine
    import spotipy as s

    spotify = s.Spotify()

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

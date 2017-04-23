from pandas.io import sql
import pandas as pd
from sqlalchemy import create_engine
from sklearn import decomposition
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
import numpy as np

%matplotlib inline

# Establish link to the database
engine = create_engine('postgresql://jamesrogol@localhost:5432/bond')

# Get the information from the database
tracks = sql.read_sql('''WITH x AS (
            SELECT s.album_id, track_name, s.track_id, film, actor
            FROM songs s JOIN films f ON s.album_id = f.album_id)
            SELECT track_id, acousticness, danceability, duration_ms, energy,
            instrumentalness, key, liveness, loudness, mode, speechiness, tempo,
            time_signature, valence, track_name, film, actor
            FROM tracks t JOIN x ON t.id = x.track_id;''', engine)


    pca = decomposition.PCA()

data = StandardScaler().fit_transform(tracks.drop(["actor","film", "track_name", "track_id"],1))
response = tracks["actor"]

pca.fit(data)
var= pca.explained_variance_ratio_

plt.plot(var)

var1=np.cumsum(np.round(pca.explained_variance_ratio_, decimals=4)*100)
plt.plot(var1)


import sklearn.neural_network as nn

nn.MLPClassifier(solver='lbfgs')

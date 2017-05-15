import numpy as np
import pandas as pd
from pandas.io import sql
import psycopg2 as psql
from sqlalchemy import create_engine
import math

from keras.models import Sequential
from keras.layers import Dense, Dropout
from keras.wrappers.scikit_learn import KerasClassifier
from keras.utils import np_utils
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import StratifiedKFold, StratifiedShuffleSplit
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.pipeline import Pipeline
from keras.optimizers import RMSprop


# fix random seed for reproducibility
seed = 41684
# Create engine for sql queries
engine = create_engine('postgresql://jamesrogol@localhost:5432/bond')

# load dataset
bond = pd.read_sql("""WITH x AS (
                     SELECT s.album_id, track_name, s.track_id, film, actor
                     FROM songs s JOIN films f ON s.album_id = f.album_id)
                   SELECT acousticness, danceability, duration_ms, energy,
                   instrumentalness, key, liveness, loudness, mode, speechiness, tempo,
                   time_signature, valence, actor
                   FROM tracks t JOIN x ON t.id = x.track_id;""", engine)
# Convert key to a circular representation
angle = (2*np.pi)/13
bond.key = bond.key.map(lambda x: math.cos(angle*x))

# Convert Pandas DataFrame to an array
dataset = bond.values
# Separate the predictors (X) from response (Y)
X = dataset[:,:-1].astype(float)
Y = dataset[:,-1]

# encode class values as integers
encoder = LabelEncoder()
encoder.fit(Y)
numerical_Y = encoder.transform(Y)
# convert integers to dummy variables (i.e. one hot encoded)
dummy_y = np_utils.to_categorical(numerical_Y)

# Scale the inputs
scaler = StandardScaler()
scale_X = scaler.fit_transform(X)

dummy_y.shape
scale_X.shape


def baseline_model(inputs,outputs):
	# create model
	model = Sequential()
	model.add(Dense(inputs, kernel_initializer='normal', activation='relu', input_dim=inputs))
	model.add(Dense(outputs, kernel_initializer='normal', activation='sigmoid'))
	# Compile model
	model.compile(loss='categorical_crossentropy', optimizer=RMSprop(), metrics=['accuracy'])
	return model

model = baseline_model(13,6)

pred = model.evaluate(scale_X,dummy_y, batch_size=32,verbose=0)
print('Test loss:', pred[0])
print('Test accuracy:', pred[1])




estimator = KerasClassifier(build_fn=model, epochs=2, batch_size=5, verbose=1)

kfold = StratifiedKFold(n_splits=10, shuffle=True, random_state=seed)

'''h/t: http://machinelearningmastery.com/evaluate-performance-deep-learning-models-keras/'''
cvscores = []
for train, test in kfold.split(scale_X, dummy_y):
  # create model
	model = baseline_model(13,6)
	# Fit the model
	model.fit(scale_X[train], dummy_y[train], epochs=1, batch_size=30, verbose=1)
	# evaluate the model
	scores = model.evaluate(scale_X[test], dummy_y[test], verbose=0)
	print("%s: %.2f%%" % (model.metrics_names[1], scores[1]*100))
	cvscores.append(scores[1] * 100)
print("%.2f%% (+/- %.2f%%)" % (numpy.mean(cvscores), numpy.std(cvscores)))

def new_model(inputs,outputs):
	# create model
	model = Sequential()
	model.add(Dense(inputs, kernel_initializer='normal', activation='relu'))
    model.add(Dropout(0.2))
    model.add(Dense(inputs, kernel_initializer='normal', activation='relu'))
    model.add(Dropout(0.2))
	model.add(Dense(outputs, kernel_initializer='normal', activation='softmax'))
	# Compile model
	model.compile(loss='categorical_crossentropy', optimizer=RMSprop(), metrics=['accuracy'])
	return model

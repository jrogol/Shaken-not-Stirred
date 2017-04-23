''' Spotify's API returns the key of the song as an integer. This integer
    corresponds with the standard "Pitch Class." This script obtains the lists
    of classes from Wikipedia, cleans them and inserts them into the postgresql
    database.'''

import urllib.request as url
import pandas as pd
import psycopg2
import re


# Get table from Wikipedia
wiki = "https://en.wikipedia.org/wiki/Pitch_class"
## Find tables on the page, through pandas
table = pd.read_html(wiki, match = "Pitch class", header = 0)[0]

# sanity check
table

## Clean the data
# reduce Pitch Class to integers
table['Pitch class'] = table['Pitch class'].str.extract('([0-9]+)', expand = False).astype('int')

# Remove the parentheses, strip white space
table['Tonal counterparts'] = table['Tonal counterparts'].str.replace('\(.+\)','').str.strip()

# sanity Check
table


## Insert into postgresql database
from pandas.io import sql
from sqlalchemy import create_engine

# Establish link to the database
engine = create_engine('postgresql://jamesrogol@localhost:5432/bond')

table.to_sql("keys",engine, if_exists='replace', index = False)

# sanity Check
pd.read_sql("SELECT * FROM keys", engine)

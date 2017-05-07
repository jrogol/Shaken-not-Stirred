from pandas.io import sql
import psycopg2 as psql
import pandas as pd
from sqlalchemy import create_engine

# List of album IDs (obtained through Spotify software by copying the link)
Dr_No = ''
FRWL = ''
Goldfinger = '2j2bpDzIPwQcbL9dapv2gV'
Thunderball = '3VEq0jeSYz3Yzh2ibaqryN'
YOLT = '70yvWorA4DzKWsS3Nvz89q'
OHMSS = '4BVd2gkQNWj30YN5P3r8Av'
Diamonds = '5Ekn0VinHi7JQTZECFC10k'
LLD = ''
MwGG = '73keMsTiKlV4N852puufnJ'
TSWLM = '5k55f89cnXdy0BikkUeBHJ'
Moonraker = '5mkRj3kQB6NW3wNLoqvnu7'
FYEO = ''
Octopussy = ''
VtaK = ''
Daylights = ''
LtK = '5V870FgJNzMTiLAGo6OMmE'
Goldeneye = '4aBVXvgB75LzBQTbKiauQN'
TND = '2UGZoHiNl2bDZyHIbaQ9Vo'
Enough = '39yJXK8vsNtRui2NQFBShp'
DAD = '1oP3qigyxt9YKSUtDx6qOm'
Casino = '4GWyNknKDbVB8Lg1IiTy5k'
Quantum = '2ahUhfrELmIHEUEiWUC1Nv'
Skyfall = '0jovLA7GjtZrj7FHpL7N2g'
spectre = '6EB2m0JP7libPTesn4kT2Z'

bestOfBond = '2lHvf04m2IO93HC7PNdkfL'

# Create a list of all the Album IDs
all_films = [Dr_No,FRWL,Goldfinger,Thunderball,YOLT,OHMSS,Diamonds,LLD,MwGG,TSWLM,Moonraker,FYEO,Octopussy,VtaK,Daylights, LtK,Goldeneye,TND,Enough,DAD,Casino,Quantum,Skyfall,spectre]

# The connection to a local database.
# A Future improvement would be to store this externally, and call it in multiple scripts
engine = create_engine('postgresql://jamesrogol@localhost:5432/bond')

# Query the PostgreSQL database for films, append all_films as the album_id
df = sql.read_sql('SELECT film FROM films ORDER BY yr;',engine).assign(album_id=all_films)
# Sanity Check!
df

# Open a connection to the database
conn = engine.connect()


# Loop over the rows of the above data frame, and update the appropriate
# information in the database
for i in range(0,len(df)):
    try:
        command = "UPDATE films SET album_id = '%s' WHERE film = '%s';"%(df.iloc[i]['album_id'],df.iloc[i]['film'])
        engine.execute(command)
    except:
        pass
# Sanity Check!
sql.read_sql('SELECT * FROM films',conn)

# disconnect
conn.close()

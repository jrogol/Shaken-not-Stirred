'''Adapted from
 https://adesquared.wordpress.com/2013/06/16/using-python-beautifulsoup-to-scrape-a-wikipedia-table/'''

from bs4 import BeautifulSoup
import urllib.request as url
import pandas as pd
import wikispanscraper
import psycopg2
wiki = "https://en.wikipedia.org/wiki/List_of_James_Bond_films"
header = {'User-Agent': 'Mozilla/5.0'} #Needed to prevent 403 error on Wikipedia
req = url.Request(wiki,headers=header)
page = url.urlopen(req)
soup = BeautifulSoup(page,"html5lib")
## Find tables on the page:
tables = soup.findAll("table", class_='wikitable')

## All tables as data frames
DF = [main(table) for table in tables]

# Tables containing the "plot" header
targets = [table for table in DF if 'plot' in [x.lower() for x in list(table)]]

# Concatenate all the films together
all_films = pd.concat(targets)

conn = psycopg2.connect(
    "dbname='bond' user=jamesrogol host=localhost")
for i in all_films.iterrows():
    cur = conn.cursor()
    command = ("INSERT INTO films(film, yr, director, writers, actor, plot) VALUES ('%s', '%s', '%s', '%s', '%s', '%s');" % (
    i[1]['Film'].replace("'", ""), i[1]['Year'], i[1]['Director'], i[1]['Screenwriter(s)'], i[1]['James Bond actor'], i[1]['Plot'].replace("'", " ")))
    cur.execute(command)
    conn.commit()
    cur.close()
conn.rollback()

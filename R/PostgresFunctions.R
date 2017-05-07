# This file contains functions to read from PostgreSQL databases

connectDB <- function(db, usr ="jamesrogol", pwd= "", hst="localhost"){
  require(RPostgreSQL)
  pg = dbDriver("PostgreSQL")
  
  # Connect to the database
  con = dbConnect(pg, user = usr,
                  password = pwd,
                  host = hst,
                  port = 5432,
                  dbname = db)
  con
}

# Simple disconnect
disconnectDB <-function(db){
  require(RPostgreSQL)
  dbDisconnect(db)
}
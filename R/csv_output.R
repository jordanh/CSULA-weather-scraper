
filenameFormat <- "output/%Y-%m_CSULA_weather_data.csv"

getOutputFilename <- function() {
  return(format(Sys.Date(), filenameFormat))
}

xformTimestampColsToStrings <- function(df) {
  newDf <- data.frame(df)
  timeCols <- sapply(df, function(x) inherits(x, "POSIXct"))
  newDf[timeCols] <- lapply(newDf[timeCols], function(x) format(x, usetz=TRUE))
  return(newDf)
}

writeDataToCsvByMonth <- function(df) {
  outputFilename <- getOutputFilename()

  isAppending <- FALSE
  if (file.exists(outputFilename)) {
    isAppending <- TRUE
  }
  
  xformedDf <- xformTimestampColsToStrings(df)
  
  write.table(xformedDf,
              file=outputFilename,
              append=isAppending,
              sep=",",
              row.names=F,
              col.names=!isAppending)
  
  return(outputFilename)
}

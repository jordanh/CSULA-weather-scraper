
filenameFormat <- "output/%Y-%m_CSULA_weather_data.csv"

getOutputFilename <- function() {
  return (format(Sys.Date(), filenameFormat))
}

writeDataToCsvByMonth <- function(df) {
  outputFileName <- getOutputFilename()

  isAppending <- FALSE
  if (file.exists(outputFileName)) {
    isAppending <- TRUE
  }
  
  write.table(df,
              file=outputFilename(),
              append=isAppending,
              sep=",",
              row.names=F,
              col.names=!isAppending)
}

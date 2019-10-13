source("./R/csv_output.R")
source("./R/fetch_data.R")

# Configuration - change these to configure the sampling duration
delayOnFailureRetrySeconds <- 1
delayBetweenSamplesMinutes <- 1

url <- 'https://www.weatherlink.com/embeddablePage/show/bdb620b1f32a4833a1e61549d46a6093/summary'
urlTimezone <- "America/Los_Angeles"

interruptableSleep = function(sleepSeconds) {
  for (i in 1:sleepSeconds) {
    Sys.sleep(1)
  }
}

while (TRUE) {
  fetchFailed <- FALSE
  
  df <- tryCatch({
    print("Fetching")
    fetchData(url, urlTimezone)
  }, error = function(error_condition) {
    print("Sample failure, will retry")
    print(error_condition)
    fetchFailed <<- TRUE
  })
  if (fetchFailed) {
    interruptableSleep(delayOnFailureRetrySeconds)
    print("Retry")
    next()
  }
  
  print("Sample success")
  outputFilename <- writeDataToCsvByMonth(df)
  print (paste("Wrote to file", outputFilename))
  
  print("Sleeping until time for next sample")
  interruptableSleep(delayBetweenSamplesMinutes * 60)
}

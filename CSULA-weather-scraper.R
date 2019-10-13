source("./R/csv_output.R")
source("./R/fetch_data.R")

url <- 'https://www.weatherlink.com/embeddablePage/show/bdb620b1f32a4833a1e61549d46a6093/summary'
urlTimezone <- "America/Los_Angeles"

while (TRUE) {
  fetchFailed <- FALSE
  df <- tryCatch({
    print("Fetching")
    fetchData(url, urlTimezone)
  }, error = function(error_condition) {
    print("Error")
    print(error_condition)
    fetchFailed <<- TRUE
  })
  if (fetchFailed) {
    Sys.sleep(1)
    print("Retry")
    next()
  }
  
  print("Writing to file")
  writeDataToCsvByMonth(df)
  
  print("Sleeping")
  Sys.sleep(10)
}

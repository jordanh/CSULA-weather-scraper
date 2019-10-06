library(RSelenium)
library(wdman)

# Global variables
defaultUrl <- 'https://www.weatherlink.com/embeddablePage/show/bdb620b1f32a4833a1e61549d46a6093/summary'
pjsDrv <- NULL
remDr <- NULL

maybeInitializeRSelenium <- function() {
  if (is.null(pjsDrv)) {
    pjsDrv <<- phantomjs(port = as.integer(4567), verbose = FALSE, check = FALSE)    
  }
  
  if (is.null(remDr)) {
    remDr <<- remoteDriver(browserName = 'phantomjs', port = as.integer(4567))
  }
  
  return(TRUE)
}

parseData <- function(htmlString) {
  htmlNodes <- read_html(htmlString)
  summaryBlockNodes <- html_nodes(
    htmlNodes, "div.summary-block table tbody tr.data-row td"
  )
  
  df <- data.frame()
  
  for (i in 1:length(summaryBlockNodes)) {
    # summaryBlockNodes are in groups of 4:
    # 1: variable name (e.g. "sensor_temp")
    # 2: current value
    # 3: daily high (e.g. "78 °F | 1:35 PM")
    # 4: daily low (e.g. "56 °F | 4:28 AM")
    if ((i %% 4) != 1) next # process the 1st of every 4th row
    
    colBaseName <- html_attr(summaryBlockNodes[i], "data-l10n-id")
    # add unit to temperature columns:
    colBaseName <- sub("temp", "temp_f", colBaseName)
    
    # current value
    value <- html_text(summaryBlockNodes[i+1])
    value <- str_extract(value, "[.0-9]+")
    df[1, colBaseName] = as.numeric(value)
    
    # daily high
    colName <- paste(colBaseName,"_high_value", sep="")
    value <- html_text(summaryBlockNodes[i+2])
    value <- str_extract(value, "[.0-9]+")
    df[1, colName] = as.numeric(value)
    
    colName <- paste(colBaseName,"_high_time", sep="")
    value <- str_extract(value, ".?.:.. (AM|PM)")
    df[1, colName] = as.numeric(value) ## TODO: make timestamp
    
    # daily low
    colName <- paste(colBaseName,"_low_value", sep="")
    value <- html_text(summaryBlockNodes[i+3])
    value <- str_extract(value, "[.0-9]+")
    df[1, colName] = as.numeric(value)
    
    colName <- paste(colBaseName,"_low_time", sep="")
    value <- str_extract(value, ".?.:.. (AM|PM)")
    df[1, colName] = as.numeric(value)
  }
  
  return (summaryBlockNodes)
}

fetchData <- function(url=defaultUrl) {
  maybeInitializeRSelenium()
  remDr$open()
  remDr$navigate(url)
  htmlString <- remDr$getPageSource()[[1]]
  data <- parseData(htmlString)
  
  return(data)
}

fetchDataCleanup <- function() {
  if (!is.null(remDr)) {
    remDr$close()
  }
  if (!is.null(pjsDrv)) {
    pjsDrv$stop()
  }
  
  return(TRUE)
}


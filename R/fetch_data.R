library(magrittr)
library(RSelenium)
library(wdman)


# Global variables
defaultUrl <- 'https://www.weatherlink.com/embeddablePage/show/bdb620b1f32a4833a1e61549d46a6093/summary'
defaultTimezone <- "America/Los_Angeles"

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

parseData <- function(htmlString, timezone) {
  htmlNodes <- read_html(htmlString)
  
  # Parse when these weather station data were last updated
  lastUpdated <- html_nodes(htmlNodes, "span#conditionsUpdated") %>%
                 html_text() %>%
                 str_match("Conditions as of: (.+)") %>%
                { .[2] } %>%  # grab 2nd elment of return value from str_match
                strptime("%I:%M %p %A, %b %d, %Y", timezone)  # parse time
  lastUpdatedDate <- as.Date(lastUpdated)
  
  # Convenience function to extract a numeric value from HTML text:
  extractNumeric <- function(text) {
    str_extract(text, "[.0-9]+") %>%
    as.numeric()
  }
  
  # Convenience function to extract a string value from HTML text:
  extractString <- function(text) { str_trim(text) }
  
  # Convenience function to detect which extractor to use based on column name:
  extractValue <- function(colName, text) {
    if (colName == "sensor_bar_trend") {
      extractString(text) 
    } else {
      extractNumeric(text)
    }
  }
  
  # Convenience function to convert a bare time to a full timestamp:
  extractTime <- function(text) {
    str_extract(text, "[^ ]?.:.. (AM|PM)") %>%
      paste(lastUpdatedDate, .) %>%
      strptime("%Y-%m-%d %I:%M %p", timezone) %>%
      as.POSIXct()
  }

  # Initialize the data frame to return
  df <- data.frame()
  df[1, "url_scraped_at"] = Sys.time()
  df[1, "sensor_values_updated_at"] = as.POSIXct(lastUpdated)
  
  # Process the scraped summary-block
  summaryBlockNodes <- html_nodes(
    htmlNodes, "div.summary-block table tbody tr.data-row td"
  )
  for (i in 1:length(summaryBlockNodes)) {
    # summaryBlockNodes are in groups of 4:
    # 1: variable name (e.g. "sensor_temp")
    # 2: current value
    # 3: daily high (e.g. "78 °F | 1:35 PM")
    # 4: daily low (e.g. "56 °F | 4:28 AM")
    if ((i %% 4) != 1) next # process the 1st of every 4th row
    
    colBaseName <- html_attr(summaryBlockNodes[i], "data-l10n-id") %>%
                   sub("temp", "temp_f", .) %>%
                   sub("barometer", "barometer_hg", .) %>%
                   sub("hum", "hum_pct", .) %>%
                   sub("wind_speed", "wind_speed_mph", .) %>%
                   sub("wind_direction", "wind_direction_deg", .)
    
    # current value
    df[1, colBaseName] <- html_text(summaryBlockNodes[i+1]) %>%
                          extractValue(colBaseName, .)
    
    # daily high
    colName <- paste(colBaseName,"_high_value", sep="")
    extractedText <- html_text(summaryBlockNodes[i+2])
    df[1, colName] <- extractValue(colName, extractedText)
    
    colName <- paste(colBaseName,"_high_time", sep="")
    df[1, colName] <- extractTime(extractedText)
    
    # daily low
    colName <- paste(colBaseName,"_low_value", sep="")
    extractedText <- html_text(summaryBlockNodes[i+3])
    df[1, colName] <- extractValue(colName, extractedText)
    
    colName <- paste(colBaseName,"_low_time", sep="")
    df[1, colName] <- extractTime(extractedText)
  }
  
  # Process the scraped wind-block
  windBlockNodes <- html_nodes(
    htmlNodes, "div.wind-block table tbody tr.data-row td"
  )
  for (i in 1:length(windBlockNodes)) {
    # windBlockNodes are also in groups of 4:
    # 1: variable name (e.g. "sensor_temp")
    # 2: 2-minute interval data
    # 3: 10-minute interval data
    # 4: blank
    if ((i %% 4) != 1) next # process the 1st of every 4th row
    
    colBaseName <- html_attr(windBlockNodes[i], "data-l10n-id") %>%
                   sub("spd", "spd_mph", .)
    
    # 2-minute interval data
    colName <- paste(colBaseName,"_2_min", sep="")
    df[1, colName] <- html_text(windBlockNodes[i+1]) %>%
                      extractValue(colName, .)
    
    # 10-minute interval data
    colName <- paste(colBaseName,"_10_min", sep="")
    df[1, colName] <- html_text(windBlockNodes[i+2]) %>%
                      extractValue(colName, .)
  }
  
  # Process the scraped rain-block
  rainBlockNodes <- html_nodes(
    htmlNodes, "div.rain-block table tbody tr.data-row td"
  )
  for (i in 1:length(rainBlockNodes)) {
    # rainBlockNodes are in groups of 7:
    # 1: variable name (e.g. "sensor_et")
    # 2: current rate
    # 3: hourly accumulation
    # 4: daily accumulation
    # 5: monthly accumulation
    # 6: yearly accumulation
    # 7: storm accumulation
    if ((i %% 7) != 1) next # process the 1st of every 7th row
    
    colBaseName <- html_attr(rainBlockNodes[i], "data-l10n-id") %>%
                   sub("rain", "rain_in", .) %>%
                   sub("sensor_et", "sensor_et_in", .)
    
    # current rate
    colName <- paste(colBaseName,"_h_rate", sep="")
    df[1, colName] <- html_text(rainBlockNodes[i+1]) %>%
                      extractValue(colBaseName, .)
    
    # hourly accumulation
    colName <- paste(colBaseName,"_hourly_accumulation", sep="")
    df[1, colName] <- html_text(rainBlockNodes[i+2]) %>%
                      extractValue(colBaseName, .)
    
    # daily accumulation
    colName <- paste(colBaseName,"_daily_accumulation", sep="")
    df[1, colName] <- html_text(rainBlockNodes[i+3]) %>%
                      extractValue(colBaseName, .)
    
    # monthly accumulation
    colName <- paste(colBaseName,"_monthly_accumulation", sep="")
    df[1, colName] <- html_text(rainBlockNodes[i+4]) %>%
                      extractValue(colBaseName, .)
    
    # yearly accumulation
    colName <- paste(colBaseName,"_yearly_accumulation", sep="")
    df[1, colName] <- html_text(rainBlockNodes[i+5]) %>%
                      extractValue(colBaseName, .)
    
    # storm accumulation
    colName <- paste(colBaseName,"_storm_accumulation", sep="")
    df[1, colName] <- html_text(rainBlockNodes[i+6]) %>%
                      extractValue(colBaseName, .)
  }
  
  return (df)
}

fetchData <- function(url=defaultUrl, timezone=defaultTimezone) {
  maybeInitializeRSelenium()
  remDr$open()
  remDr$navigate(url)
  htmlString <- remDr$getPageSource()[[1]]
  df <- parseData(htmlString, timezone)
  
  return(df)
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


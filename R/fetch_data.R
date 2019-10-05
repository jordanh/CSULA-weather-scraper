library(RSelenium)
library(wdman)

# url <- 'http://www.calstatela.edu/ecst/weather'
url <- 'https://www.weatherlink.com/embeddablePage/show/bdb620b1f32a4833a1e61549d46a6093/summary'

pjsDrv <- phantomjs(port = as.integer(4567), verbose = FALSE, check = FALSE)

remDr <- remoteDriver(browserName = 'phantomjs', port = as.integer(4567))
remDr$open()
remDr$navigate(url)
html_source <- remDr$getPageSource()
remDr$close()

pjsDrv$stop()



# CSULA-weather-scraper

Periodically scrape Cal State LA's weather station, and save these data to CSV.

## Important Note!

This is a work in progress, and is not yet complete.

## Dependencies

Open the project with RStudio. It will require the following libraries:

   * magrittr - the forward pipe operator (%>%)
   * packrat - for managing package dependencies
   * RSelenium - a framework for controling a web browser
   * rvest - for scraping the web

## Implementation Notes

The weather for CSULA is hosted at http://www.calstatela.edu/ecst/weather, however
if you download this HTML to a file, you'll see that the data isn't there. The
HTML document refers to another URL
(https://www.weatherlink.com/embeddablePage/show/bdb620b1f32a4833a1e61549d46a6093/summary)
where we can scrape the data. This R script pulls data from this URL directly.

After the data is scraped, CSV files written one month at a time. If a file
already exists, it will be appended to.


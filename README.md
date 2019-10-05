
# CSULA-weather-scraper

Periodically scrape Cal State LA's weather station, and save these data to CSV.

## Dependencies

Open the project with RStudio. It will require the following libraries:

   * packrat - for managing package dependencies
   * rvest - for scraping the web

## Implementation Notes

The weather for CSULA is hosted at http://www.calstatela.edu/ecst/weather, however
if you download this HTML to a file, you'll see that the data isn't there. The
HTML document refers to another URL
(https://www.weatherlink.com/embeddablePage/show/bdb620b1f32a4833a1e61549d46a6093/summary)
where we can scrape the data. This R script pulls data from this URL directly.

After the data is scraped, CSV files written one month at a time. If a file
already exists, it will be appended to.


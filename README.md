
# CSULA-weather-scraper

Periodically scrape Cal State LA's weather station, and save these data to CSV.

## Dependencies

### System dependencies

Install libxml:

```brew install libxml2```

### Rselenium

If when installing RSelenium packages it asks to install from source, say 'n'

### wdman

wdman needs to install all of its binary dependencies, this is done by manually
running the following R code:

```R
selenium(verbose = TRUE)
```


## Configuration

Open the [CSULA-weather-scraper.R](./CSULA-weather-scraper.R) file and edit the
following parameters:

   * `delayOnFailureRetrySeconds` - how many seconds to wait between scrape failures
   * `delayBetweenSamplesMinutes` - how many minutes to wait between successful weather samples

## Implementation Notes

### Scraping implementation

The weather for CSULA is hosted at http://www.calstatela.edu/ecst/weather, however
if you download this HTML to a file, you'll see that this webpage embeds another. The
HTML document refers to the URL
https://www.weatherlink.com/embeddablePage/show/bdb620b1f32a4833a1e61549d46a6093/summary
via an `<iframe>` tag. This file is written in Javascript, not HTML, and the weather
data cannot be scraped directly. What we do is start a "headless" browser, PhantomJS, 
instruct it to load the URL which runs the Javascript and renders the HTML. We then
scrape this resulting HTML to obtain the data.

After the data is scraped, CSV files written one month at a time into the `output/`
directory. If the CSV file already exists, it is appended to.


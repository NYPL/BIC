# Automating Overdrive Fetch and Adding Census Tract

This document summarizes the current process for collecting and sharing Overdrive checkouts stats, proposes a way to automate it, and estimates effort.

## Estimated Effort

Specific estimates are attached to work below. In summary:

1. Automate scraping: 1 developer 1-2 sprints
2. Augment with patron data and send to Redis: 1 sprint
3. Census Tract module: 1 developer 1-2 sprints
4. Add census tract data to circ_trans: 1 developer 1-2 sprints

Although 3 and 4 are a dependency for 1 and 2, it should be possible to have one developer work on 3 and 4 while another works on 1 and 2. So overall either:

* 1 developer 4-7 sprints
* 2 developers 2-4 sprints

## Proposal for Automatic Process

This is a rough sketch of a pipeline for moving Overdrive Insights data into BIC automatically.

### 1. Harvest Overdrive "Insights" data

There is no API. There is a website. A lot of the reporting controls are built with JS. In lieu of Overdrive providing a dedicated, versioned API, one would need to write a scraping app that runs a headless browser to script the interaction.

In Ruby, that would look something like:

```
require "selenium-webdriver"
options = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
driver = Selenium::WebDriver.for :firefox, options: options
driver.navigate.to 'https://marketplace.overdrive.com/Account/Login'
# etc.
```

The essential steps for harvesting the reports are:
 * Log in via https://marketplace.overdrive.com/Account/Login
 * Navigate to "Insights > Checkouts" ( https://marketplace.overdrive.com/Report/View/Checkouts )
 * For each "Format" (ideally this is a scraped list):
   * Initialize the report by `POST`ing to report URLs resembling `https://marketplace.overdrive.com/Report/View/CheckoutsDetail?chart_by=Format&checkout_origins=&ContentAccessLevels=All+access+levels&UserType=&bc=&lendingmodel=All+lending+models&websiteType=&formats=420&language=&audience=All+audiences&rating=All+ratings&subject=&date_range=specific&date_units=30&date_unit=day&date_start=05%2F01%2F2020&date_end=05%2F31%2F2020&date_unit_by=day&SummaryCeilingTotal=122290&detail_key=420&detail_label=Kindle%2520Book` (this `POST` may or may not be necessary; more investigation needed)
   * Download report data via URL
   * Store retrieval time somewhere (Redis?) so that subsequent invocation can use next logical range

See [Current Process](#current-process) for the current manual steps we're trying to emulate.

Note that it may be the case that downloadable CSV URLs can be created from Marketplace URLs by replacing "View/CheckoutsDetail" with "Export/CheckoutsDetail/CSV".

Things to consider:
 * We should strive to script this in a way that is flexible to design changes and simple to update (e.g. follow links based on link text rather than CSS selector class name)
 * We should log and monitor all issues encountered by scraper so that failures are identified quickly so they can be repaired
 * We should apply reasonable delays in between navigations to emulate human interaction
 * We should expect that even the most carefully written version of this harvester is absolutely going to break at some point in the future if Overdrive changes a critical aspect of their reporting interface.

Estimated time: 1 developer 1-2 sprints

### 2. Massage 

After each harvest, we'll have one CSV report for each queried format (13 at writing). We'll need to perform the following tranformations:
 * Add "format2" column identifying format
 * Removes line(s) matching /^CrossRefID/
 * Assemble one master CSV
 * Sort by date
 * Ensure unix line endings (downloaded reports may be DOS?)
 * Export columns "$25"|"$10"|"$21"|"$23"|"$20"|"$19"|"$17"|"$31"

Estimated time: 1 developer <1 sprint

### 3. Add patron data

For each row in the CSV:
 - Fetch patron by id from PatronService
 - Obfuscate patron id (See https://github.com/NYPL/BIC/blob/master/obfuscating-identifiers.md )
 - Compute census tract from patron address (See [Census Tracts](#census-tracts))
 - Add following data points to CSV:
   - obfuscated patron id
   - ptype
   - homelib
   - pcode3
   - zip
   - geoid (See [Census Tracts](#census-tracts))

Estimated time: 1 developer <1 sprint

Scraping, massaging, and adding patron data would likely need to be handled by a single, dedicated lambda called, for example, "OverdriveCircTransHarvester". The harvester would need to produce a stream of documents, Avro encoded against a new "OverdriveCircTrans" schema resembling the [Destination Redis Schema](#destination-redis-schema).

### 4. Funnel data into Redis

A Firehose connection would decode events off the "OverdiveCircTrans" stream, funneling the records into a new "overdrive_circ_trans" table in Redis (alongside the existing "circ_trans" table). (See [Destination Redis Schema](#destination-redis-schema).)

Estimated time: 1 developer <1 sprint

## Census Tracts

We can compute census tract for a given NYC address using [NYC Planning's Geosupport package](https://www1.nyc.gov/site/planning/data-maps/open-data/dwn-gde-home.page). [Python bindings exist](https://github.com/ishiland/python-geosupport) (See also this [article](https://medium.com/nyc-planning-digital/geosupport-%EF%B8%8Fpython-a094a2d30fbe).) as well as for [Ruby](https://github.com/jordanderson/nyc_geosupport).

One way to use this efficiently would be to create a "nyc-geocoding" package or Lambda layer, which included the geosupport binaries, the python/Ruby bindings, and a simple python invocation script with an interface like the following to print census tract ids:

```
/opt/nyc-geocoding/census-tract.rb --address1 [address1] --address2 [address2] --city [city] --state [state] --zip [zip]
```

(Note that addresses in Sierra are stored as "line1" and "line2", so would need to parse city, state, and zip out of line2 before calling.)

If deployed as a lambda Layer, the package could be attached to a lambda written in any language. Ruby lambdas could require `census-tract.rb` directly. Other languages could interact with the CLI via system calls. Note that Beanstalks can not use Layers.

Alternatively, `nyc-geocoding` could just be a git repo, pulled into Lambda/Beanstalk apps as a git submodule.

Alternatively still, one could turn `nyc-geocoding` into a local service, which any app could interact with over HTTP. A third party service likely already exists, but we'd have to be skeptical of rate limiting, cost, and efficiency. To reduce calls, we could cache recently-geocoded addresses, but we should be very cautious about TTL because census tracts do change.

Note that - if using offline geosupport - the work will have to include building a means to *update* the underlying assets as NYC Planning releases updates.

Estimated time: 1 developer 1-2 sprints

### Integration of census tracts module

The census tracts work would be used in two places:

1. The 'nyc-geocoding' module is a dependency for "3. Add patron data" step above, where it's included via Layer or as a package
2. The module will also be needed for computing census tract in the existing circ_trans stream populated by the [dataHarvester](https://github.com/NYPL/dataHarvester).

#### Adding census tract data to circ_trans

The existing [dataHarvester](https://github.com/NYPL/dataHarvester) is a Java app deployed as a Beanstalk. One possible integration method:

 * Include nyc-geocoding module as a git submodule
 * Ensure necessary geo data is fetched and environment initialized via EB build scripts
 * Add a system call to the Java app to call `census-tract.rb` to compute geoid (which already exists in `CircTrans` schema)

Estimated time: 1 developer 1-2 sprints

## Destination Redis Schema

These are the planned fields for `overdrive_circ_trans`:

* `bcrypted_patron_id`: Patron id translated by our salted bcrypt
* `overdrive_renewal_yes_no`: Is either 'Yes' or 'No'
* `op_code`:
  - If `overdrive_renewal_yes_no` = 'No' then 'o'
  - If `overdrive_renewal_yes_no` = 'Yes' then 'r'
* `transaction_et`: Translate `overdrive_checkout_date_time` to ET and drop the time
* `overdrive_lending_period`: Number of days lent
* `loanrrule_code_num`: The Sierra loanrule code corresponding to the `overdrive_lending_period`
* `overdrive_checkout_id`: Uniquely identifies the transaction. May be redundant if it's used as-is to fill `transaction_checksum`. Need to verify the value can not be used to identify the patron.
* `transaction_checksum`: May be the unmodified value of `overdrive_checkout_id` or a translation of it
* `ptype_code`: From `ils_ptype`
* `patron_home_library_code`: From `ils_home_library`
* `pcode3`: From `ils_pcode3`
* `postal_code`: From `ils_postal_code`
* `overdrive_format`: Will be 'Ebook', 'Audiobook', etc.
* `itype_code_num`:
  - If `overdrive_format` = 'Ebook' then `124`
  - If `overdrive_format` = 'Audiobook' then `125`
  - If `overdrive_format` = 'Video' then `126`
  - If `overdrive_format` = 'Music' then `127`
* `overdrive_borrowed_from`: Source of checkout. E.g. 'API', 'Main Collection', 'Libby', etc.
* `overdrive_audience`: E.g. 'Adult Fiction', 'Adult Nonfiction', 'Young Adult Fiction'
* `overdrive_format2`: E.g. 'Adobe Epub Book', 'Kindle Book', etc. May not exist in Overdrive data explicitly but be implicit in where the transaction was scraped from.


## Current Process

This is the current process:

1. Fetch reports:
 - Log in to Overdrive > Insights > Checkouts
 - Click "Run new report"
 - Select "Checkouts by" .. "Format"
 - The resulting page lists 13 results corresponding to each of the 13 formats
 - For each of them:
   - Click on the title (e.g. "Adobe EPUB EBook")
   - That produces a paginated listing of all distinct checkouts for that format (Adobe EPUB EBook has 4356 results over 88 pages at writing)
   - Click "Create worksheet" to download the CSV containing all rows
 - As of 04/10/2020 we expect 13 files (may increase over time).
 - Download Overdrive Checkout stats for the desired time period by format
 - This presumably produces several files called Checkout{N}.csv for N = 1 through 13 - presumably always in the same order
 - Copy Checkout*.csv to script directory
2. Prepper.bash
 - Run prepper.bash to add appropriate format2 column to end of all rows and concat result into RANK_work.prep
 - Also removes the line(s) matching /^CrossRefID/
 - Prodouces RANK_work.excel
3. Remove headers, ctrl-M's (?)
4. #set ff=unix
5. Process in Excel
 - import into Excel
 - the Excel file import uses comma delimiter and quote text qualifier
 - sort in date order
 - copy resulting file to /home/aarondabbah/WORK/SANDBOX/RANKIN
 - Change tabs to pipes, rename file to RANK_work.over_raw
6. Reduce columns:
 - Run awk -F"|" '{print $25"|"$10"|"$21"|"$23"|"$20"|"$19"|"$17"|"$31}' RANK_work.over_raw > RANK_work.over
 - This produces a new RANK_work.over with just the 8 named columns
 - rm -rf RANK_work.over_raw
7. Build patron lookup from Sierra:
 - Run a big sql against Sierra to build a lookup consisting of:
    sierra_view.patron_view.record_num,             # patron id (e.g. .p1234567)
    sierra_view.patron_view.id,                     # patron id? (Later referred to as 'hash'?)
    sierra_view.patron_view.ptype_code,             # ptype
    sierra_view.patron_view.home_library_code,      # location
    sierra_view.patron_view.pcode3,                 # pcode3
    sierra_view.patron_record_address.postal_code   # zip
 - This runs for a couple minutes, producing RANK_work.ils_raw 
 - Strip dupe spaces and whitespace padding via:
    tr -s " " < RANK_work.ils_raw | sed 's/^ //g' | sed 's/ | /|/g' > RANK_work.ils
 - This produces RANK_work.ils
 - rm -rf RANK_work.ils_raw
   awk -F"|" '{print#
8. Build final report:
 - Loop over RANK_work.over, producing:
    patron: line[1]
    format: line[2]
    borrow: line[3]
    renew: line[4]
    checkout: line[5]
    lending: line[6]
    checkid: line[7]
    file: line[8]
    ilsdata: line matching ^$patron"|" in RANK_WORK.ils
    hash: ilsdata[2]
    ptype: ilsdata[3]
    homelib: ilsdata[4]
    pcode3: ilsdata[5]
    zip: ilsdata[6]
    crypt: anonymizer.py "$hash" | sed 's/^{SALT}//g')
 - echo $crypt"|"$format"|"$borrow"|"$renew"|"$checkout"|"$lending"|"$checkid"|"$ptype"|"$homelib"|"$pcode3"|"$zip"|"$file >> RANK_work.results
9. Send RANK_work.results to Strategy    


# BIC

The BIC gives NYPL access to anonymized circulation data for the purpose of assessing reach.

The BIC is really version 3 of the Data Warehouse. See [History (Data Warehouse)](#history-data-warehouse) for information on its origins.

## Protections against re-identification

The data has been modified to ensure that it's essentially impossible to derive any individual patron's detailed transaction history. Furthermore, the data granularity has been reduced to ensure that - should one have the means to identify an individual - the transaction history obtained would be of very low quality. In particular transactions do not record item information except `item_code_num`, `item_location_code`, and `icode1`. To make re-identification difficult, all timestamps are stored with day granularity, ensuring for example, that the *time* of checkout can not be used together with item type to re-identify an anonymized transaction. These choices m

Finally, we obfuscate patron ids using a closely guarded cryptographic [salt](https://en.wikipedia.org/wiki/Salt_(cryptography)).

## Components

See [BIC (Data Warehouse v3)](https://docs.google.com/presentation/d/1e2dkC5vLwJ8SzaLrwad-TUyRPmqFZNIG8gxD12YY98w/edit#slide=id.g29c0c333b1_0_3) for a diagram of the BIC pipeline.

### CircTransPoller

The poller is a Ruby native lambda, which polls the Sierra database directly for transaction data. It executes a [query against several joined tables](tables/circ_trans/query.sql).

### Firehose

The ["CircTransAnon" firehose stream](https://console.aws.amazon.com/firehose/home?region=us-east-1#/details/CircTransAnon-production):

 * sources events from the "CircTransAnon" Kinesis stream](https://console.aws.amazon.com/kinesis/home?region=us-east-1#/streams/details?streamName=CircTransAnon-production&tab=details)
 * transforms (i.e. decodes) them via the AvroToJsonTransformer component
 * places them in S3 bucket `circ-trans-data-production`, where they're loaded into the Redshift db
 
### AvroToJsonTransformer

The AvroToJsonTransformer is responsible for Avro-decoding events received by the ["CircTransAnon" firehose stream](https://console.aws.amazon.com/firehose/home?region=us-east-1#/details/CircTransAnon-production).

The "AvroToJsonTransformer", originally developed for the Data Warehouse, is [a Node app](https://github.com/NYPL/firehose-avro-to-json-transformer) deployed as [AWS Lambda "AvroToJsonTransformer-production"](https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/AvroToJsonTransformer-production?tab=configuration). It essentially:

 - [Decodes the incoming batch of documents](https://github.com/NYPL/firehose-avro-to-json-transformer/blob/master/src/helpers/RecordsProcessor.js#L10) using the ["CircTrans" avro schema](https://platform.nypl.org/api/v0.1/current-schemas/CircTrans)
 - [Converts them into a hash](https://github.com/NYPL/firehose-avro-to-json-transformer/blob/a99b4b35182392cf4df112cccfc91e3748a99a8b/src/helpers/RecordsProcessor.js#L20-L24) with `recordId`, `result: 'Ok'`, and `data` containing a JSON serialization of the circtrans record, which is also base64 encoded.
 - The [final `callback`](https://github.com/NYPL/firehose-avro-to-json-transformer/blob/a99b4b35182392cf4df112cccfc91e3748a99a8b/index.js#L17) returns something resembling `{ records: [ { recordId: '[circtrans record id]', result: 'Ok', data: 'eyJmb28iOiJiYXIifQ....' }, ... ] }`

## Redshift Database

The Redshift db receives all `circ_trans` data and is the database queried by NYPL staff.

### CircTrans Schema

| column                     | type           | description                                                                                                                                                                                                                                                                                                                                                                                                                | sample value                           |
|----------------------------|----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|
| `id`                       | `INTEGER`      | Unique id for transaction (local to Redshift)                                                                                                                                                                                                                                                                                                                                                                              | `12345`                                |
| `patron_id`                | `VARCHAR(31)`  | Anonymized patron id                                                                                                                                                                                                                                                                                                                                                                                                       | `Sw0A74bw1YxANttZZO3XmMhrJpdW6yy`        |
| `ptype_code`               | `VARCHAR(5)`   | Patron ["ptype"](https://docs.google.com/spreadsheets/d/1YUZuG8yGS-7kW2uG2eU5K4YWThH-DN8_ucqJaDCAvw4/edit#gid=0&range=A3)                                                                                                                                                                                                                                                                                                  | `10`                                   |
| `patron_home_library_code` | `VARCHAR(20)`  | A five-character location code, right-padded with spaces, from the associated patron record.                                                                                                                                                                                                                                                                                                                               | `sa`                                   |
| `pcode3`                   | `SMALLINT`     | Patron ["home region"](https://docs.google.com/spreadsheets/d/1YUZuG8yGS-7kW2uG2eU5K4YWThH-DN8_ucqJaDCAvw4/edit#gid=1206057186)                                                                                                                                                                                                                                                                                            | `2`                                    |
| `postal_code`              | `VARCHAR(5)`?  | Patron postal code                                                                                                                                                                                                                                                                                                                                                                                                         | `11222`                                |
| `itype_code_num`           | `SMALLINT`     | [Item Type](https://docs.google.com/spreadsheets/d/1YUZuG8yGS-7kW2uG2eU5K4YWThH-DN8_ucqJaDCAvw4/edit#gid=580006046&range=A1)                                                                                                                                                                                                                                                                                               | `101` (Book, circ)                     |
| `item_location_code`       | `VARCHAR(20)`  | A five-character [location code](https://docs.google.com/spreadsheets/d/1YUZuG8yGS-7kW2uG2eU5K4YWThH-DN8_ucqJaDCAvw4/edit#gid=2039183095&range=A1), right-padded with spaces, from the associated item record.                                                                                                                                                                                                             | `maj0f`                                |
| `icode1`                   | `INTEGER`      | Item ["icode1"](https://docs.google.com/spreadsheets/d/1YUZuG8yGS-7kW2uG2eU5K4YWThH-DN8_ucqJaDCAvw4/edit#gid=333228251&range=A1)                                                                                                                                                                                                                                                                                           | `-` (Is this the only possible value?) |
| `op_code`                  | `VARCHAR(5)`   | Type of transaction: `o` (checkout), `i` (checkin), `n` (hold), `nb` (bib hold), `ni` (item hold), `nv` (volume hold), `h` (hold with recall), `hb` (hold recall bib), `hi` (hold recall item), `hv` (hold recall volume), `f` (filled hold), `r` (renewal), `b` (booking), `u` (use count)                                                                                                                                                                         | `o`                                    |
| `transaction_gmt`          | `DATE`         | Transaction date (without time)                                                                                                                                                                                                                                                                                                                                                                                            | `2019-11-15`                           |
| `due_date_gmt`             | `DATE`         | Due date                                                                                                                                                                                                                                                                                                                                                                                                                   | `2019-11-29`                           |
| `application_name`         | `VARCHAR(200)` | The name of the program that generated the transaction. Valid program names are: `circ` (includes transactions made using PC Circ), `circa` (for transactions written by selfcheckwebserver and in-house use [transaction codes 'u' and 's'], which use webpac to execute transactions.) `milcirc`, ` milmyselfcheck`, `readreq`, `selfcheck`                                                                                               | `readreq`                              |
| `stat_group_code_num`      | `SMALLINT`     | The [number of the terminal](https://docs.google.com/spreadsheets/d/1YUZuG8yGS-7kW2uG2eU5K4YWThH-DN8_ucqJaDCAvw4/edit#gid=1498427022&range=A1) at which the transaction occurred or the user-specified statistics group number for PC-Circ transactions. Also stores the login's statistics group number for circulation transactions performed with the following Circa applications: checkout checkin count internal use | `800`                                  |
| `loanrule_code_num`        | `SMALLINT`     | Indicates loan rule governing transaction                                                                                                                                                                                                                                                                                                                                                                                                                          | `0`                                    |
| `source_code`              | `VARCHAR(200)` | The transaction source. Possible values are: local INN-Reach ILL                                                                                                                                                                                                                                                                                                                                                           | `0`                                    |
| `has_checkouts`            | `BOOLEAN`      | Does this patron have a checkout-count > 0?     | `true`                                        |
| `last_activity`            | `DATE`         | Date (without time) of last activity by patron                                                                                                                                                                                                                                                                                                                                                                             | `2011-11-15`                           |

### User Management

To add a new read-only user to Redshift:

```sql
CREATE USER username WITH password 'password123';
ALTER GROUP readonly ADD USER username;
```

User credentials are stored as a `Secure String` in Parameter Store as [`/production/redshift/credentials/{username}`](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Parameters:Path=%5BOneLevel%5D/production/redshift/credentials/;sort=Name).

An example value:

```
{"username":"analysis","password":"1234567"}
```

**Creating the `readonly` group:**

The `readonly` group in Redshift was created as follows:

```sql
CREATE GROUP readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO GROUP readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO GROUP readonly;
```

### Queries run

?

### Tables

Note that only `circ_trans` is populated dynamically. `patrons` has been deprecated entirely. The remaining lookup tables may be useful for interpretting codes in `circ_trans`, but are not kept up to date.

Name                  | Data Schema                                                                                             | Table Schema                                        | Query                                    | Load                                            | Notes
--------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | ---------------------------------------- | ----------------------------------------------- | ------------------------------------
`circ_trans`          | [CircTrans](https://platform.nypl.org/api/v0.1/current-schemas/CircTrans)              | [schema.sql](tables/circ_trans/schema.sql)          | [query.sql](tables/circ_trans/query.sql)              | [load.sql](tables/circ_trans/load.sql)          | [Notes](tables/circ_trans/README.md)
`patrons` (deprecated)            | [DataWarehousePatrons](https://dev-platform.nypl.org/api/v0.1/current-schemas/DataWarehousePatrons)     | [schema.sql](tables/patrons/schema.sql)             |                                          | [load.sql](tables/patrons/load.sql)             |
`item_types` (static)                 |                                                                                                         | [schema.sql](tables/item_types/schema.sql)          |                                          | [load.sql](tables/item_types/load.sql)          |
`locations` (static)           |                                                                                                         | [schema.sql](tables/locations/schema.sql)           |                                          | [load.sql](tables/locations/load.sql)           |
`location_details` (static)   |                                                                                                         | [schema.sql](tables/location_details/schema.sql)    |                                          | [load.sql](tables/location_details/load.sql)    |
`op_codes  ` (static)         |                                                                                                         | [schema.sql](tables/op_codes/schema.sql)            |                                          | [load.sql](tables/op_codes/load.sql)            |
`patron_types` (static)        |                                                                                                         | [schema.sql](tables/patron_types/schema.sql)        |                                          | [load.sql](tables/patron_types/load.sql)        |
`terminal_codes` (static)     |                                                                                                         | [schema.sql](tables/terminal_codes/schema.sql)      |                                          | [load.sql](tables/terminal_codes/load.sql)      |
`patron_home_regions` (static) |                                                                                                         | [schema.sql](tables/patron_home_regions/schema.sql) |                                          | [load.sql](tables/patron_home_regions/load.sql) |


## History (Data Warehouse)

BIC had its origins in the "Data Warehouse". This was a project to extract anonymized circulation data out of NYPL ILS for interpretation by NYPL Strategy. It was kicked off Oct 12, 2017. It was disabled mid-April, 2018:

```sql
SELECT MAX(transaction_gmt) FROM circ_trans;
          max           
------------------------
 2018-05-15 16:27:39+00
```

### Documentation

- [NYPL Data Warehouse Project](https://docs.google.com/presentation/d/1RP-sh7Dmkxgz-dzhu6wRHQzD8FUE3-HwIfbOf5MKNi0/edit): Presentation given at NYPL at the start of this project
- [Getting Started with Amazon Redshift](aws_presentations/Getting_Started_with_Amazon_Redshift.pdf): Useful introductory presentation from Amazon about Redshift
- [Deep Dive on Amazon Redshift](aws_presentations/Amazon_Redshift_Deep_Dive.pdf): A deeper dive into the more technical aspects of Redshift
- [Sierra Codes & Tables](https://docs.google.com/spreadsheets/d/1heMNlpy4kGJx6EZpjROqJxHCl2F8LN2Ta2qoMq7FwcI/edit#gid=0)
- [Sierra Circtrans Details](https://docs.google.com/spreadsheets/d/1heMNlpy4kGJx6EZpjROqJxHCl2F8LN2Ta2qoMq7FwcI/edit#gid=0)
- [Common Circulation Activity Reports Requested](https://docs.google.com/document/d/1UMscWy9bDHhAJlJ41myIJsysWcL5YNE2AOj6QjNJVXk/edit)

### Architecture

[Data Warehouse Architecture v2](https://docs.google.com/presentation/d/1DZ5J_D6aiyOQ-Hchhs7o5zEojGby9anRPW0hV8WqVW0/edit) captures the implemented architecture of the Data Warehouse. (Note that the other two slides were not implemented.)

### Lookup Tables

The Data Warehouse proposed use of a number of "lookup tables", which columns in `circ_trans` reference. They're useful mainly for getting labels and other metadata about referenced locations, etc.  These tables are populated by:

- [Source Data](https://docs.google.com/spreadsheets/d/1bqjFbDUKQh9ybdvE3CnJIjyeHXt9FJMRL2Pr-MTUI1A/edit#gid=1294251034)
- [CSV Exports](data)

### Target interface

Data Warehouse data was queried via psql. Digital experimented with [AWS QuickSight](https://aws.amazon.com/quicksight/) to explore the data. They also developed  [circ_trans_combined_v2.sql](quicksight/queries/circ_trans_combined_v2.sql), which demonstrates the kind of many-join query that would be possible with fully populated lookup tables.

### Deprecated components

#### 1. Poller

The poller ("harvester") is [a Java app](https://github.com/NYPL/dataHarvester) deployed as [Beanstalk "CircTransPoller-production"](https://console.aws.amazon.com/elasticbeanstalk/home?region=us-east-1#/environment/dashboard?applicationName=CircTransPoller&environmentId=e-eidxm4xpfz). The poller essentially:

 - On [a fixed 60s delay](https://github.com/NYPL/dataHarvester/blob/edc9d417cfb43b621454239b8744323601880e52/src/main/java/org/nypl/datawarehouse/harvester/route/RouteCircTrans.java#L45-L51) ..
 - [Queries the Sierra prod database directly](https://github.com/NYPL/dataHarvester/blob/edc9d417cfb43b621454239b8744323601880e52/src/main/java/org/nypl/datawarehouse/harvester/processor/DbProcessor.java#L115-L122) for circ trans records in batches of 10000, [starting with the last seen `circ_trans.id`](https://github.com/NYPL/dataHarvester/blob/edc9d417cfb43b621454239b8744323601880e52/src/main/java/org/nypl/datawarehouse/harvester/processor/DbProcessor.java#L105-L106) (an incrementing id generated by Sierra)
 - [Sends the records to the configured Kinesis stream](https://github.com/NYPL/dataHarvester/blob/edc9d417cfb43b621454239b8744323601880e52/src/main/java/org/nypl/datawarehouse/harvester/processor/DbProcessor.java#L198) encoded using [the CircTrans schema](https://platform.nypl.org/api/v0.1/current-schemas/CircTrans)
 - [Records the last seen id in cache](https://github.com/NYPL/dataHarvester/blob/edc9d417cfb43b621454239b8744323601880e52/src/main/java/org/nypl/datawarehouse/harvester/processor/DbProcessor.java#L199) (redis)

#### 2. Anonymizer

The anonymizer is [a Node app](https://github.com/NYPL/dw-circ-trans-anonymizer) deployed as [AWS Lambda "CircTransAnonymizer-production"](https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/CircTransAnonymizer-production?tab=configuration). The anonymizer essentially:

 - [Decodes](https://github.com/NYPL/dw-circ-trans-anonymizer/blob/ddab1554633bd98d289b630ba9b28cafbf95a1a3/index.js#L60) the incoming batch of records using ["CircTrans" avro schema](https://platform.nypl.org/api/v0.1/current-schemas/CircTrans)
 - [Anonymizes](https://github.com/NYPL/dw-circ-trans-anonymizer/blob/ddab1554633bd98d289b630ba9b28cafbf95a1a3/index.js#L61) configured fields (bib_id,item_id,patron_id,volume_id) by, [for each configured "mask" field](https://github.com/NYPL/dw-circ-trans-anonymizer/blob/ddab1554633bd98d289b630ba9b28cafbf95a1a3/src/models/CircRecord.js#L10):
   - [Builds a redis key](https://github.com/NYPL/dw-circ-trans-anonymizer/blob/master/src/models/CircRecord.js#L31) for the field to anonymize (e.g. "bib_id:1234")
   - [Fetches the anonymized id from Redis](https://github.com/NYPL/dw-circ-trans-anonymizer/blob/ddab1554633bd98d289b630ba9b28cafbf95a1a3/src/models/CircRecord.js#L33)
   - If there is no existing anonymized value for the queried id, [creates a new one via a counter](https://github.com/NYPL/dw-circ-trans-anonymizer/blob/master/src/models/CircRecord.js#L57) (e.g. "bib_id_counter")
   - [Sets the new anonymized value in Redis](https://github.com/NYPL/dw-circ-trans-anonymizer/blob/ddab1554633bd98d289b630ba9b28cafbf95a1a3/src/models/CircRecord.js#L67)
   - Overwrites the given field with the new anonymized value
 - [Posts anonymized records](https://github.com/NYPL/dw-circ-trans-anonymizer/blob/ddab1554633bd98d289b630ba9b28cafbf95a1a3/index.js#L68) to "CircTransAnon-production" Kinesis stream (using ["CircTrans" avro schema](https://platform.nypl.org/api/v0.1/current-schemas/CircTrans))


### Redis Databases (for mapping anonymized identifiers)

These databases contained anonymization mappings for patrons, bibs, items, and volumes:

Environment  | Endpoint
------------ | ----------
Development  | `shared-dev.rtovuw.0001.use1.cache.amazonaws.com`
Production   | `anonymizer-prod.frh6pg.0001.use1.cache.amazonaws.com`

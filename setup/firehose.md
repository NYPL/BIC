# Kinesis Firehose

## GUI Configuration Options

Delivery role policy defined during Firehose creation

* allows Firehose to listen to incoming stream
* allows Firehose to invoke transformer lambda (optional)
* allows Firehose to read/write to S3 bucket (prefix to top level directory optional)

Stream to listen for events

* CircTransAnonymizerStream (Avro encoded records)

Transformer stream (optional)

* processes records received from Firehose (record set size determined by Firehose)
* returns records back to Firehose with transformed, base64 encoded data
* retries 3 times by default when errors occur invoking the lambda

S3 bucket as intermediary or destination

* formats directories as (YYYY/MM/DD/HH/\[files\])
* a directory prefix can be designated as a parent of the above directory structure
  * adds "processed-failures" directory when a batch fails transformation
  * retries writing to S3 for up to 24 hours; data is lost after that period

S3 Buffer Capacity

* defaults: size 5 MB; 300 ms interval
  * can be customized (1 - 128 MB; 60-900 ms interval

Compression (optional)

Encryption (optional)

Source Record Backup (optional)

Redshift as destination

* Add credentials
* Add cluster name
* Add table name
* Add columns (comma delimited list)
* Add COPY command options NOT the actual COPY command
  * COPY command is formulated automatically using the table name and columns defined
  * options specified are appended to the formulated command
  * adds "manifest" directory with files for tracking data sent to Redshift
* Retry duration (default: 3600 ms)
  * adds "errors/manifest" directory with files after timeout
  * configurable up to 7200 ms

Logging (S3 and Redshift)

* enabled in config

Monitoring

* enabled by default

### Additional Configuration

Security group inbound rule for Redshift

* Add custom TCP rule for Firehose designated [CIDR](http://docs.aws.amazon.com/firehose/latest/dev/controlling-access.html) for region on port 5439

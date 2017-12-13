# Kinesis Firehose [Developer Guide](http://docs.aws.amazon.com/firehose/latest/dev/what-is-this-service.html)

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
* Current prefix: 'CircTransData'

S3 Buffer Capacity

* defaults: size 5 MB; 300 ms interval
  * can be customized (1 - 128 MB; 60-900 ms interval

Compression (optional)

Encryption (optional)

Source Record Backup (optional)

Redshift as destination

* Add credentials
* Add cluster name
* Add database name
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

## Current Firehose Setup

* Incoming stream: CircTransAnon
* Transformer: [AvroToJsonTransformer](https://github.com/NYPL/firehose-avro-to-json-transformer)
* S3 Bucket: circ-trans-data; prefix: CircTransData
* IAM Role: firehose_redshift_role
* S3 buffer size/interval: default
* S3 compression: default
* S3 encryption: default
* Error logging: enabled
* Redshift cluster: nypl-dw-production
* Table columns: id,patron_id,patron_record_id,item_id,item_record_id,bib_id,bib_record_id,volume_id,volume_record_id,transaction_gmt,application_name,source_code,op_code,stat_group_code_num,due_date_gmt,count_type_code_num,itype_code_num,icode1,icode2,item_location_code,item_agency_code_num,ptype_code,pcode1,pcode2,pcode3,pcode4,patron_home_library_code,patron_agency_code_num,loanrule_code_num
* COPY options: JSON 'auto' REGION 'us-east-1'
* Redshift retry duration: default

## Examples

Redshift COPY command Option [Examples](http://docs.aws.amazon.com/redshift/latest/dg/r_COPY_command_examples.html#r_COPY_command_examples-copy-from-json)

copy patrons
    from 's3://nypl-data-warehouse-production/2017-01-01/'
    iam_role 'arn:aws:iam::946183545209:role/redshift-s3-read'
    region 'us-east-1'
    format as avro 'auto'
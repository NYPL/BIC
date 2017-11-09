copy patron_types
from 's3://nypl-data-warehouse-production/lookups/patron_types.csv'
iam_role 'arn:aws:iam::946183545209:role/redshift-s3-read'
region 'us-east-1'
csv
ignoreheader 1
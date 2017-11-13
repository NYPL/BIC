# Data Warehouse

This repo is intended to be used for information relevant to the NYPL Data Warehouse.

## Users

User credentials are stored in our EC2 in the Parameter Store (following the naming convention of '/production/redshift/credentials/USERNAME'). Non-admin users default to read-only database access. 

## Tables

Name         | Data Schema                                                                                                                                                     | Table Schema                                                     | Query                                                            | Notes
------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------- | ------------------------------
`circ_trans` | [Development](https://dev-platform.nypl.org/api/v0.1/current-schemas/circ_trans) - [Production](https://platform.nypl.org/api/v0.1/current-schemas/circ_trans)  | [circ_trans_schema.sql](tables/circ_trans/circ_trans_schema.sql) | [circ_trans_query.sql](tables/circ_trans/circ_trans_query.sql) | [Notes](tables/circ_trans/README.md)

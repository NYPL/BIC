# Data Warehouse

This repo is intended to be used for information relevant to the NYPL Data Warehouse.

## Tables

Name                  | Data Schema                                                                                             | Table Schema                                        | Query                                    | Load                                            | Notes
--------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | ---------------------------------------- | ----------------------------------------------- | ------------------------------------
`circ_trans`          | [CircTrans](https://dev-platform.nypl.org/api/v0.1/current-schemas/CircTrans)              | [schema.sql](tables/circ_trans/schema.sql)          | [query.sql](tables/circ_trans/query.sql)              | [load.sql](tables/circ_trans/load.sql)          | [Notes](tables/circ_trans/README.md)
`patrons`             | [DataWarehousePatrons](https://dev-platform.nypl.org/api/v0.1/current-schemas/DataWarehousePatrons)     | [schema.sql](tables/patrons/schema.sql)             |                                          | [load.sql](tables/patrons/load.sql)             |
`item_types`          |                                                                                                         | [schema.sql](tables/item_types/schema.sql)          |                                          | [load.sql](tables/item_types/load.sql)          |
`locations`           |                                                                                                         | [schema.sql](tables/locations/schema.sql)           |                                          | [load.sql](tables/locations/load.sql)           |
`location_details`    |                                                                                                         | [schema.sql](tables/location_details/schema.sql)    |                                          | [load.sql](tables/location_details/load.sql)    |
`op_codes  `          |                                                                                                         | [schema.sql](tables/op_codes/schema.sql)            |                                          | [load.sql](tables/op_codes/load.sql)            |
`patron_types`        |                                                                                                         | [schema.sql](tables/patron_types/schema.sql)        |                                          | [load.sql](tables/patron_types/load.sql)        |
`terminal_codes`      |                                                                                                         | [schema.sql](tables/terminal_codes/schema.sql)      |                                          | [load.sql](tables/terminal_codes/load.sql)      |
`patron_home_regions` |                                                                                                         | [schema.sql](tables/patron_home_regions/schema.sql) |                                          | [load.sql](tables/patron_home_regions/load.sql) |

## Lookup Tables

The data warehouse contain various lookup tables to display more user-friendly. These tables are populated by:

- [Source Data](https://docs.google.com/spreadsheets/d/1bqjFbDUKQh9ybdvE3CnJIjyeHXt9FJMRL2Pr-MTUI1A/edit#gid=1294251034) 
- [CSV Exports](data)

## QuickSight

These queries are used to build data sets in QuickSight:

Name                   | Query
---------------------- | -----------------------------------------------------------------------------
circ_trans_combined_v2 | [circ_trans_combined_v2.sql](quicksight/queries/circ_trans_combined_v2.sql)

## Other Information

### Presentations

- [NYPL Data Warehouse Project](https://docs.google.com/presentation/d/1RP-sh7Dmkxgz-dzhu6wRHQzD8FUE3-HwIfbOf5MKNi0/edit): Presentation given at NYPL at the start of this project
- [Getting Started with Amazon Redshift](aws_presentations/Getting_Started_with_Amazon_Redshift.pdf): Useful introductory presentation from Amazon about Redshift
- [Deep Dive on Amazon Redshift](aws_presentations/Amazon_Redshift_Deep_Dive.pdf): A deeper dive into the more technical aspects of Redshift

### More links

- [Sierra Codes & Tables](https://docs.google.com/spreadsheets/d/1heMNlpy4kGJx6EZpjROqJxHCl2F8LN2Ta2qoMq7FwcI/edit#gid=0)
- [Sierra Circtrans Details](https://docs.google.com/spreadsheets/d/1heMNlpy4kGJx6EZpjROqJxHCl2F8LN2Ta2qoMq7FwcI/edit#gid=0)

## Technical Details

### Architecture

[Diagram](https://docs.google.com/presentation/d/1DZ5J_D6aiyOQ-Hchhs7o5zEojGby9anRPW0hV8WqVW0/edit)

### User Management

#### Add a new read-only user

To add a new read-only user to Redshift:

```
CREATE USER username WITH password 'password123';
ALTER GROUP readonly ADD USER username;
```

User credentials are stored as a `Secure String` in Parameter Store as [`/production/redshift/credentials/{username}`](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Parameters:Path=%5BOneLevel%5D/production/redshift/credentials/;sort=Name).

An example value:

```
{"username":"analysis","password":"1234567"}
```

#### Creating the `readonly` group

The `readonly` group in Redshift was created as follows:

```
CREATE GROUP readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO GROUP readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO GROUP readonly;
```

### Anonymization

#### Databases

These databases contain anonymization mappings for patrons, bibs, items, and volumes:

Environment  | Endpoint
------------ | ----------
Development  | `shared-dev.rtovuw.0001.use1.cache.amazonaws.com`
Production   | `anonymizer-prod.frh6pg.0001.use1.cache.amazonaws.com`

### Services Involved

- circTransPoller: [https://github.com/NYPL/dataHarvester](https://github.com/NYPL/dataHarvester)
- circTransTransformerService: [https://github.com/NYPL/dw-circ-trans-transformer](https://github.com/NYPL/dw-circ-trans-transformer)

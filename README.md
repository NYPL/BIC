# Data Warehouse

This repo is intended to be used for information relevant to the NYPL Data Warehouse.

## Tables

Name                  | Data Schema                                                                                             | Table Schema                                        | Query                                    | Load                                            | Notes
--------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | ---------------------------------------- | ----------------------------------------------- | ------------------------------------
`circ_trans`          | [DataWarehouseCircTrans](https://dev-platform.nypl.org/api/v0.1/current-schemas/DataWarehouseCircTrans) | [schema.sql](tables/circ_trans/schema.sql)          | [query.sql](tables/circ_trans/query.sql) | [load.sql](tables/circ_trans/load.sql)          | [Notes](tables/circ_trans/README.md)
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

## Users

### Add a new read-only user

To add a new read-only user to Redshift:

```
CREATE USER username WITH password 'password123';
ALTER GROUP readonly ADD USER username;
```

User credentials should be stored as a `Secure String` in Parameter Store as `production/redshift/credentials/{username}`. An example value:

```
{"username":"analysis","password":"1234567"}
```

### Creating the `readonly` group

The `readonly` group in Redshift was created as follows:

```
CREATE GROUP readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO GROUP readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO GROUP readonly;
```

## Services Involved

1. circTransPoller - [https://github.com/NYPL/dataHarvester](https://github.com/NYPL/dataHarvester)
2. circTransTransformerService - [https://github.com/NYPL/dw-circ-trans-transformer](https://github.com/NYPL/dw-circ-trans-transformer)

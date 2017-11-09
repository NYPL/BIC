# Data Warehouse

This repo is intended to be used for information relevant to the NYPL Data Warehouse.

## Tables

Name           | Data Schema                                                                                                                                                     | Table Schema                                 | Query                                    | Load                                     | Notes
------------   | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------- | ---------------------------------------- | ---------------------------------------- | ------------------------------------
`circ_trans`   | [Development](https://dev-platform.nypl.org/api/v0.1/current-schemas/circ_trans) - [Production](https://platform.nypl.org/api/v0.1/current-schemas/circ_trans)  | [schema.sql](tables/circ_trans/schema.sql)   | [query.sql](tables/circ_trans/query.sql) | [load.sql](tables/circ_trans/load.sql)   | [Notes](tables/circ_trans/README.md)
`item_types`   |                                                                                                                                                                 | [schema.sql](tables/item_types/schema.sql)   |                                          | [load.sql](tables/item_types/load.sql)   |
`locations`    |                                                                                                                                                                 | [schema.sql](tables/locations/schema.sql)    |                                          | [load.sql](tables/locations/load.sql)    |
`op_codes  `   |                                                                                                                                                                 | [schema.sql](tables/op_codes/schema.sql)     |                                          | [load.sql](tables/op_codes/load.sql)     |
`patron_tyoes` |                                                                                                                                                                 | [schema.sql](tables/patron_types/schema.sql) |                                          | [load.sql](tables/patron_tyoes/load.sql) |

## Data

The [data](data) directory contains CSVs with data for various lookup tables.

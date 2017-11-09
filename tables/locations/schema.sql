create table locations(
    id varchar(10) not null sortkey,
    short_code varchar(2),
    long_code varchar(10),
    name varchar(200),
    sierra_label varchar(200),
    location_type varchar(200),
    is_public boolean
)
diststyle all
create table locations(
    location_id varchar(10) not null sortkey,
    location_short_code varchar(2),
    location_long_code varchar(10),
    location_name varchar(200),
    location_sierra_label varchar(200),
    location_location_type varchar(200),
    location_is_public boolean,
    location_detail_id varchar(4)
)
diststyle all
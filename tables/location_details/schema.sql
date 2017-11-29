create table location_details(
    location_detail_full_name varchar(200),
    location_detail_short_name varchar(200),
    location_detail_id varchar(8) not null sortkey,
    location_detail_slug varchar(50),
    location_detail_phone varchar(30),
    location_detail_fax varchar(30),
    location_detail_tty varchar(30),
    location_detail_email varchar(200),
    location_detail_cross_street varchar(200),
    location_detail_main_url varchar(200),
    location_detail_address1 varchar(200),
    location_detail_address2 varchar(200),
    location_detail_city varchar(200),
    location_detail_region varchar(200),
    location_detail_postal_code varchar(30),
    location_detail_floor varchar(200),
    location_detail_room varchar(200),
    location_detail_lat float,
    location_detail_lng float
)
diststyle all
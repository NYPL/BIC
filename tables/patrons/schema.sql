create table patrons(
    patron_id integer not null sortkey,
    patron_city varchar(200),
    patron_region varchar(200),
    patron_postal_code varchar(50),
    patron_lat float,
    patron_lng float,
    patron_geocoded_address varchar(200)
)

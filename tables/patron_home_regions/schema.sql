create table patron_home_regions(
	patron_home_region_id integer not null sortkey,
	patron_home_region_sort_order integer,
	patron_home_region_name varchar(100)
)
diststyle all
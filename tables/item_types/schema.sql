create table item_types(
    id integer not null sortkey,
    name varchar(200),
    branch_type varchar(100),
    division_type varchar(100),
    print_type varchar(100)
)
diststyle all
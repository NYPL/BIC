create table item_types(
    item_type_id integer not null sortkey,
    item_type_name varchar(200),
    item_type_branch_type varchar(100),
    item_type_division_type varchar(100),
    item_type_print_type varchar(100)
)
diststyle all
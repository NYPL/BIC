CREATE TABLE circ_trans (
  uuid VARCHAR(36) NOT NULL,
  transaction_checksum VARCHAR(100)
  patron_id VARCHAR(100),
  ptype_code SMALLINT,
  patron_home_library_code VARCHAR(5),
  pcode3 SMALLINT,
  postal_code VARCHAR(5),
  geoid VARCHAR(11),

  itype_code_num SMALLINT,
  item_location_code VARCHAR(5),
  icode1 INTEGER,

  op_code VARCHAR(5),
  transaction_et DATE NOT NULL SORTKEY,
  due_date_et DATE,
  application_name VARCHAR(200),
  stat_group_code_num SMALLINT,
  loanrule_code_num SMALLINT,
  source_code VARCHAR(200)
);

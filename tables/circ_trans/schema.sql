CREATE TABLE circ_trans (
  id INTEGER NOT NULL DISTKEY,

  patron_id INTEGER,
  ptype_code VARCHAR(5),
  patron_home_library_code VARCHAR(20),
  pcode3 SMALLINT,
  postal_code VARCHAR(5),
  has_checkouts BOOLEAN,
  last_activity_et DATE,

  itype_code_num SMALLINT,
  item_location_code VARCHAR(20),
  icode1 INTEGER,

  op_code VARCHAR(5),
  transaction_et DATE NOT NULL SORTKEY,
  due_date_et DATE,
  application_name VARCHAR(200),
  stat_group_code_num SMALLINT,
  loanrule_code_num SMALLINT,
  source_code VARCHAR(200)
);

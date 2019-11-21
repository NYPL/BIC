SELECT patron.id AS patron_id,
  circ_trans.ptype_code,
  circ_trans.patron_home_library_code,
  circ_trans.pcode3,
  patron_address.postal_code,
  circ_trans.itype_code_num,
  circ_trans.item_location_code,
  circ_trans.icode1,
  circ_trans.op_code,
  to_date(cast(circ_trans.transaction_gmt AS TEXT), 'YYYY-MM-DD'),
  to_date(cast(circ_trans.due_date_gmt AS TEXT), 'YYYY-MM-DD'),
  circ_trans.application_name,
  circ_trans.stat_group_code_num,
  circ_trans.loanrule_code_num,
  circ_trans.source_code,
  CASE WHEN patron.checkout_count > 0 THEN TRUE ELSE FALSE AS has_checkouts,
  to_date(cast(patron.activity_gmt AS TEXT), 'YYYY-MM-DD') AS last_activity
  FROM sierra_view.circ_trans
  LEFT JOIN sierra_view.patron_record patron ON circ_trans.patron_record_id = patron.record_id
  LEFT JOIN sierra_view.patron_record_address patron_address ON circ_trans.patron_record_id = patron_address.patron_record_id
  WHERE circ_trans.id >= :start_id
  LIMIT 1;

select
    item.record_num as item_id,
    patron.record_num as patron_id,
    bib.record_num as bib_id,
    circ_trans.*
    from sierra_view.circ_trans as circ_trans
    left join sierra_view.record_metadata as item on item.id = circ_trans.item_record_id
    left join sierra_view.record_metadata as patron on patron.id = circ_trans.patron_record_id
    left join sierra_view.record_metadata as bib on bib.id = circ_trans.bib_record_id
    where circ_trans.id >= :start_id
    order by circ_trans.id
    limit :limit;
SELECT
    item.record_num AS item_id,
    patron.record_num AS patron_id,
    bib.record_num AS bib_id,
    circ_trans.*
    FROM sierra_view.circ_trans AS circ_trans
    LEFT JOIN sierra_view.record_metadata AS item ON item.id = circ_trans.item_record_id
    LEFT JOIN sierra_view.record_metadata AS patron ON patron.id = circ_trans.patron_record_id
    LEFT JOIN sierra_view.record_metadata AS bib ON bib.id = circ_trans.bib_record_id
    WHERE circ_trans.id >= :start_id
    ORDER BY circ_trans.id
    LIMIT :limit;
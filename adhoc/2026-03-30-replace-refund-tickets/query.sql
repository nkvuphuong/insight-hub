-- BI-791: Export ticket Replace/Refund 6 tháng
-- Range: 2025-10-01 → 2026-03-30 (ngày phát sinh issue)
-- Output: raw list từng ticket
-- DB: geadb__bronze (ClickHouse)

WITH

-- ============================================================
-- REPLACE: đơn con có parent_id > 0 và ord_is_split = 0
-- Issue date = ord_time của đơn con
-- Reason = nh_order_extra.ordx_type_error (join qua parent ord_id)
-- ============================================================
replace_tickets AS (
    SELECT
        C.ord_id                                          AS order_id,
        P.ord_id                                          AS parent_order_id,
        'replace'                                         AS type,
        P.cus_id                                          AS seller_id,
        C.ord_time                                        AS issue_date,
        toInt64(OX.ordx_type_error)                       AS raw_reason_id,
        multiIf(
            OX.ordx_type_error IN (1, 2, 20), 'Wrong size/type',
            OX.ordx_type_error = 3,           'Wrong print',
            OX.ordx_type_error = 4,           'Bad Print',
            OX.ordx_type_error = 5,           'Item Missing',
            OX.ordx_type_error = 6,           'Late Production',
            OX.ordx_type_error IN (7, 8, 19), 'Shipping Problem',
            OX.ordx_type_error IN (9, 10, 11),'Another reason',
            OX.ordx_type_error IN (12, 13, 14, 15, 16, 17, 18, 21, 22, 23, 24, 25, 26), 'Item Damaged',
            'Unknown'
        )                                                 AS reason_label,
        toDecimal64(0, 2)                                 AS refund_amount,
        OX.ordx_fulfill_locate                            AS workshop_code
    FROM geadb__bronze.nh_order AS C FINAL
    INNER JOIN geadb__bronze.nh_order AS P FINAL
        ON C.parent_id = P.ord_id
    INNER JOIN geadb__bronze.nh_order_extra AS OX FINAL
        ON P.ord_id = OX.ord_id
    WHERE C.parent_id > 0
      AND C.ord_is_split = 0
      AND OX.ordx_type_error != 0
      AND C.ord_time >= toDateTime('2025-10-01 00:00:00')
      AND C.ord_time <  toDateTime('2026-04-01 00:00:00')
),

-- ============================================================
-- REFUND: nh_order_refund
-- Issue date = created_time (unix → DateTime)
-- Reason = reason_id
-- ============================================================
refund_tickets AS (
    SELECT
        R.order_id                                        AS order_id,
        toInt64(0)                                        AS parent_order_id,
        'refund'                                          AS type,
        O.cus_id                                          AS seller_id,
        toDateTime(R.created_time)                        AS issue_date,
        toInt64(R.reason_id)                              AS raw_reason_id,
        multiIf(
            R.reason_id IN (1, 4),   'Bad Print',
            R.reason_id = 2,         'Item Damaged',
            R.reason_id = 3,         'Item Missing',
            R.reason_id IN (5, 7, 10),'Shipping Problem',
            R.reason_id = 6,         'Late Production',
            R.reason_id IN (8, 11),  'Wrong size/type',
            R.reason_id IN (9, 13),  'Wrong print',
            R.reason_id IN (14, 15, 17), 'Another reason',
            R.reason_id = 16,        'Cancel by buyer',
            'Unknown'
        )                                                 AS reason_label,
        R.order_amount                                    AS refund_amount,
        OX.ordx_fulfill_locate                            AS workshop_code
    FROM geadb__bronze.nh_order_refund AS R FINAL
    INNER JOIN geadb__bronze.nh_order AS O FINAL
        ON R.order_id = O.ord_id
    INNER JOIN geadb__bronze.nh_order_extra AS OX FINAL
        ON R.order_id = OX.ord_id
    WHERE R.created_time > 0
      AND toDateTime(R.created_time) >= toDateTime('2025-10-01 00:00:00')
      AND toDateTime(R.created_time) <  toDateTime('2026-04-01 00:00:00')
),

-- ============================================================
-- UNION: gộp replace + refund, enrich seller email
-- ============================================================
combined AS (
    SELECT * FROM replace_tickets
    UNION ALL
    SELECT * FROM refund_tickets
)

SELECT
    c.order_id,
    c.parent_order_id,
    c.type,
    c.seller_id,
    CUS.cus_email                                         AS seller_email,
    toDate(c.issue_date)                                  AS issue_date,
    c.raw_reason_id,
    c.reason_label,
    c.refund_amount,
    c.workshop_code
FROM combined AS c
LEFT JOIN geadb__bronze.nh_customer AS CUS
    ON c.seller_id = CUS.cus_id
ORDER BY c.issue_date, c.type, c.order_id

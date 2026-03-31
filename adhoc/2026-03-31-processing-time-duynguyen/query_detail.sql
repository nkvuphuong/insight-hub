-- BI-792: Processing Time Report — DETAIL (raw list)
-- Seller: duynguyen02169@gmail.com
-- Products: Apparel, blanket, Doormat, Garden Flag, Mug, Ornament, Tumbler
-- Range: Q1 2026 (payment_date_utc: 2026-01-01 → 2026-03-31)
-- Output: raw list từng đơn để đối soát
--
-- Tables:
--   gea__silver.fact_order_line_v1  (OMS orders)
--   gea__silver.fact_order_line_v3  (POD orders)
--   gea__silver.fact_order_fulfillment_performance_by_product FINAL
-- Join cast: toUInt64(fol.order_id) = fofp.order_id
-- Note: filter dùng toDate(payment_date_utc) vì column là Nullable(DateTime('UTC'))

WITH seller_orders AS (
    SELECT DISTINCT
        toUInt64(order_id)          AS order_id,
        toDate(payment_date_utc)    AS paid_date
    FROM gea__silver.fact_order_line_v1
    WHERE seller_email = 'duynguyen02169@gmail.com'
      AND toDate(payment_date_utc) >= '2026-01-01'
      AND toDate(payment_date_utc) <= '2026-03-31'

    UNION DISTINCT

    SELECT DISTINCT
        toUInt64(order_id)          AS order_id,
        toDate(payment_date_utc)    AS paid_date
    FROM gea__silver.fact_order_line_v3
    WHERE seller_email = 'duynguyen02169@gmail.com'
      AND toDate(payment_date_utc) >= '2026-01-01'
      AND toDate(payment_date_utc) <= '2026-03-31'
)

SELECT
    so.order_id,
    so.paid_date,
    pf.product_type,
    pf.ordx_fulfill_locate      AS workshop_code,
    pf.processing_day,
    pf.first_scan_day,
    pf.shipping_day
FROM seller_orders AS so
INNER JOIN gea__silver.fact_order_fulfillment_performance_by_product AS pf FINAL
    ON so.order_id = pf.order_id
WHERE pf.product_type IN (
    'Apparel', 'blanket', 'Doormat', 'Garden Flag', 'Mug', 'Ornament', 'Tumbler'
)
  AND pf.processing_day >= 0
ORDER BY so.paid_date, pf.product_type, so.order_id

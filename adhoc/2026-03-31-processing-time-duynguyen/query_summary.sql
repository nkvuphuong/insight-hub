-- BI-792: Processing Time Report — SUMMARY (aggregate)
-- Seller: duynguyen02169@gmail.com
-- Products: Apparel, blanket, Doormat, Garden Flag, Mug, Ornament, Tumbler
-- Range: Q1 2026 (payment_date_utc: 2026-01-01 → 2026-03-31)
-- Output: avg/p50/p90 processing_day per product_type × paid_month
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
    pf.product_type,
    formatDateTime(toStartOfMonth(so.paid_date), '%Y-%m') AS paid_month,
    count(DISTINCT so.order_id)                            AS order_count,
    round(avg(pf.processing_day), 2)                       AS avg_processing_day,
    round(quantile(0.5)(pf.processing_day), 2)             AS p50_processing_day,
    round(quantile(0.9)(pf.processing_day), 2)             AS p90_processing_day
FROM seller_orders AS so
INNER JOIN gea__silver.fact_order_fulfillment_performance_by_product AS pf FINAL
    ON so.order_id = pf.order_id
WHERE pf.product_type IN (
    'Apparel', 'blanket', 'Doormat', 'Garden Flag', 'Mug', 'Ornament', 'Tumbler'
)
  AND pf.processing_day >= 0
GROUP BY pf.product_type, paid_month
ORDER BY pf.product_type, paid_month

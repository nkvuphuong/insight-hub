-- =============================================================
-- Q2: Processing time by month
-- Customer: dopeskill — touch@dopeskillbrand.com
-- Period:   Q4 2025 (Oct–Dec) + Q1 2026 (Jan–Mar, tính đến hiện tại)
-- =============================================================
--
-- Data model:
--   fact_order_fulfillment_performance (fact_ofp) là bảng pre-calculated của OMS,
--   chứa processing_day (số ngày từ order created → production done).
--   Partition key: paid_at_utc → luôn filter paid_at_utc để tận dụng partition pruning.
--
-- Join logic (cover cả V1 + V3):
--   fact_ofp.order_id → nh_order.ord_id (toInt64 cast)
--   nh_order LEFT JOIN sc_fulfillment_order ON ord_id = toInt32(vendor_ref)
--     sc_fulfillment_order là bảng fulfillment tracking của V3, vendor_ref = nh_order.ord_id
--   WHERE cus_id = 11677          → V1-only và overlap orders
--       OR fo.team_id = '0Px0QS0P3YI'  → V3 orders đã sync về OMS
--
-- Lưu ý:
--   V3 native orders (sc_order format '260318P-...', sau 2026-03-18) chưa sync về OMS
--   → chưa có trong fact_ofp → không xuất hiện trong kết quả.
--   processing_day < 0 là artifact — loại bỏ bằng filter >= 0.
-- =============================================================

SELECT
    formatDateTime(toStartOfMonth(pf.paid_at_utc), '%Y-%m') AS payment_month,
    count(DISTINCT pf.order_id)                              AS orders,
    round(avg(pf.processing_day), 2)                         AS avg_processing_day,
    round(median(pf.processing_day), 2)                      AS median_processing_day,
    round(min(pf.processing_day), 2)                         AS min_processing_day,
    round(max(pf.processing_day), 2)                         AS max_processing_day
FROM gea__silver.fact_order_fulfillment_performance AS pf
INNER JOIN geadb__bronze.nh_order AS o                   ON toInt64(pf.order_id) = o.ord_id
LEFT JOIN  gea_seller__bronze.sc_fulfillment_order AS fo ON o.ord_id = toInt32(fo.vendor_ref)
WHERE pf.paid_at_utc >= '2025-10-01'
  AND pf.paid_at_utc  < '2026-04-01'
  AND pf.processing_day >= 0
  AND (o.cus_id = 11677 OR fo.team_id = '0Px0QS0P3YI')
GROUP BY payment_month
ORDER BY payment_month

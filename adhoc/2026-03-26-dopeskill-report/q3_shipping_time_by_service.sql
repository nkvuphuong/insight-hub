-- =============================================================
-- Q3: Shipping time by month by shipping class
-- Customer: dopeskill — touch@dopeskillbrand.com
-- Period:   Q1 2026 (Jan–Mar)
-- =============================================================
--
-- Data model:
--   fact_ofp chứa shipping_day (số ngày từ first scan → delivered) và shipping_class.
--   shipping_class là nhóm service level: Standard / Ground / Fastship / Other.
--   Partition key: paid_at_utc → luôn filter để tận dụng partition pruning.
--
-- Join logic (giống Q2 — cover cả V1 + V3):
--   fact_ofp JOIN nh_order ON toInt64(order_id) = ord_id
--   LEFT JOIN sc_fulfillment_order ON ord_id = toInt32(vendor_ref)
--   WHERE cus_id = 11677 OR fo.team_id = '0Px0QS0P3YI'
--
-- Filter shipping_hour >= 0:
--   shipping_hour < 0 = đơn chưa delivered hoặc thiếu tracking data → loại bỏ.
--   Tháng 10/2025 và 11/2025 có ít đơn delivered vì nhiều đơn vẫn đang vận chuyển
--   tại thời điểm snapshot.
--
-- Lưu ý:
--   sc_order_shipment không có data cho dopeskill → không dùng được để lấy carrier detail.
--   shipping_class là mức phân tách tốt nhất hiện tại từ fact_ofp.
-- =============================================================

SELECT
    formatDateTime(toStartOfMonth(pf.paid_at_utc), '%Y-%m') AS payment_month,
    pf.shipping_class,
    count(DISTINCT pf.order_id)                              AS orders,
    round(min(pf.shipping_day), 2)                           AS min_shipping_day,
    round(avg(pf.shipping_day), 2)                           AS avg_shipping_day,
    round(median(pf.shipping_day), 2)                        AS median_shipping_day,
    round(quantile(0.90)(pf.shipping_day), 2)                AS p90_shipping_day,
    round(quantile(0.95)(pf.shipping_day), 2)                AS p95_shipping_day,
    round(max(pf.shipping_day), 2)                           AS max_shipping_day
FROM gea__silver.fact_order_fulfillment_performance AS pf
INNER JOIN geadb__bronze.nh_order AS o                   ON toInt64(pf.order_id) = o.ord_id
LEFT JOIN  gea_seller__bronze.sc_fulfillment_order AS fo ON o.ord_id = toInt32(fo.vendor_ref)
WHERE pf.paid_at_utc >= '2026-01-01'
  AND pf.paid_at_utc  < '2026-04-01'
  AND pf.shipping_hour >= 0
  AND (o.cus_id = 11677 OR fo.team_id = '0Px0QS0P3YI')
GROUP BY payment_month, pf.shipping_class
ORDER BY payment_month, pf.shipping_class

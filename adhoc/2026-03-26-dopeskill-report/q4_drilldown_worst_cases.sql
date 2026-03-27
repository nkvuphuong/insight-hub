-- =============================================================
-- Q4: Drilldown — Worst case orders by processing & shipping time
-- Customer: dopeskill — touch@dopeskillbrand.com
-- Period:   Q1 2026 (Jan–Mar)
-- =============================================================
--
-- Định nghĩa "worst case":
--   Processing: processing_day >= p90 của từng tháng
--   Shipping:   shipping_day   >= p90 của từng tháng × shipping_class
--
-- Milestones có trong fact_ofp:
--   paid_at_utc       → thời điểm thanh toán
--   production_at     → hoàn thành sản xuất
--   fulfilled_at      → fulfill (packed/shipped)
--   first_scanned_at  → carrier quét lần đầu
--   delivered_at      → giao thành công
-- =============================================================

-- Part 1: Worst processing time orders (processing_day >= p90 per month)
SELECT
    'processing'                                          AS case_type,
    pf.order_id,
    formatDateTime(pf.paid_at_utc, '%Y-%m-%d %H:%M')    AS paid_at,
    formatDateTime(pf.production_at, '%Y-%m-%d %H:%M')  AS production_at,
    formatDateTime(pf.fulfilled_at, '%Y-%m-%d %H:%M')   AS fulfilled_at,
    NULL                                                  AS first_scanned_at,
    NULL                                                  AS delivered_at,
    pf.processing_day,
    NULL                                                  AS shipping_day,
    pf.shipping_class,
    if(pf.is_rush = 1, 'Yes', 'No')                      AS is_rush
FROM gea__silver.fact_order_fulfillment_performance AS pf
INNER JOIN geadb__bronze.nh_order AS o                   ON toInt64(pf.order_id) = o.ord_id
LEFT JOIN  gea_seller__bronze.sc_fulfillment_order AS fo ON o.ord_id = toInt32(fo.vendor_ref)
WHERE pf.paid_at_utc >= '2026-01-01'
  AND pf.paid_at_utc  < '2026-04-01'
  AND pf.processing_day >= 0
  AND (o.cus_id = 11677 OR fo.team_id = '0Px0QS0P3YI')
  AND pf.processing_day >= quantileIf(0.90)(
        pf.processing_day,
        toStartOfMonth(pf.paid_at_utc) = toStartOfMonth(pf.paid_at_utc)
      )
ORDER BY pf.processing_day DESC
LIMIT 50;

-- Part 2: Worst shipping time orders (shipping_day >= p90 per month × shipping_class)
SELECT
    'shipping'                                            AS case_type,
    pf.order_id,
    formatDateTime(pf.paid_at_utc, '%Y-%m-%d %H:%M')    AS paid_at,
    formatDateTime(pf.production_at, '%Y-%m-%d %H:%M')  AS production_at,
    formatDateTime(pf.fulfilled_at, '%Y-%m-%d %H:%M')   AS fulfilled_at,
    formatDateTime(pf.first_scanned_at, '%Y-%m-%d %H:%M') AS first_scanned_at,
    formatDateTime(pf.delivered_at, '%Y-%m-%d %H:%M')   AS delivered_at,
    pf.processing_day,
    pf.shipping_day,
    pf.shipping_class,
    if(pf.is_rush = 1, 'Yes', 'No')                      AS is_rush
FROM gea__silver.fact_order_fulfillment_performance AS pf
INNER JOIN geadb__bronze.nh_order AS o                   ON toInt64(pf.order_id) = o.ord_id
LEFT JOIN  gea_seller__bronze.sc_fulfillment_order AS fo ON o.ord_id = toInt32(fo.vendor_ref)
WHERE pf.paid_at_utc >= '2026-01-01'
  AND pf.paid_at_utc  < '2026-04-01'
  AND pf.shipping_hour >= 0
  AND (o.cus_id = 11677 OR fo.team_id = '0Px0QS0P3YI')
ORDER BY pf.shipping_day DESC
LIMIT 50;

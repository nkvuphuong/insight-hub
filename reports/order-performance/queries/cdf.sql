-- Order Performance: CDF breakpoints for all 3 metrics
-- Spec: spec.md v0.6
-- Scope: Jan–Feb 2026 (paid_at_utc), 1 aggregate row
-- Output: X = metric value (days), Y = cumulative % orders
-- Verified: 2026-03-14 via MCP (11,420 orders)

SELECT
    count() AS orders,

    -- Production Time (processing_day)
    round(countIf(processing_day <= 0.5)  / count() * 100, 1) AS prod_le_0d5,
    round(countIf(processing_day <= 1)    / count() * 100, 1) AS prod_le_1d,
    round(countIf(processing_day <= 2)    / count() * 100, 1) AS prod_le_2d,
    round(countIf(processing_day <= 3)    / count() * 100, 1) AS prod_le_3d,
    round(countIf(processing_day <= 5)    / count() * 100, 1) AS prod_le_5d,
    round(countIf(processing_day <= 7)    / count() * 100, 1) AS prod_le_7d,

    -- Tracking Lag (first_scan_day)
    round(countIf(first_scan_day <= 0.25) / count() * 100, 1) AS lag_le_0d25,
    round(countIf(first_scan_day <= 0.5)  / count() * 100, 1) AS lag_le_0d5,
    round(countIf(first_scan_day <= 1)    / count() * 100, 1) AS lag_le_1d,
    round(countIf(first_scan_day <= 2)    / count() * 100, 1) AS lag_le_2d,
    round(countIf(first_scan_day <= 3)    / count() * 100, 1) AS lag_le_3d,

    -- Tracking Active Lead (processing_day + first_scan_day)
    round(countIf(processing_day + first_scan_day <= 1)  / count() * 100, 1) AS lead_le_1d,
    round(countIf(processing_day + first_scan_day <= 2)  / count() * 100, 1) AS lead_le_2d,
    round(countIf(processing_day + first_scan_day <= 3)  / count() * 100, 1) AS lead_le_3d,
    round(countIf(processing_day + first_scan_day <= 5)  / count() * 100, 1) AS lead_le_5d,
    round(countIf(processing_day + first_scan_day <= 7)  / count() * 100, 1) AS lead_le_7d

FROM gea__silver.fact_order_fulfillment_performance FINAL
WHERE paid_at_utc >= '2026-01-01'
  AND paid_at_utc <  '2026-03-01'
  AND processing_day >= 0
  AND first_scan_day >= 0
  AND processing_day IS NOT NULL
  AND first_scan_day IS NOT NULL
  AND fulfilled_at IS NOT NULL
  AND first_scanned_at IS NOT NULL
  AND country_code = 'US'

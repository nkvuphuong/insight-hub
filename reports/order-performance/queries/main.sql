-- Order Performance: Tracking Active Lead + Component Metrics
-- Spec: order-performance/spec.md v0.6
-- Verified: 2026-03-14 via MCP
-- Granularity: monthly × shipping_class × facility

-- Unit convention (all in days, pre-calculated):
--   processing_day  = Production Time  (paid → fulfilled, production-adjusted days)
--   first_scan_day  = Tracking Lag     (fulfilled → first scan, business days)
--   processing_day + first_scan_day = Tracking Active Lead
--
-- NOTE: shipping_day = fulfilled → delivered (transit time) — NOT used in this report

WITH base AS (
    SELECT
        toStartOfMonth(paid_at_utc)              AS month,
        shipping_class,
        ordx_fulfill_locate                      AS facility,
        -- Component 1: Production Time (pre-calc, production-adjusted days)
        processing_day,
        -- Component 2: Tracking Lag (pre-calc, calendar days)
        first_scan_day
    FROM gea__silver.fact_order_fulfillment_performance FINAL
    WHERE paid_at_utc >= toDate('2024-11-01')
      AND paid_at_utc <  toStartOfMonth(today())                      -- exclude current incomplete month
      AND NOT (paid_at_utc >= '2025-08-01' AND paid_at_utc < '2025-11-01')  -- exclude pipeline gap
      AND processing_day >= 0                                         -- exclude anomalies
      AND first_scan_day >= 0                                         -- exclude anomalies (fulfilled > first_scanned)
      AND processing_day IS NOT NULL
      AND first_scan_day IS NOT NULL
      AND fulfilled_at IS NOT NULL
      AND first_scanned_at IS NOT NULL
      AND country_code = 'US'                                         -- domestic only
)
SELECT
    month,
    shipping_class,
    facility,
    count()                                                               AS orders,

    -- KPI: Tracking Active Lead (paid → first scan, days)
    round(quantile(0.5)(processing_day + first_scan_day), 2)              AS p50_active_lead_d,
    round(quantile(0.9)(processing_day + first_scan_day), 2)              AS p90_active_lead_d,
    round(avg(processing_day + first_scan_day),           2)              AS avg_active_lead_d,

    -- Component 1: Production Time (paid → fulfilled, days)
    round(quantile(0.5)(processing_day), 2)                               AS p50_prod_d,
    round(quantile(0.9)(processing_day), 2)                               AS p90_prod_d,
    round(avg(processing_day),           2)                               AS avg_prod_d,
    round(countIf(processing_day <= 1) / count() * 100, 1)                AS pct_prod_within_1d,
    round(countIf(processing_day <= 2) / count() * 100, 1)                AS pct_prod_within_2d,
    round(countIf(processing_day <= 3) / count() * 100, 1)                AS pct_prod_within_3d,
    round(countIf(processing_day <= 5) / count() * 100, 1)                AS pct_prod_within_5d,

    -- Component 2: Tracking Lag (fulfilled → first scan, days)
    round(quantile(0.5)(first_scan_day), 2)                               AS p50_lag_d,
    round(quantile(0.9)(first_scan_day), 2)                               AS p90_lag_d,
    round(countIf(first_scan_day <= 0.5) / count() * 100, 1)              AS pct_scan_within_12h,
    round(countIf(first_scan_day <= 1)   / count() * 100, 1)              AS pct_scan_within_1d,
    round(countIf(first_scan_day <= 2)   / count() * 100, 1)              AS pct_scan_within_2d

FROM base
GROUP BY month, shipping_class, facility
ORDER BY month, facility, shipping_class

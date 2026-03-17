-- Order Performance: Segment breakdown by facility × shipping_class
-- Spec: spec.md v0.6  |  Scope: Jan–Feb 2026, US
-- Verified: 2026-03-14 via MCP (6 segments, orders >= 50)

SELECT
    ordx_fulfill_locate                                                        AS facility,
    shipping_class,
    count()                                                                    AS orders,
    round(quantile(0.5)(processing_day + first_scan_day), 2)                   AS p50_active_lead_d,
    round(quantile(0.5)(processing_day), 2)                                    AS p50_prod_d,
    round(quantile(0.5)(first_scan_day), 2)                                    AS p50_lag_d,
    round(countIf(first_scan_day <= 1) / count() * 100, 1)                     AS pct_scan_within_1d
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
GROUP BY facility, shipping_class
HAVING count() >= 50
ORDER BY facility, shipping_class

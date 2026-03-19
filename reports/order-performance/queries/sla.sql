-- SLA Compliance Rate — TikTok Shop Focus
-- Scope: Standard US, Jan–Feb 2026
-- SLA target: 2 BD (TikTok Shop), 5 BD (eBay/Etsy)

WITH base AS (
    SELECT
        ordx_fulfill_locate                                  AS facility,
        shipping_class,
        processing_day,
        first_scan_day,
        processing_day + first_scan_day                      AS tracking_active_lead
    FROM gea__silver.fact_order_fulfillment_performance FINAL
    WHERE processing_day >= 0
      AND first_scan_day >= 0
      AND processing_day IS NOT NULL
      AND first_scan_day IS NOT NULL
      AND country_code = 'US'
      AND paid_at_utc >= toDate('2026-01-01')
      AND paid_at_utc <  toDate('2026-03-01')
)
SELECT
    facility,
    shipping_class,
    count()                                                                          AS total_orders,

    -- Tracking Active Lead
    round(quantile(0.5)(tracking_active_lead), 2)                                   AS p50_lead,
    round(quantile(0.9)(tracking_active_lead), 2)                                   AS p90_lead,

    -- TikTok Shop SLA (2 BD)
    round(countIf(tracking_active_lead <= 2) / count() * 100, 1)                    AS tiktok_sla_pct,

    -- Components
    round(quantile(0.5)(processing_day), 2)                                         AS p50_production,
    round(quantile(0.5)(first_scan_day), 2)                                         AS p50_tracking_lag,

    -- eBay / Etsy safe zone (5 BD)
    round(countIf(tracking_active_lead <= 5) / count() * 100, 1)                    AS ebay_etsy_sla_pct

FROM base
GROUP BY facility, shipping_class
ORDER BY tiktok_sla_pct ASC

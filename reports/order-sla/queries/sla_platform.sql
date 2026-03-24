-- SLA Platform Group: TAL pass rate theo tháng
-- Audience: BOD — viz dùng tal_pass_rate + MoM delta; debug columns giữ lại để tham khảo
-- Gate: sql-refactored (Step 3 — enrich-fact-ofp-platform)
--
-- Platform = is_platform = 1 (từ nh_order_source.is_label=1 trong fact_ofp)
-- TAL = floor(processing_day + first_scan_day) — integer biz days elapsed (payment → first scan)
--       Consistent với Standard; processing_day + first_scan_day ≈ production→fulfilled + fulfilled→first_scan
-- SLA pass = TAL ≤ 3 biz days
-- Filter: first_scan_day IS NOT NULL — Platform own USPS label; non-USPS label không có tracking data
-- Period: 12 tháng gần nhất (rolling)

SELECT
    formatDateTime(toStartOfMonth(paid_at_utc), '%Y-%m')                                      AS month,
    'Platform'                                                                                  AS group,
    count()                                                                                     AS total_orders,
    round(countIf(floor(processing_day + first_scan_day) <= 3) * 100.0 / count(), 1)          AS tal_pass_rate,
    -- debug columns (không hiển thị trong BOD view)
    round(avg(processing_day + first_scan_day), 2)                                             AS avg_tal_days,
    round(countIf(ceil(processing_day) <= 3) * 100.0 / count(), 1)                            AS production_pass_rate
FROM gea__silver.fact_order_fulfillment_performance FINAL
WHERE
    paid_at_utc >= toStartOfMonth(now() - INTERVAL 12 MONTH)
    AND is_platform = 1
    AND first_scan_day IS NOT NULL
    AND processing_day IS NOT NULL
GROUP BY month
ORDER BY month

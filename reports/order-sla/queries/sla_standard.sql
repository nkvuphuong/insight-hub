-- SLA Standard Group: TAL pass rate theo tháng
-- Audience: BOD — viz dùng tal_pass_rate + MoM delta; debug columns giữ lại để tham khảo
-- Gate: sql-refactored (Step 3 — enrich-fact-ofp-platform)
--
-- Standard = is_platform = 0 (từ nh_order_source.is_label=0 trong fact_ofp)
-- TAL = floor(processing_day + first_scan_day) — integer biz days elapsed (payment → first scan)
-- SLA pass = TAL ≤ 4 biz days
-- Period: 12 tháng gần nhất (rolling)
--
-- Note: FINAL trong subquery để tránh timeout với bảng lớn

SELECT
    formatDateTime(toStartOfMonth(paid_at_utc), '%Y-%m')                                      AS month,
    'Standard'                                                                                  AS group,
    count()                                                                                     AS total_orders,
    round(countIf(floor(processing_day + first_scan_day) <= 4) * 100.0 / count(), 1)          AS tal_pass_rate,
    -- debug columns (không hiển thị trong BOD view)
    round(avg(processing_day + first_scan_day), 2)                                             AS avg_tal_days,
    round(countIf(floor(processing_day) <= 4) * 100.0 / count(), 1)                           AS production_pass_rate,
    round(countIf(floor(first_scan_day) <= 4) * 100.0 / count(), 1)                           AS tracking_pass_rate
FROM (
    SELECT paid_at_utc, processing_day, first_scan_day
    FROM gea__silver.fact_order_fulfillment_performance FINAL
    WHERE
        paid_at_utc >= toStartOfMonth(now() - INTERVAL 12 MONTH)
        AND is_platform = 0
        AND first_scan_day IS NOT NULL
        AND processing_day IS NOT NULL
) AS f
GROUP BY month
ORDER BY month

-- SLA Standard Group: TAL pass rate theo tháng
-- Audience: BOD — viz dùng tal_pass_rate + MoM delta; debug columns giữ lại để tham khảo
-- Gate: sql-verified
--
-- Standard = đơn GM mua label = orders KHÔNG có trong v__usps_paided_to_first_scan_days
-- TAL = floor(processing_day + first_scan_day) — integer biz days elapsed (payment → first scan)
-- Convention: same as Platform business_days_exclude_payment (floor, payment day excluded)
-- Period: 12 tháng gần nhất (rolling)
--
-- Join pattern: fact_ofp FINAL (subquery) LEFT ANTI JOIN v__usps_paided

SELECT
    formatDateTime(toStartOfMonth(f.paid_at_utc), '%Y-%m')                                    AS month,
    'Standard'                                                                                  AS group,
    count()                                                                                     AS total_orders,
    round(countIf(floor(f.processing_day + f.first_scan_day) <= 4) * 100.0 / count(), 1)      AS tal_pass_rate,
    -- debug columns (không hiển thị trong BOD view)
    round(avg(f.processing_day + f.first_scan_day), 2)                                        AS avg_tal_days,
    round(countIf(floor(f.processing_day) <= 4) * 100.0 / count(), 1)                        AS production_pass_rate,
    round(countIf(floor(f.first_scan_day) <= 4) * 100.0 / count(), 1)                        AS tracking_pass_rate
FROM (
    SELECT order_id, paid_at_utc, processing_day, first_scan_day
    FROM gea__silver.fact_order_fulfillment_performance FINAL
    WHERE
        paid_at_utc >= toStartOfMonth(now() - INTERVAL 12 MONTH)
        AND first_scan_day IS NOT NULL
        AND processing_day IS NOT NULL
) f
LEFT ANTI JOIN gea__silver.v__usps_paided_to_first_scan_days p
    ON toInt64(f.order_id) = toInt64(p.ord_id)
GROUP BY month
ORDER BY month

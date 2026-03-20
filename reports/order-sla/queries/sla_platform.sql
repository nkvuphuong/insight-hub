-- SLA Platform Group: TAL pass rate theo tháng
-- Audience: BOD — viz dùng tal_pass_rate + MoM delta; debug columns giữ lại để tham khảo
-- Gate: sql-verified
--
-- Platform = đơn khách hàng cung cấp USPS label = orders có trong v__usps_paided_to_first_scan_days
-- TAL = v__usps_paided.business_days_exclude_payment (biz days, paid → first scan)
-- Period: 12 tháng gần nhất (rolling)
--
-- Join pattern: v__usps_paided driving (~143K rows) → INNER JOIN fact_ofp FINAL (subquery)
-- Lý do: FINAL trực tiếp + JOIN gây timeout; tách FINAL vào subquery để tránh
-- Lưu ý: count() trên v__usps_paided có thể trả partial result — dùng aggregate query để verify
-- Cast: toInt64() cả 2 phía (v__usps.ord_id=Int32, fact_ofp.order_id=UInt64)

SELECT
    formatDateTime(toStartOfMonth(f.paid_at_utc), '%Y-%m')                           AS month,
    'Platform'                                                                          AS group,
    count()                                                                             AS total_orders,
    round(countIf(p.business_days_exclude_payment <= 3) * 100.0 / count(), 1)         AS tal_pass_rate,
    -- debug columns (không hiển thị trong BOD view)
    round(avg(p.business_days_exclude_payment), 2)                                     AS avg_tal_days,
    round(countIf(ceil(f.processing_day) <= 3) * 100.0 / count(), 1)                 AS production_pass_rate
FROM gea__silver.v__usps_paided_to_first_scan_days p
INNER JOIN (
    SELECT order_id, paid_at_utc, processing_day
    FROM gea__silver.fact_order_fulfillment_performance FINAL
    WHERE paid_at_utc >= toStartOfMonth(now() - INTERVAL 12 MONTH)
) f ON toInt64(p.ord_id) = toInt64(f.order_id)
WHERE f.paid_at_utc >= toStartOfMonth(now() - INTERVAL 12 MONTH)
GROUP BY month
ORDER BY month

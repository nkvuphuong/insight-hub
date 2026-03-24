-- ops_location_breakdown.sql
-- SLA pass rate per ordx_fulfill_locate, Platform (≤3 biz days) và Standard (≤4 biz days)
-- Period: 6 tháng gần nhất
-- Output: group, ordx_fulfill_locate, total_orders, passed_orders, pass_rate

WITH
    platform AS (
        SELECT
            'Platform'                                                  AS group,
            CASE WHEN ordx_fulfill_locate IN ('HB1', 'HB2') THEN 'CA'
                 ELSE ordx_fulfill_locate END                           AS ordx_fulfill_locate,
            count()                                                     AS total_orders,
            countIf(floor(processing_day + first_scan_day) <= 3)       AS passed_orders,
            round(passed_orders / total_orders * 100, 1)               AS pass_rate
        FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL
        WHERE is_platform = 1
          AND processing_day IS NOT NULL
          AND first_scan_day IS NOT NULL
          AND paid_at_utc >= toStartOfMonth(now() - INTERVAL 1 MONTH)
          AND paid_at_utc < toStartOfMonth(now())
        GROUP BY ordx_fulfill_locate
    ),
    standard AS (
        SELECT
            'Standard'                                                  AS group,
            CASE WHEN ordx_fulfill_locate IN ('HB1', 'HB2') THEN 'CA'
                 ELSE ordx_fulfill_locate END                           AS ordx_fulfill_locate,
            count()                                                     AS total_orders,
            countIf(floor(processing_day + first_scan_day) <= 4)       AS passed_orders,
            round(passed_orders / total_orders * 100, 1)               AS pass_rate
        FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL
        WHERE is_platform = 0
          AND processing_day IS NOT NULL
          AND first_scan_day IS NOT NULL
          AND paid_at_utc >= toStartOfMonth(now() - INTERVAL 1 MONTH)
          AND paid_at_utc < toStartOfMonth(now())
        GROUP BY ordx_fulfill_locate
    )
SELECT *
FROM platform
UNION ALL
SELECT *
FROM standard
ORDER BY group, pass_rate ASC

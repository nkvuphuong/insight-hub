-- ops_facility_product.sql
-- Avg processing_day + first_scan_day per facility × product_type
-- Dùng để drill-down: sau khi L1 identify facility bottleneck, xác định loại bottleneck + product cụ thể
-- Period: 6 tháng gần nhất
-- Output: group, ordx_fulfill_locate, product_type, avg_processing_day, avg_first_scan_day, avg_tal, order_count

WITH
    platform AS (
        SELECT
            'Platform'                                      AS group,
            CASE WHEN ordx_fulfill_locate IN ('HB1', 'HB2') THEN 'CA'
                 ELSE ordx_fulfill_locate END               AS ordx_fulfill_locate,
            product_type,
            avg(processing_day)                             AS avg_processing_day,
            avg(first_scan_day)                             AS avg_first_scan_day,
            avg(processing_day + first_scan_day)            AS avg_tal,
            count()                                         AS order_count
        FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL
        WHERE is_platform = 1
          AND processing_day IS NOT NULL
          AND first_scan_day IS NOT NULL
          AND paid_at_utc >= toStartOfMonth(now() - INTERVAL 1 MONTH)
          AND paid_at_utc < toStartOfMonth(now())
        GROUP BY ordx_fulfill_locate, product_type
    ),
    standard AS (
        SELECT
            'Standard'                                      AS group,
            CASE WHEN ordx_fulfill_locate IN ('HB1', 'HB2') THEN 'CA'
                 ELSE ordx_fulfill_locate END               AS ordx_fulfill_locate,
            product_type,
            avg(processing_day)                             AS avg_processing_day,
            avg(first_scan_day)                             AS avg_first_scan_day,
            avg(processing_day + first_scan_day)            AS avg_tal,
            count()                                         AS order_count
        FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL
        WHERE is_platform = 0
          AND processing_day IS NOT NULL
          AND first_scan_day IS NOT NULL
          AND paid_at_utc >= toStartOfMonth(now() - INTERVAL 1 MONTH)
          AND paid_at_utc < toStartOfMonth(now())
        GROUP BY ordx_fulfill_locate, product_type
    )
SELECT *
FROM platform
UNION ALL
SELECT *
FROM standard
ORDER BY group, ordx_fulfill_locate, order_count DESC

-- ops_contribution.sql
-- Avg processing_day + first_scan_day per product_type, Platform và Standard
-- Period: 6 tháng gần nhất
-- Output: group, product_type, avg_processing_day, avg_first_scan_day, avg_tal, order_count

WITH
    platform AS (
        SELECT
            'Platform' AS group,
            product_type,
            avg(processing_day)                              AS avg_processing_day,
            avg(first_scan_day)                              AS avg_first_scan_day,
            avg(processing_day + first_scan_day)             AS avg_tal,
            count()                                          AS order_count
        FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL
        WHERE is_platform = 1
          AND processing_day IS NOT NULL
          AND first_scan_day IS NOT NULL
          AND paid_at_utc >= toStartOfMonth(now() - INTERVAL 1 MONTH)
          AND paid_at_utc < toStartOfMonth(now())
        GROUP BY product_type
    ),
    standard AS (
        SELECT
            'Standard' AS group,
            product_type,
            avg(processing_day)                              AS avg_processing_day,
            avg(first_scan_day)                              AS avg_first_scan_day,
            avg(processing_day + first_scan_day)             AS avg_tal,
            count()                                          AS order_count
        FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL
        WHERE is_platform = 0
          AND processing_day IS NOT NULL
          AND first_scan_day IS NOT NULL
          AND paid_at_utc >= toStartOfMonth(now() - INTERVAL 1 MONTH)
          AND paid_at_utc < toStartOfMonth(now())
        GROUP BY product_type
    )
SELECT *
FROM platform
UNION ALL
SELECT *
FROM standard
ORDER BY group, order_count DESC

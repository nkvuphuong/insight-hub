-- ================================================================
-- BACKUP: DDL gốc của mv__fact_order_fulfillment_performance_by_product
-- Captured: 2026-03-23 (trước khi enrich-fact-ofp-by-product)
-- Source: SELECT create_table_query FROM system.tables WHERE ...
-- ================================================================

CREATE MATERIALIZED VIEW gea__silver.mv__fact_order_fulfillment_performance_by_product
REFRESH EVERY 4 HOUR
TO gea__silver.fact_order_fulfillment_performance_by_product
(
    `order_id`             UInt64,
    `product_type`         String,
    `ordx_fulfill_locate`  String,
    `fulfill_timezone`     String,
    `paid_at_utc`          DateTime('UTC'),
    `paid_at_local`        DateTime,
    `production_at`        Nullable(DateTime),
    `is_shifted_production` UInt8,
    `fulfilled_at`         Nullable(DateTime),
    `first_scanned_at`     Nullable(DateTime),
    `delivered_at`         Nullable(DateTime),
    `processing_hour`      Nullable(Int32),
    `first_scan_hour`      Nullable(Int32),
    `shipping_hour`        Nullable(Int32),
    `processing_day`       Nullable(Float32),
    `first_scan_day`       Nullable(Float32),
    `shipping_day`         Nullable(Float32),
    `updated_at`           DateTime64(3, 'UTC')
)
DEFINER = default SQL SECURITY DEFINER
AS
WITH
single_quantity_orders AS (
    SELECT
        ord_id,
        ordi_type,
        sum(ordi_quantity) AS total_quantity,
        count(*) AS item_count
    FROM geadb__bronze.nh_order_item
    WHERE (ordi_id >= 13500000) AND (ordi_deleted = 0)
    GROUP BY ord_id, ordi_type
    HAVING total_quantity = 1
),
base_orders AS (
    SELECT
        o.ord_id AS order_id,
        pt.type_name AS product_type,
        oe.ordx_fulfill_locate,
        multiIf(
            (oe.ordx_fulfill_locate IN ('HB1', 'HB2')), 'America/Los_Angeles',
            oe.ordx_fulfill_locate = 'TX1', 'America/Chicago',
            'America/Los_Angeles'
        ) AS fulfill_timezone,
        toDateTime(nt.transaction_time, 'UTC') AS paid_at_utc,
        multiIf(
            (oe.ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Los_Angeles'),
            oe.ordx_fulfill_locate = 'TX1', toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Chicago'),
            toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Los_Angeles')
        ) AS paid_at_local,
        if(toHour(paid_at_local) <= if((toMonth(paid_at_local) IN (5, 6, 12)), 6, 12),
            paid_at_local,
            toDateTime(addDays(toDate(paid_at_local), 1), 'UTC') + toIntervalHour(8)
        ) AS production_at,
        if(toHour(paid_at_local) <= if((toMonth(paid_at_local) IN (5, 6, 12)), 6, 12), 0, 1) AS is_shifted_production,
        multiIf(
            (oe.ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(oa.fulfilled_at_utc, 'America/Los_Angeles'),
            oe.ordx_fulfill_locate = 'TX1', toTimezone(oa.fulfilled_at_utc, 'America/Chicago'),
            toTimezone(oa.fulfilled_at_utc, 'America/Los_Angeles')
        ) AS fulfilled_at,
        multiIf(
            (oe.ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(oa.first_scanned_at_utc, 'America/Los_Angeles'),
            oe.ordx_fulfill_locate = 'TX1', toTimezone(oa.first_scanned_at_utc, 'America/Chicago'),
            toTimezone(oa.first_scanned_at_utc, 'America/Los_Angeles')
        ) AS first_scanned_at,
        multiIf(
            (oe.ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(oa.delivered_at_utc, 'America/Los_Angeles'),
            oe.ordx_fulfill_locate = 'TX1', toTimezone(oa.delivered_at_utc, 'America/Chicago'),
            toTimezone(oa.delivered_at_utc, 'America/Los_Angeles')
        ) AS delivered_at,
        toDate32(production_at)    AS production_date,
        toDate32(fulfilled_at)     AS fulfilled_date,
        toDate32(first_scanned_at) AS first_scanned_date,
        toDate32(delivered_at)     AS delivered_date
    FROM geadb__bronze.nh_transaction AS nt
    INNER JOIN geadb__bronze.nh_order AS o
        ON (nt.transaction_id = o.transaction_id) AND (o.ord_id >= 13500000)
    INNER JOIN single_quantity_orders AS sqo ON o.ord_id = sqo.ord_id
    INNER JOIN geadb__bronze.nh_product_type AS pt ON sqo.ordi_type = pt.ordi_type
    INNER JOIN geadb__bronze.nh_order_extra AS oe ON o.ord_id = oe.ord_id
    ANY LEFT JOIN (
        SELECT
            ord_id,
            minIf(toDateTime(oact_time, 'UTC'), oact_activity = 'fulfilled') AS fulfilled_at_utc,
            minIf(toDateTime(oact_time, 'UTC'), oact_activity = 'pickup')    AS first_scanned_at_utc,
            minIf(toDateTime(oact_time, 'UTC'), oact_activity = 'delivered') AS delivered_at_utc
        FROM geadb__bronze.nh_order_activities
        PREWHERE ord_id >= 13500000
        WHERE oact_activity IN ('pickup', 'fulfilled', 'delivered')
        GROUP BY ord_id
    ) AS oa ON o.ord_id = oa.ord_id
),
orders_with_business_days AS (
    SELECT
        bo.*,
        pbd.business_day_seq  AS production_idx,
        fbd.business_day_seq  AS fulfilled_idx,
        fsbd.business_day_seq AS first_scanned_idx,
        dbd.business_day_seq  AS delivered_idx
    FROM base_orders AS bo
    ANY LEFT JOIN gea__silver.dim_time_bd AS pbd  ON bo.production_date    = pbd.full_date
    ANY LEFT JOIN gea__silver.dim_time_bd AS fbd  ON bo.fulfilled_date     = fbd.full_date
    ANY LEFT JOIN gea__silver.dim_time_bd AS fsbd ON bo.first_scanned_date = fsbd.full_date
    ANY LEFT JOIN gea__silver.dim_time_bd AS dbd  ON bo.delivered_date     = dbd.full_date
),
time_differences AS (
    SELECT
        *,
        dateDiff('hour', production_at, fulfilled_at)     AS pf_hour,
        dateDiff('day',  production_at, fulfilled_at)     AS pf_day,
        dateDiff('hour', fulfilled_at,  first_scanned_at) AS ff_hour,
        dateDiff('day',  fulfilled_at,  first_scanned_at) AS ff_day,
        dateDiff('hour', fulfilled_at,  delivered_at)     AS fd_hour,
        dateDiff('day',  fulfilled_at,  delivered_at)     AS fd_day
    FROM orders_with_business_days
),
adjusted_hours AS (
    SELECT
        *,
        if((fulfilled_idx > 0) AND (production_idx > 0),
            pf_hour - ((pf_day - (fulfilled_idx - production_idx)) * 24), NULL) AS processing_hour,
        if((fulfilled_idx > 0) AND (first_scanned_idx > 0),
            ff_hour - ((ff_day - (first_scanned_idx - fulfilled_idx)) * 24), NULL) AS first_scan_hour,
        if((fulfilled_idx > 0) AND (delivered_idx > 0),
            fd_hour - ((fd_day - (delivered_idx - fulfilled_idx)) * 24), NULL) AS shipping_hour
    FROM time_differences
)
SELECT
    toUInt64(order_id)                               AS order_id,
    product_type,
    ordx_fulfill_locate,
    fulfill_timezone,
    paid_at_utc,
    paid_at_local,
    production_at,
    is_shifted_production,
    fulfilled_at,
    first_scanned_at,
    delivered_at,
    CAST(processing_hour, 'Nullable(Int32)')         AS processing_hour,
    CAST(first_scan_hour, 'Nullable(Int32)')         AS first_scan_hour,
    CAST(shipping_hour,   'Nullable(Int32)')         AS shipping_hour,
    CAST(processing_hour / 24., 'Nullable(Float32)') AS processing_day,
    CAST(first_scan_hour / 24., 'Nullable(Float32)') AS first_scan_day,
    CAST(shipping_hour   / 24., 'Nullable(Float32)') AS shipping_day,
    now64(3)                                         AS updated_at
FROM adjusted_hours;

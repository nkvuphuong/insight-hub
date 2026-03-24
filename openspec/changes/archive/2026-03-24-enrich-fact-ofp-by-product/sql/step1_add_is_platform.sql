-- =============================================================
-- Step 1: Add is_platform to fact_order_fulfillment_performance_by_product
-- Source: geadb__bronze.nh_order_source.is_label
-- Baseline: 1,494,477 rows (567,025 Platform / 927,452 Standard)
-- =============================================================

-- Step 1a: Add column to destination table
ALTER TABLE gea__silver.fact_order_fulfillment_performance_by_product
ADD COLUMN IF NOT EXISTS is_platform UInt8 DEFAULT 0;

-- Step 1b: Drop old MV
DROP VIEW IF EXISTS gea__silver.mv__fact_order_fulfillment_performance_by_product;

-- Step 1c: Recreate MV with is_platform
-- Changes vs original (marked [ADDED]):
--   base_orders: + ANY LEFT JOIN nh_order_source AS nos
--     → toInt64(ord_id): nh_order_source.ord_id=UInt64, nh_order.ord_id=Int64 (verified)
--   base_orders SELECT: + ifNull(toUInt8(nos.is_label), 0) AS is_platform
--   final SELECT: + is_platform
-- SELECT standalone verified qua MCP — is_platform = 1 đúng cho Platform orders
CREATE MATERIALIZED VIEW gea__silver.mv__fact_order_fulfillment_performance_by_product
REFRESH EVERY 4 HOUR
TO gea__silver.fact_order_fulfillment_performance_by_product
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
    WHERE ordi_id >= 13500000
      AND ordi_deleted = 0
    GROUP BY ord_id, ordi_type
    HAVING total_quantity = 1
),
base_orders AS (
    SELECT
        o.ord_id AS order_id,
        pt.type_name AS product_type,
        oe.ordx_fulfill_locate,
        multiIf(
            oe.ordx_fulfill_locate IN ('HB1', 'HB2'), 'America/Los_Angeles',
            oe.ordx_fulfill_locate = 'TX1', 'America/Chicago',
            'America/Los_Angeles'
        ) AS fulfill_timezone,
        toDateTime(nt.transaction_time, 'UTC') AS paid_at_utc,
        multiIf(
            oe.ordx_fulfill_locate IN ('HB1', 'HB2'), toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Los_Angeles'),
            oe.ordx_fulfill_locate = 'TX1', toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Chicago'),
            toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Los_Angeles')
        ) AS paid_at_local,
        if(toHour(paid_at_local) <= if(toMonth(paid_at_local) IN (5, 6, 12), 6, 12),
            paid_at_local,
            toDateTime(addDays(toDate(paid_at_local), 1), 'UTC') + toIntervalHour(8)
        ) AS production_at,
        if(toHour(paid_at_local) <= if(toMonth(paid_at_local) IN (5, 6, 12), 6, 12), 0, 1) AS is_shifted_production,
        multiIf(
            oe.ordx_fulfill_locate IN ('HB1', 'HB2'), toTimezone(oa.fulfilled_at_utc, 'America/Los_Angeles'),
            oe.ordx_fulfill_locate = 'TX1', toTimezone(oa.fulfilled_at_utc, 'America/Chicago'),
            toTimezone(oa.fulfilled_at_utc, 'America/Los_Angeles')
        ) AS fulfilled_at,
        multiIf(
            oe.ordx_fulfill_locate IN ('HB1', 'HB2'), toTimezone(oa.first_scanned_at_utc, 'America/Los_Angeles'),
            oe.ordx_fulfill_locate = 'TX1', toTimezone(oa.first_scanned_at_utc, 'America/Chicago'),
            toTimezone(oa.first_scanned_at_utc, 'America/Los_Angeles')
        ) AS first_scanned_at,
        multiIf(
            oe.ordx_fulfill_locate IN ('HB1', 'HB2'), toTimezone(oa.delivered_at_utc, 'America/Los_Angeles'),
            oe.ordx_fulfill_locate = 'TX1', toTimezone(oa.delivered_at_utc, 'America/Chicago'),
            toTimezone(oa.delivered_at_utc, 'America/Los_Angeles')
        ) AS delivered_at,
        toDate32(production_at)    AS production_date,
        toDate32(fulfilled_at)     AS fulfilled_date,
        toDate32(first_scanned_at) AS first_scanned_date,
        toDate32(delivered_at)     AS delivered_date,
        -- [ADDED]
        ifNull(toUInt8(nos.is_label), 0) AS is_platform
    FROM geadb__bronze.nh_transaction AS nt
    INNER JOIN geadb__bronze.nh_order AS o
        ON nt.transaction_id = o.transaction_id AND o.ord_id >= 13500000
    INNER JOIN single_quantity_orders AS sqo ON o.ord_id = sqo.ord_id
    INNER JOIN geadb__bronze.nh_product_type AS pt ON sqo.ordi_type = pt.ordi_type
    INNER JOIN geadb__bronze.nh_order_extra AS oe ON o.ord_id = oe.ord_id
    ANY LEFT JOIN (
        SELECT ord_id,
               minIf(toDateTime(oact_time, 'UTC'), oact_activity = 'fulfilled') AS fulfilled_at_utc,
               minIf(toDateTime(oact_time, 'UTC'), oact_activity = 'pickup')    AS first_scanned_at_utc,
               minIf(toDateTime(oact_time, 'UTC'), oact_activity = 'delivered') AS delivered_at_utc
        FROM geadb__bronze.nh_order_activities
        PREWHERE ord_id >= 13500000
        WHERE oact_activity IN ('pickup', 'fulfilled', 'delivered')
        GROUP BY ord_id
    ) AS oa ON o.ord_id = oa.ord_id
    -- [ADDED] toInt64 cast: nh_order_source.ord_id=UInt64, nh_order.ord_id=Int64
    ANY LEFT JOIN (
        SELECT toInt64(ord_id) AS ord_id, is_label
        FROM geadb__bronze.nh_order_source
    ) AS nos ON o.ord_id = nos.ord_id
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
    now64(3)                                         AS updated_at,
    -- [ADDED]
    is_platform
FROM adjusted_hours;

-- =============================================================
-- Step 1d: Trigger immediate refresh (chạy trực tiếp trên ClickHouse, không qua MCP)
-- SYSTEM REFRESH VIEW gea__silver.mv__fact_order_fulfillment_performance_by_product;
-- =============================================================

-- Step 1e: Verify sau khi refresh (chạy qua MCP)
-- SELECT
--     countIf(is_platform = 1) AS platform_count,
--     countIf(is_platform = 0) AS standard_count,
--     count() AS total
-- FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL;
-- Expected: platform ≈ 567,025 / standard ≈ 927,452 / total ≈ 1,494,477

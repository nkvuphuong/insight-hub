-- Step 1 — CREATE OR REPLACE mv__fact_order_fulfillment_performance
-- Chạy file này SAU step1_alter_table.sql
--
-- Lưu ý: ClickHouse không hỗ trợ CREATE OR REPLACE MATERIALIZED VIEW.
-- Dùng DROP IF EXISTS + CREATE. Risk window rất ngắn (vài ms) — chấp nhận được
-- vì đây là full-refresh MV (REFRESH EVERY 4 HOUR), không phải trigger-based.
-- Nếu muốn zero-downtime: tạo MV tên khác → verify → drop cũ (option B, phức tạp hơn).
--
-- Thay đổi so với MV cũ:
--   1. Column list: thêm `is_platform` UInt8
--   2. base_order_data: thêm ANY LEFT JOIN nh_order_source FINAL để lấy is_label
--   3. base_order_data SELECT: thêm is_platform = if(os.is_label = 1, 1, 0)
--   4. lifecycle_timestamps SELECT: thêm is_platform (pass-through)
--   5. business_hour_metrics SELECT: thêm is_platform (pass-through)
--   6. SELECT cuối: thêm is_platform
--
-- Full refresh cycle tiếp theo (~4h) sẽ populate đúng is_platform cho tất cả orders.

DROP TABLE IF EXISTS gea__silver.mv__fact_order_fulfillment_performance;

CREATE MATERIALIZED VIEW gea__silver.mv__fact_order_fulfillment_performance
REFRESH EVERY 4 HOUR TO gea__silver.fact_order_fulfillment_performance
(
    `order_id`             UInt64,
    `ordx_fulfill_locate`  String,
    `shipping_scope`       String,
    `shipping_class`       String,
    `country_code`         FixedString(2),
    `country_name`         String,
    `fulfill_timezone`     String,
    `paid_at_utc`          DateTime('UTC'),
    `paid_at_local`        DateTime,
    `production_at`        Nullable(DateTime),
    `fulfilled_at`         Nullable(DateTime),
    `first_scanned_at`     Nullable(DateTime),
    `delivered_at`         Nullable(DateTime),
    `is_shifted_production` UInt8,
    `processing_hour`      Nullable(Int16),
    `first_scan_hour`      Nullable(Int16),
    `shipping_hour`        Nullable(Int16),
    `processing_day`       Nullable(Float32),
    `first_scan_day`       Nullable(Float32),
    `shipping_day`         Nullable(Float32),
    `updated_at`           DateTime64(3, 'UTC'),
    `is_platform`          UInt8 COMMENT 'Platform order flag: 1 = is_label=1 trong nh_order_source, 0 = Standard'
)
DEFINER = default SQL SECURITY DEFINER
AS WITH
    base_order_data AS
    (
        SELECT
            o.ord_id AS order_id,
            oe.ordx_fulfill_locate,
            multiIf(o.ord_cus_country = 231, 'Domestic', 'International') AS shipping_scope,
            multiIf(
                o.ord_shipping_method = 0, 'Standard',
                o.ord_shipping_method = 1, 'Fastship',
                o.ord_shipping_method = 2, 'Ground',
                o.ord_shipping_method = 3, 'Stamp',
                'Other'
            ) AS shipping_class,
            ctr.country_iso_code AS country_code,
            ctr.country_name     AS country_name,
            multiIf(
                (oe.ordx_fulfill_locate IN ('HB1', 'HB2')), 'America/Los_Angeles',
                oe.ordx_fulfill_locate = 'TX1',             'America/Chicago',
                'America/Los_Angeles'
            ) AS fulfill_timezone,
            toDateTime(nt.transaction_time, 'UTC') AS paid_at_utc,
            multiIf(
                (oe.ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Los_Angeles'),
                oe.ordx_fulfill_locate = 'TX1',             toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Chicago'),
                toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Los_Angeles')
            ) AS paid_at_local,
            oa.fulfilled_at_utc,
            oa.first_scanned_at_utc,
            oa.delivered_at_utc,
            -- [Step 1] is_platform: 1 nếu customer tự mang label hoặc Ship by GM
            -- Source of truth: nh_order_source.is_label
            -- is_label (UInt16) → cast sang UInt8 để match column type
            if(os.is_label = 1, toUInt8(1), toUInt8(0)) AS is_platform
        FROM geadb__bronze.nh_transaction AS nt
        INNER JOIN geadb__bronze.nh_order AS o
            ON (nt.transaction_id = o.transaction_id) AND (o.ord_id >= 13500000)
        INNER JOIN geadb__bronze.nh_order_extra AS oe
            ON o.ord_id = oe.ord_id
        INNER JOIN geadb__bronze.nh_country AS ctr
            ON o.ord_cus_country = ctr.country_id
        ANY LEFT JOIN
        (
            -- Lấy timestamps từ order activities: fulfilled, first scan (pickup), delivered
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
        -- [Step 1] JOIN nh_order_source để lấy is_label (Platform flag)
        -- Dùng subquery + FINAL bên trong để tránh ambiguity FINAL+alias trong JOIN syntax
        -- ClickHouse chỉ chấp nhận SAMPLE/USING/ON sau FINAL trong JOIN context
        ANY LEFT JOIN (
            -- toInt64: nh_order_source.ord_id là UInt64, nh_order.ord_id là Int64
            -- ClickHouse không tự cast signed/unsigned trong JOIN ON → cast tường minh
            SELECT toInt64(ord_id) AS ord_id, is_label
            FROM geadb__bronze.nh_order_source FINAL
        ) AS os ON o.ord_id = os.ord_id
    ),
    production_schedule AS
    (
        -- SELECT * tự include is_platform từ base_order_data
        SELECT
            *,
            if((toMonth(paid_at_local) IN (5, 6, 12)), 6, 12) AS cutoff_hour,
            if(
                toHour(paid_at_local) <= cutoff_hour,
                paid_at_local,
                toDateTime(addDays(toDate(paid_at_local), 1), 'UTC') + toIntervalHour(8)
            ) AS production_at,
            if(toHour(paid_at_local) <= cutoff_hour, 0, 1) AS is_shifted_production
        FROM base_order_data
    ),
    lifecycle_timestamps AS
    (
        SELECT
            order_id,
            ordx_fulfill_locate,
            shipping_scope,
            shipping_class,
            country_code,
            country_name,
            fulfill_timezone,
            paid_at_utc,
            paid_at_local,
            production_at,
            is_shifted_production,
            -- [Step 1] pass-through is_platform
            is_platform,
            multiIf(
                (ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(fulfilled_at_utc, 'America/Los_Angeles'),
                ordx_fulfill_locate = 'TX1',             toTimezone(fulfilled_at_utc, 'America/Chicago'),
                toTimezone(fulfilled_at_utc, 'America/Los_Angeles')
            ) AS fulfilled_at,
            multiIf(
                (ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(first_scanned_at_utc, 'America/Los_Angeles'),
                ordx_fulfill_locate = 'TX1',             toTimezone(first_scanned_at_utc, 'America/Chicago'),
                toTimezone(first_scanned_at_utc, 'America/Los_Angeles')
            ) AS first_scanned_at,
            multiIf(
                (ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(delivered_at_utc, 'America/Los_Angeles'),
                ordx_fulfill_locate = 'TX1',             toTimezone(delivered_at_utc, 'America/Chicago'),
                toTimezone(delivered_at_utc, 'America/Los_Angeles')
            ) AS delivered_at,
            toDate32(production_at)    AS production_date,
            toDate32(fulfilled_at)     AS fulfilled_date,
            toDate32(first_scanned_at) AS first_scanned_date,
            toDate32(delivered_at)     AS delivered_date
        FROM production_schedule
    ),
    business_day_indices AS
    (
        -- SELECT lt.* tự include is_platform từ lifecycle_timestamps
        SELECT
            lt.*,
            pbd.business_day_seq  AS production_idx,
            fbd.business_day_seq  AS fulfilled_idx,
            fsbd.business_day_seq AS first_scanned_idx,
            dbd.business_day_seq  AS delivered_idx
        FROM lifecycle_timestamps AS lt
        ANY LEFT JOIN gea__silver.dim_time_bd AS pbd  ON lt.production_date    = pbd.full_date
        ANY LEFT JOIN gea__silver.dim_time_bd AS fbd  ON lt.fulfilled_date     = fbd.full_date
        ANY LEFT JOIN gea__silver.dim_time_bd AS fsbd ON lt.first_scanned_date = fsbd.full_date
        ANY LEFT JOIN gea__silver.dim_time_bd AS dbd  ON lt.delivered_date     = dbd.full_date
    ),
    raw_time_differences AS
    (
        -- SELECT * tự include is_platform từ business_day_indices
        SELECT
            *,
            dateDiff('hour', production_at, fulfilled_at)    AS pf_hour,
            dateDiff('day',  production_at, fulfilled_at)    AS pf_day,
            dateDiff('hour', fulfilled_at,  first_scanned_at) AS ff_hour,
            dateDiff('day',  fulfilled_at,  first_scanned_at) AS ff_day,
            dateDiff('hour', fulfilled_at,  delivered_at)    AS fd_hour,
            dateDiff('day',  fulfilled_at,  delivered_at)    AS fd_day
        FROM business_day_indices
    ),
    business_hour_metrics AS
    (
        SELECT
            order_id,
            shipping_scope,
            shipping_class,
            country_code,
            country_name,
            ordx_fulfill_locate,
            fulfill_timezone,
            paid_at_utc,
            paid_at_local,
            production_at,
            is_shifted_production,
            fulfilled_at,
            first_scanned_at,
            delivered_at,
            -- [Step 1] pass-through is_platform
            is_platform,
            if((fulfilled_idx > 0) AND (production_idx > 0),
                pf_hour - ((pf_day - (fulfilled_idx - production_idx)) * 24),
                NULL
            ) AS processing_hour,
            if((fulfilled_idx > 0) AND (first_scanned_idx > 0),
                ff_hour - ((ff_day - (first_scanned_idx - fulfilled_idx)) * 24),
                NULL
            ) AS first_scan_hour,
            if((fulfilled_idx > 0) AND (delivered_idx > 0),
                fd_hour - ((fd_day - (delivered_idx - fulfilled_idx)) * 24),
                NULL
            ) AS shipping_hour
        FROM raw_time_differences
    )
SELECT
    toUInt64(order_id)                          AS order_id,
    ordx_fulfill_locate,
    shipping_scope,
    shipping_class,
    CAST(country_code, 'FixedString(2)')        AS country_code,
    country_name,
    fulfill_timezone,
    paid_at_utc,
    paid_at_local,
    production_at,
    is_shifted_production,
    fulfilled_at,
    first_scanned_at,
    delivered_at,
    CAST(processing_hour, 'Nullable(Int16)')    AS processing_hour,
    CAST(first_scan_hour, 'Nullable(Int16)')    AS first_scan_hour,
    CAST(shipping_hour,   'Nullable(Int16)')    AS shipping_hour,
    CAST(processing_hour / 24., 'Nullable(Float32)') AS processing_day,
    CAST(first_scan_hour / 24., 'Nullable(Float32)') AS first_scan_day,
    CAST(shipping_hour   / 24., 'Nullable(Float32)') AS shipping_day,
    now64(3)                                    AS updated_at,
    -- [Step 1] is_platform: từ nh_order_source.is_label
    is_platform
FROM business_hour_metrics;

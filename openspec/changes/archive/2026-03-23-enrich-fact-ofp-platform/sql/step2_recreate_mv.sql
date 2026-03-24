-- Step 2 — RECREATE mv__fact_order_fulfillment_performance
-- Chạy file này SAU khi Step 1 đã verified.
-- Dựa trên step1_recreate_mv.sql + thêm Platform first scan + delivered.
--
-- Thay đổi so với Step 1:
--   1. base_order_data: thêm subquery `pt` từ usps_tracking_event
--      → lấy platform_first_scan_utc + platform_delivered_utc per ord_id
--   2. base_order_data SELECT: COALESCE oa.first_scanned_at_utc với pt.platform_first_scan_utc
--   3. base_order_data SELECT: COALESCE oa.delivered_at_utc với pt.platform_delivered_utc
--   4. nullIf bắt buộc: minIf() trả epoch (1970-01-01) khi không match → nullIf → NULL
--   5. Type cast bắt buộc: usps_tracking_event.ord_id là Int32 → toInt64()
--                          GMTTimestamp là DateTime64(3,'UTC') → toDateTime(..., 'UTC')
--
-- PRE-TRANSIT event codes (loại trừ khỏi first scan): 89, GC, GX, MA, VP
-- DELIVERED event codes: 01, 13, 43, 60, 61, 62, 63, LD
--
-- Quy trình an toàn:
--   1. Test SELECT body standalone trước (step 2.3 trong tasks.md)
--   2. Sau khi confirm OK → chạy DROP + CREATE bên dưới
--   3. Verify sau refresh (~4h)

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
            -- [Step 2] COALESCE: Standard dùng nh_order_activities, Platform dùng usps_tracking_event
            -- nullIf bắt buộc vì minIf() trả epoch (1970-01-01) khi không có row match
            -- toDateTime() cast từ DateTime64(3,'UTC') → DateTime('UTC') để match type
            COALESCE(
                nullIf(oa.first_scanned_at_utc, toDateTime(0, 'UTC')),
                nullIf(toDateTime(pt.platform_first_scan_utc, 'UTC'), toDateTime(0, 'UTC'))
            ) AS first_scanned_at_utc,
            COALESCE(
                nullIf(oa.delivered_at_utc, toDateTime(0, 'UTC')),
                nullIf(toDateTime(pt.platform_delivered_utc, 'UTC'), toDateTime(0, 'UTC'))
            ) AS delivered_at_utc,
            -- [Step 1] is_platform: 1 nếu customer tự mang label hoặc Ship by GM
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
        -- [Step 2] JOIN usps_tracking_event để lấy Platform first scan + delivered
        -- Inline trực tiếp — không join view (view scan toàn bộ 8.6M rows, chậm)
        -- PRE-TRANSIT codes loại trừ: 89 (pre-shipment), GC (return receipt), GX (label),
        --                             MA (pre-shipment info), VP (carrier pickup scheduled)
        -- DELIVERED codes: 01, 13, 43, 60, 61, 62, 63, LD
        -- usps_tracking_event.ord_id là Int32 → toInt64() để match nh_order.ord_id (Int64)
        ANY LEFT JOIN (
            SELECT
                toInt64(ord_id) AS ord_id,
                minIf(GMTTimestamp, eventCode NOT IN ('89','GC','GX','MA','VP')
                      AND eventType != 'Tracking Not Available') AS platform_first_scan_utc,
                minIf(GMTTimestamp, eventCode IN ('01','13','43','60','61','62','63','LD'))
                      AS platform_delivered_utc
            FROM gea__bronze.usps_tracking_event
            GROUP BY ord_id
        ) AS pt ON o.ord_id = pt.ord_id
        -- [Step 1] JOIN nh_order_source để lấy is_label (Platform flag)
        ANY LEFT JOIN (
            SELECT toInt64(ord_id) AS ord_id, is_label
            FROM geadb__bronze.nh_order_source FINAL
        ) AS os ON o.ord_id = os.ord_id
    ),
    production_schedule AS
    (
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
    is_platform
FROM business_hour_metrics;

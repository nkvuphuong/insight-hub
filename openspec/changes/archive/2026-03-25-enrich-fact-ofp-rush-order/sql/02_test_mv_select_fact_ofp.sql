-- enrich-fact-ofp-rush-order: TEST SELECT cho mv__fact_order_fulfillment_performance
-- Chạy standalone qua MCP TRƯỚC KHI DROP + CREATE MV để verify không có lỗi syntax/type.
-- Expect: kết quả có is_rush column, một số rows có is_rush = 1

WITH base_order_data AS (
    SELECT
        o.ord_id AS order_id,
        oe.ordx_fulfill_locate,
        multiIf(o.ord_cus_country = 231, 'Domestic', 'International') AS shipping_scope,
        multiIf(o.ord_shipping_method = 0, 'Standard', o.ord_shipping_method = 1, 'Fastship', o.ord_shipping_method = 2, 'Ground', o.ord_shipping_method = 3, 'Stamp', 'Other') AS shipping_class,
        ctr.country_iso_code AS country_code,
        ctr.country_name AS country_name,
        multiIf((oe.ordx_fulfill_locate IN ('HB1', 'HB2')), 'America/Los_Angeles', oe.ordx_fulfill_locate = 'TX1', 'America/Chicago', 'America/Los_Angeles') AS fulfill_timezone,
        toDateTime(nt.transaction_time, 'UTC') AS paid_at_utc,
        multiIf((oe.ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Los_Angeles'), oe.ordx_fulfill_locate = 'TX1', toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Chicago'), toTimezone(toDateTime(nt.transaction_time, 'UTC'), 'America/Los_Angeles')) AS paid_at_local,
        oa.fulfilled_at_utc,
        coalesce(nullIf(oa.first_scanned_at_utc, toDateTime(0, 'UTC')), nullIf(toDateTime(pt.platform_first_scan_utc, 'UTC'), toDateTime(0, 'UTC'))) AS first_scanned_at_utc,
        coalesce(nullIf(oa.delivered_at_utc, toDateTime(0, 'UTC')), nullIf(toDateTime(pt.platform_delivered_utc, 'UTC'), toDateTime(0, 'UTC'))) AS delivered_at_utc,
        if(os.is_label = 1, toUInt8(1), toUInt8(0)) AS is_platform
    FROM geadb__bronze.nh_transaction AS nt
    INNER JOIN geadb__bronze.nh_order AS o ON (nt.transaction_id = o.transaction_id) AND (o.ord_id >= 13500000)
    INNER JOIN geadb__bronze.nh_order_extra AS oe ON o.ord_id = oe.ord_id
    INNER JOIN geadb__bronze.nh_country AS ctr ON o.ord_cus_country = ctr.country_id
    ANY LEFT JOIN (
        SELECT ord_id,
            minIf(toDateTime(oact_time, 'UTC'), oact_activity = 'fulfilled') AS fulfilled_at_utc,
            minIf(toDateTime(oact_time, 'UTC'), oact_activity = 'pickup') AS first_scanned_at_utc,
            minIf(toDateTime(oact_time, 'UTC'), oact_activity = 'delivered') AS delivered_at_utc
        FROM geadb__bronze.nh_order_activities
        PREWHERE ord_id >= 13500000
        WHERE oact_activity IN ('pickup', 'fulfilled', 'delivered')
        GROUP BY ord_id
    ) AS oa ON o.ord_id = oa.ord_id
    ANY LEFT JOIN (
        SELECT toInt64(ord_id) AS ord_id,
            minIf(GMTTimestamp, (eventCode NOT IN ('89', 'GC', 'GX', 'MA', 'VP')) AND (eventType != 'Tracking Not Available')) AS platform_first_scan_utc,
            minIf(GMTTimestamp, (eventCode IN ('01', '13', '43', '60', '61', '62', '63', 'LD'))) AS platform_delivered_utc
        FROM gea__bronze.usps_tracking_event
        GROUP BY ord_id
    ) AS pt ON o.ord_id = pt.ord_id
    ANY LEFT JOIN (
        SELECT toInt64(ord_id) AS ord_id, is_label
        FROM geadb__bronze.nh_order_source FINAL
    ) AS os ON o.ord_id = os.ord_id
),
production_schedule AS (
    SELECT *,
        if((toMonth(paid_at_local) IN (5, 6, 12)), 6, 12) AS cutoff_hour,
        if(toHour(paid_at_local) <= cutoff_hour, paid_at_local, toDateTime(addDays(toDate(paid_at_local), 1), 'UTC') + toIntervalHour(8)) AS production_at,
        if(toHour(paid_at_local) <= cutoff_hour, 0, 1) AS is_shifted_production
    FROM base_order_data
),
lifecycle_timestamps AS (
    SELECT
        order_id, ordx_fulfill_locate, shipping_scope, shipping_class,
        country_code, country_name, fulfill_timezone,
        paid_at_utc, paid_at_local, production_at, is_shifted_production, is_platform,
        multiIf((ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(fulfilled_at_utc, 'America/Los_Angeles'), ordx_fulfill_locate = 'TX1', toTimezone(fulfilled_at_utc, 'America/Chicago'), toTimezone(fulfilled_at_utc, 'America/Los_Angeles')) AS fulfilled_at,
        multiIf((ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(first_scanned_at_utc, 'America/Los_Angeles'), ordx_fulfill_locate = 'TX1', toTimezone(first_scanned_at_utc, 'America/Chicago'), toTimezone(first_scanned_at_utc, 'America/Los_Angeles')) AS first_scanned_at,
        multiIf((ordx_fulfill_locate IN ('HB1', 'HB2')), toTimezone(delivered_at_utc, 'America/Los_Angeles'), ordx_fulfill_locate = 'TX1', toTimezone(delivered_at_utc, 'America/Chicago'), toTimezone(delivered_at_utc, 'America/Los_Angeles')) AS delivered_at,
        toDate32(production_at) AS production_date,
        toDate32(fulfilled_at) AS fulfilled_date,
        toDate32(first_scanned_at) AS first_scanned_date,
        toDate32(delivered_at) AS delivered_date
    FROM production_schedule
),
business_day_indices AS (
    SELECT lt.*,
        pbd.business_day_seq AS production_idx,
        fbd.business_day_seq AS fulfilled_idx,
        fsbd.business_day_seq AS first_scanned_idx,
        dbd.business_day_seq AS delivered_idx
    FROM lifecycle_timestamps AS lt
    ANY LEFT JOIN gea__silver.dim_time_bd AS pbd ON lt.production_date = pbd.full_date
    ANY LEFT JOIN gea__silver.dim_time_bd AS fbd ON lt.fulfilled_date = fbd.full_date
    ANY LEFT JOIN gea__silver.dim_time_bd AS fsbd ON lt.first_scanned_date = fsbd.full_date
    ANY LEFT JOIN gea__silver.dim_time_bd AS dbd ON lt.delivered_date = dbd.full_date
),
raw_time_differences AS (
    SELECT *,
        dateDiff('hour', production_at, fulfilled_at) AS pf_hour,
        dateDiff('day', production_at, fulfilled_at) AS pf_day,
        dateDiff('hour', fulfilled_at, first_scanned_at) AS ff_hour,
        dateDiff('day', fulfilled_at, first_scanned_at) AS ff_day,
        dateDiff('hour', fulfilled_at, delivered_at) AS fd_hour,
        dateDiff('day', fulfilled_at, delivered_at) AS fd_day
    FROM business_day_indices
),
business_hour_metrics AS (
    SELECT
        order_id, shipping_scope, shipping_class, country_code, country_name,
        ordx_fulfill_locate, fulfill_timezone, paid_at_utc, paid_at_local,
        production_at, is_shifted_production, fulfilled_at, first_scanned_at, delivered_at,
        is_platform,
        if((fulfilled_idx > 0) AND (production_idx > 0), pf_hour - ((pf_day - (fulfilled_idx - production_idx)) * 24), NULL) AS processing_hour,
        if((fulfilled_idx > 0) AND (first_scanned_idx > 0), ff_hour - ((ff_day - (first_scanned_idx - fulfilled_idx)) * 24), NULL) AS first_scan_hour,
        if((fulfilled_idx > 0) AND (delivered_idx > 0), fd_hour - ((fd_day - (delivered_idx - fulfilled_idx)) * 24), NULL) AS shipping_hour
    FROM raw_time_differences
)
SELECT
    toUInt64(order_id) AS order_id,
    ordx_fulfill_locate,
    shipping_scope,
    shipping_class,
    CAST(country_code, 'FixedString(2)') AS country_code,
    country_name,
    fulfill_timezone,
    paid_at_utc,
    paid_at_local,
    production_at,
    is_shifted_production,
    fulfilled_at,
    first_scanned_at,
    delivered_at,
    CAST(processing_hour, 'Nullable(Int16)') AS processing_hour,
    CAST(first_scan_hour, 'Nullable(Int16)') AS first_scan_hour,
    CAST(shipping_hour, 'Nullable(Int16)') AS shipping_hour,
    CAST(processing_hour / 24., 'Nullable(Float32)') AS processing_day,
    CAST(first_scan_hour / 24., 'Nullable(Float32)') AS first_scan_day,
    CAST(shipping_hour / 24., 'Nullable(Float32)') AS shipping_day,
    now64(3) AS updated_at,
    is_platform,
    -- 🆕 is_rush
    if(rush.oid > 0, toUInt8(1), toUInt8(0)) AS is_rush
FROM business_hour_metrics
ANY LEFT JOIN (
    SELECT DISTINCT toUInt64(rush_order_id) AS oid
    FROM geadb__bronze.nh_rush_order_data FINAL
    WHERE rush_status = 1
) AS rush ON toUInt64(order_id) = rush.oid
LIMIT 100

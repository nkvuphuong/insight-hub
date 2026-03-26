-- =============================================================
-- Q1: Volume (orders + units) by month
-- Customer: dopeskill — touch@dopeskillbrand.com
-- Period:   Q4 2025 (Oct–Dec) + Q1 2026 (Jan–Mar, tính đến hiện tại)
-- =============================================================
--
-- Data model:
--   dopeskill ban đầu dùng V1 (OMS trực tiếp, cus_id = 11677).
--   Sau đó migrate sang V3 (POD platform, team_id = '0Px0QS0P3YI').
--   Migration là partial: 1 phần đơn ở V1-only, 1 phần ở cả 2, 1 phần ở V3-only.
--
-- Nguồn dữ liệu:
--   V1 (base_orders_v1v2): geadb__bronze.nh_order — lọc trực tiếp qua cus_email
--   V3 (base_orders_v3):   gea_seller__bronze.sc_order — lọc qua team owner email
--
-- Loại trừ overlap:
--   Đơn migrate từ V1 lên V3 có sc_order.order_id dạng 'TW-00{ord_id}'.
--   → Exclude bằng `order_id NOT LIKE 'TW-%'` ở V3 để tránh đếm 2 lần.
--
-- Timezone: America/Los_Angeles (PST) — theo business rule của hệ thống.
-- =============================================================

WITH
params AS (
    SELECT
        ['touch@dopeskillbrand.com']                              AS seller_emails,
        toDateTime('2025-10-01 00:00:00', 'America/Los_Angeles')  AS date_cutoff_pst
),

-- V1: OMS legacy — đơn do khách đặt trực tiếp trên hệ thống cũ
base_orders_v1v2 AS (
    SELECT
        toString(o.ord_id)                                   AS _order_id,
        toInt32(oi.ordi_quantity)                             AS _quantity,
        -- ord_payment_datetime lưu dạng YYYYMMDD integer, không phải timestamp
        toDate(toString(o.ord_payment_datetime), 'YYYYMMDD') AS _payment_date
    FROM geadb__bronze.nh_order            AS o
    INNER JOIN geadb__bronze.nh_order_item AS oi  ON o.ord_id  = oi.ord_id
    INNER JOIN geadb__bronze.nh_customer   AS cus ON o.cus_id  = cus.cus_id
    CROSS JOIN params                      AS pm
    WHERE o.ord_deleted           = 0
      AND oi.ordi_deleted         = 0
      AND o.parent_id             = 0
      AND o.ord_payment_datetime != 0
      AND o.ord_payment_datetime >= toUInt32(formatDateTime(pm.date_cutoff_pst, '%Y%m%d'))
      AND has(pm.seller_emails, lower(cus.cus_email))
),

-- V3: POD platform — đơn qua hệ thống mới, lọc qua team owner
-- Exclude TW- vì đó là đơn migrate từ V1 (đã có trong base_orders_v1v2)
base_orders_v3 AS (
    SELECT
        toString(o.order_id)                     AS _order_id,
        toInt32(oi.item_quantity)                 AS _quantity,
        -- paid_at lưu UTC, convert sang PST để đồng nhất với V1
        toDate(o.paid_at, 'America/Los_Angeles') AS _payment_date
    FROM gea_seller__bronze.sc_order                 AS o
    INNER JOIN gea_seller__bronze.sc_order_line_item AS oi ON o.order_id  = oi.order_id
    INNER JOIN gea_iam__bronze.iam_team              AS t  ON o.team_id   = t.team_id
    INNER JOIN gea_iam__bronze.iam_user              AS u  ON t.owner_id  = u.user_id
    CROSS JOIN params                                AS pm
    WHERE o.payment_status = 'success'
      AND o.order_id NOT LIKE 'TW-%'
      AND toTimeZone(o.paid_at, 'America/Los_Angeles') >= pm.date_cutoff_pst
      AND has(pm.seller_emails, lower(u.gm_email))
),

all_orders AS (
    SELECT _order_id, _quantity, _payment_date FROM base_orders_v1v2
    UNION ALL
    SELECT _order_id, _quantity, _payment_date FROM base_orders_v3
)

SELECT
    formatDateTime(toStartOfMonth(_payment_date), '%Y-%m') AS payment_month,
    count(DISTINCT _order_id)                               AS orders,
    sum(_quantity)                                          AS units
FROM all_orders
GROUP BY payment_month
ORDER BY payment_month

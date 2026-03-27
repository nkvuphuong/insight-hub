-- =============================================================
-- BI-786: Top 10 sellers theo mug volume — 2024 vs 2025
-- Source: V1 (nh_order, ordi_type=1) + V3 (sc_order, product_type_id=2)
-- Exclude overlap: V1 exclude cus_id=19968 (V3 platform user)
--                  V3 exclude order_id LIKE 'TW-%' (migrated from V1)
-- Units = ordi_quantity × attr_quantity (V1)
--       = item_quantity × gm_product_option.quantity (V3)
-- =============================================================

WITH base_orders_v1 AS (
    SELECT
        c.cus_email                                                           AS _seller_email,
        toDateTime64(YYYYMMDDToDate(o.ord_payment_datetime), 6, 'America/Los_Angeles') AS _payment_date,
        oi.ordi_quantity * a.attr_quantity                                    AS _units
    FROM geadb__bronze.nh_order AS o
    INNER JOIN geadb__bronze.nh_order_item AS oi ON o.ord_id = oi.ord_id
    INNER JOIN geadb__bronze.nh_attribute AS a   ON oi.ordi_size = a.attr_id
    INNER JOIN geadb__bronze.nh_customer AS c    ON o.cus_id = c.cus_id
    WHERE o.parent_id = 0
      AND o.ord_payment_datetime >= 20240101
      AND o.ord_payment_datetime < 20260101
      AND o.ord_deleted = 0
      AND oi.ordi_deleted = 0
      AND o.cus_id != 19968        -- exclude V3 platform user → prevent overlap
      AND oi.ordi_type = 1         -- mug
),

base_orders_v3 AS (
    SELECT
        u.gm_email                                                            AS _seller_email,
        o.paid_at                                                             AS _payment_date,
        oi.item_quantity * po.quantity                                        AS _units
    FROM gea_seller__bronze.sc_order AS o
    INNER JOIN gea_seller__bronze.sc_order_line_item AS oi ON o.order_id = oi.order_id
    INNER JOIN gea_seller__bronze.gm_product_variant AS v  ON oi.variant_id = v.variant_id
    INNER JOIN gea_seller__bronze.gm_product_option AS po
        ON po.type = 2
        AND v.option2_code = po.code
        AND v.product_id = po.product_id
    INNER JOIN gea_seller__bronze.gm_product AS p          ON oi.product_id = p.product_id
    INNER JOIN gea_iam__bronze.iam_team AS t               ON o.team_id = t.team_id
    INNER JOIN gea_iam__bronze.iam_user AS u               ON t.owner_id = u.user_id
    WHERE o.paid_at >= toDateTime64('2024-01-01 00:00:00', 6, 'America/Los_Angeles')
      AND o.paid_at <  toDateTime64('2026-01-01 00:00:00', 6, 'America/Los_Angeles')
      AND o.order_id NOT LIKE 'TW-%'   -- exclude migrated V1 orders → prevent overlap
      AND o.payment_status = 'success'
      AND p.product_type_id = 2        -- mug
),

agg AS (
    SELECT
        toYear(toTimeZone(_payment_date, 'America/Los_Angeles')) AS year,
        _seller_email                                            AS seller_email,
        sum(_units)                                              AS mug_units
    FROM (
        SELECT * FROM base_orders_v1
        UNION ALL
        SELECT * FROM base_orders_v3
    )
    GROUP BY year, seller_email
),

ranked AS (
    SELECT
        year,
        seller_email,
        mug_units,
        row_number() OVER (PARTITION BY year ORDER BY mug_units DESC) AS rn
    FROM agg
)

SELECT
    year,
    seller_email,
    mug_units
FROM ranked
WHERE rn <= 10
ORDER BY year ASC, mug_units DESC

-- =============================================================
-- Q2: Volume by product type — Standard Tier outreach
-- Campaign: CS reach out với giá giảm cho Apparel/Sticker/Poster/Mug
-- Period: 2025-10-01 → hiện tại (Q4 2025 + Q1 2026)
-- =============================================================
--
-- Mục đích: Xác định vol từng product type cho từng seller Standard Tier
-- để CS biết seller đang tập trung vào product nào → gửi offer phù hợp.
--
-- Tier filter: tier_id = 'sale_price' (Standard/Bronze — level 1)
-- Để thay đổi tier: sửa điều kiện WHERE team_tier.tier_id = '...'
--   sale_price   → Bronze  (level 1)
--   price_5000   → Silver  (level 2)
--   price_15000  → Gold    (level 3)
--   price_30000  → Platinum(level 4)
--   price_50000  → Diamond (level 5)
--
-- Units = po.quantity × oi.item_quantity
--   po.quantity    = số đơn vị per option (vd: 1 shirt = 1 unit)
--   oi.item_quantity = số lượng item trong line item
--
-- Join path:
--   sc_order → sc_order_line_item (order_id)
--           → gm_product_variant  (variant_id)   → lấy option2_code (size)
--           → gm_product_option   (product_id + type=2 + option2_code=code) → quantity per size
--           → gm_product          (product_id)   → lấy product_type_id
--           → gm_product_type     (id)           → product type name
--   sc_order → iam_team (team_id) → iam_user (owner_id) → email
--   iam_team → gm_team_price_tier (team_id) → filter tier
--
-- gm_product_option.type = 2: option type cho size (phân biệt với type khác như color)
-- =============================================================

WITH base_data AS (
    SELECT
        u.gm_email                        AS _seller_email,
        t.team_id                         AS _team_id,
        oi.order_id                       AS _order_id,
        oi.item_id                        AS _item_id,
        pt.name                           AS _product_type,
        p.product_id                      AS _product_id,
        oi.variant_id                     AS _variant_id,
        po.code                           AS _option_code,
        v.option2_code                    AS _size_code,
        po.quantity                       AS _option_qty,
        oi.item_quantity                  AS _item_qty,
        -- Units = số đơn vị thực tế (option qty × item qty)
        po.quantity * oi.item_quantity    AS _units,
        o.paid_at                         AS _paid_at
    FROM gea_seller__bronze.sc_order AS o
    -- Line items của order
    INNER JOIN gea_seller__bronze.sc_order_line_item AS oi
        ON o.order_id = oi.order_id
    -- Variant để lấy size code (option2_code)
    INNER JOIN gea_seller__bronze.gm_product_variant AS v
        ON oi.variant_id = v.variant_id
    -- Option để lấy quantity per size (type=2: size option)
    INNER JOIN gea_seller__bronze.gm_product_option AS po
        ON po.type = 2
        AND v.option2_code = po.code
        AND v.product_id = po.product_id
    -- Product để lấy product_type_id
    INNER JOIN gea_seller__bronze.gm_product AS p
        ON oi.product_id = p.product_id
    -- Product type name (Apparel / Sticker / Poster / Mug / ...)
    INNER JOIN gea_seller__bronze.gm_product_type AS pt
        ON p.product_type_id = pt.id
    -- Seller info
    INNER JOIN gea_iam__bronze.iam_team AS t
        ON o.team_id = t.team_id
    INNER JOIN gea_iam__bronze.iam_user AS u
        ON t.owner_id = u.user_id
    -- Tier filter
    INNER JOIN gea_seller__bronze.gm_team_price_tier AS team_tier
        ON t.team_id = team_tier.team_id
    WHERE o.paid_at >= '2024-01-01 00:00:00'
      AND team_tier.tier_id = 'sale_price'  -- Standard/Bronze tier
)

SELECT
    _seller_email,
    coalesce(sumIf(_units, _product_type = 'Apparel'), 0) AS apparel_vol,
    coalesce(sumIf(_units, _product_type = 'Sticker'), 0) AS sticker_vol,
    coalesce(sumIf(_units, _product_type = 'Poster'),  0) AS poster_vol,
    coalesce(sumIf(_units, _product_type = 'Mug'),     0) AS mug_vol,
    coalesce(sumIf(_units, _product_type NOT IN ('Apparel', 'Sticker', 'Poster', 'Mug')), 0) AS others_vol,
    coalesce(sum(_units), 0) AS total_vol
FROM base_data
GROUP BY _seller_email
ORDER BY total_vol DESC

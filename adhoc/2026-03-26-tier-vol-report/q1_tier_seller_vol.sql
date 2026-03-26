-- =============================================================
-- Q1: Seller list by tier (Gold / Platinum / Diamond) + vol by product type
-- Campaign: Promotion outreach — Poster (Gold/Platinum/Diamond) + Standard Tier
-- Period: 2024-01-01 → hiện tại
-- =============================================================
--
-- Tier mapping (gm_product_price_tier):
--   price_15000 → Gold   (level 3)
--   price_30000 → Platinum (level 4)
--   price_50000 → Diamond  (level 5)
--
-- Vol source: sc_order (V3 platform) — tiers là khái niệm của V3
-- Product type: classify từ sc_order_line_item.variant_name
--
-- gm_team_price_tier là SharedReplacingMergeTree:
--   Dùng FINAL để lấy assignment hiện tại (mỗi team có 1 tier active)
-- =============================================================

WITH
current_tiers AS (
    SELECT team_id, tier_id
    FROM gea_seller__bronze.gm_team_price_tier FINAL
    WHERE tier_id IN ('price_15000', 'price_30000', 'price_50000')
),

vol AS (
    SELECT
        o.team_id,
        multiIf(
            oi.variant_name ILIKE '%mug%' OR oi.variant_name ILIKE '%tumbler%' OR oi.variant_name ILIKE '%cup%', 'Mug',
            oi.variant_name ILIKE '%poster%' OR oi.variant_name ILIKE '%canvas%',             'Poster',
            oi.variant_name ILIKE '%sticker%',                                                'Sticker',
            oi.variant_name ILIKE '%shirt%' OR oi.variant_name ILIKE '%hoodie%'
                OR oi.variant_name ILIKE '%tee%' OR oi.variant_name ILIKE '%sweatshirt%'
                OR oi.variant_name ILIKE '%jacket%' OR oi.variant_name ILIKE '%fleece%',      'Apparel',
            'Other'
        ) AS product_type,
        count(DISTINCT o.order_id) AS orders,
        sum(oi.item_quantity)      AS units
    FROM gea_seller__bronze.sc_order AS o
    INNER JOIN gea_seller__bronze.sc_order_line_item AS oi ON o.order_id = oi.order_id
    WHERE o.payment_status = 'success'
      AND toDate(o.paid_at, 'America/Los_Angeles') >= '2024-01-01'
    GROUP BY o.team_id, product_type
)

SELECT
    multiIf(
        t.tier_id = 'price_15000', 'Gold',
        t.tier_id = 'price_30000', 'Platinum',
        'Diamond'
    )                                                     AS tier,
    team.team_id,
    team.name                                             AS team_name,
    u.gm_email                                            AS email,
    sumIf(v.units,  v.product_type = 'Apparel')           AS apparel_units,
    sumIf(v.units,  v.product_type = 'Poster')            AS poster_units,
    sumIf(v.units,  v.product_type = 'Mug')               AS mug_units,
    sumIf(v.units,  v.product_type = 'Sticker')           AS sticker_units,
    sumIf(v.units,  v.product_type = 'Other')             AS other_units,
    sum(v.units)                                          AS total_units,
    countDistinct(v.orders) -- placeholder, see note
FROM current_tiers AS t
INNER JOIN gea_iam__bronze.iam_team AS team ON t.team_id = team.team_id
INNER JOIN gea_iam__bronze.iam_user AS u    ON team.owner_id = u.user_id
LEFT JOIN  vol AS v                          ON t.team_id = v.team_id
GROUP BY tier, team.team_id, team.name, u.gm_email
ORDER BY
    multiIf(t.tier_id = 'price_50000', 1, t.tier_id = 'price_30000', 2, 3) ASC,
    total_units DESC

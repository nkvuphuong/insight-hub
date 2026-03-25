-- enrich-fact-ofp-rush-order: Backfill is_rush
-- Chạy sau khi ALTER TABLE đã add column is_rush UInt8 DEFAULT 0
-- Expected: ~22,613 rows updated trong fact_ofp; ~24,013 rows trong by_product
--
-- Verify trước khi chạy:
--   SELECT count() FROM gea__silver.fact_order_fulfillment_performance FINAL
--   WHERE order_id IN (SELECT toUInt64(rush_order_id) FROM geadb__bronze.nh_rush_order_data WHERE rush_status = 1)
--   -- expect: 22613

-- Step 1: Backfill fact_order_fulfillment_performance
ALTER TABLE gea__silver.fact_order_fulfillment_performance
    UPDATE is_rush = 1
    WHERE order_id IN (
        SELECT toUInt64(rush_order_id)
        FROM geadb__bronze.nh_rush_order_data FINAL
        WHERE rush_status = 1
    );

-- Step 2: Backfill fact_order_fulfillment_performance_by_product
ALTER TABLE gea__silver.fact_order_fulfillment_performance_by_product
    UPDATE is_rush = 1
    WHERE order_id IN (
        SELECT toUInt64(rush_order_id)
        FROM geadb__bronze.nh_rush_order_data FINAL
        WHERE rush_status = 1
    );

-- Verify sau khi chạy (chờ mutation xong):
-- SELECT is_rush, count() FROM gea__silver.fact_order_fulfillment_performance FINAL GROUP BY is_rush;
-- SELECT is_rush, count() FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL GROUP BY is_rush;
-- Check mutation status:
-- SELECT * FROM system.mutations WHERE table LIKE 'fact_order_fulfillment%' AND is_done = 0;

-- Step 1 — ALTER TABLE: thêm column is_platform
-- Chạy file này TRƯỚC step1_recreate_mv.sql
--
-- Non-breaking: DEFAULT 0 → existing rows không bị ảnh hưởng
-- Existing queries không cần thay đổi
-- is_platform sẽ được populate đúng sau MV refresh đầu tiên (~4h)

ALTER TABLE gea__silver.fact_order_fulfillment_performance
    ADD COLUMN IF NOT EXISTS is_platform UInt8 DEFAULT 0
        COMMENT 'Platform order flag: 1 = is_label=1 trong nh_order_source (customer tự mang label hoặc Ship by GM), 0 = Standard (Gearment mua label qua hệ thống riêng)';

-- Verify ngay sau khi chạy:
-- DESCRIBE TABLE gea__silver.fact_order_fulfillment_performance;
-- → thấy is_platform UInt8 DEFAULT 0

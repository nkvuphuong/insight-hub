## 1. Discovery → Spec Confirmed [gate: Phuong confirm]

- [x] 1.1 Explore `nh_rush_order_data` schema — xác nhận columns, types, semantic
- [x] 1.2 Xác nhận: `rush_status = 1` = rush order thật; `rush_status = 0` = capacity slot (rush_order_id = 0)
- [x] 1.3 Xác nhận: `rush_order_id` Int64 → cần `toUInt64()` khi join với fact table UInt64
- [x] 1.4 Xác nhận: cả `rush_over = 0` và `rush_over = 1` đều flag `is_rush = 1`
- [x] 1.5 Design decision: chỉ thêm `is_rush UInt8`, không expose `rush_over` hay `cro_id`

## 2. ALTER TABLE — Thêm cột [gate: Phuong confirm spec-confirmed]

- [x] 2.1 `ALTER TABLE fact_order_fulfillment_performance ADD COLUMN is_rush UInt8 DEFAULT 0`
- [x] 2.2 Verify cột đã xuất hiện trong schema (SELECT * LIMIT 1, kiểm tra is_rush = 0 default)
- [x] 2.3 `ALTER TABLE fact_order_fulfillment_performance_by_product ADD COLUMN is_rush UInt8 DEFAULT 0`
- [x] 2.4 Verify cột đã xuất hiện trong by_product table

## 3. Backfill UPDATE [SKIP — không cần]

> Cả 2 MV đều là Refreshable MV (`REFRESH EVERY 4 HOUR`) — mỗi lần refresh chạy lại toàn bộ SELECT,
> ghi đè hoàn toàn vào target table. CREATE MV mới với `is_rush` là đủ; không cần ALTER TABLE UPDATE.

- [x] 3.1 ~~Chạy UPDATE~~ — N/A, covered bởi MV refresh
- [x] 3.2 ~~Verify backfill count~~ — N/A
- [x] 3.3 ~~Chạy UPDATE by_product~~ — N/A
- [x] 3.4 ~~Verify by_product count~~ — N/A
- [x] 3.5 ~~Sanity check~~ — verify sau khi MV refresh (task 4.4, 4.8)

## 4. MV Update [gate: sau khi backfill verified]

- [x] 4.1 Đọc DDL hiện tại của `mv__fact_order_fulfillment_performance` — xác định chỗ cần thêm JOIN
- [x] 4.2 Test SELECT (phần AS SELECT của MV) standalone — file viết sẵn: `sql/02_test_mv_select_fact_ofp.sql` (spot-check JOIN logic confirmed với 4 known rush orders)
- [x] 4.3 DROP + CREATE `mv__fact_order_fulfillment_performance` với LEFT JOIN `nh_rush_order_data` + `is_rush`
- [x] 4.4 Verify MV: is_rush=1 count = 22,613 — khớp expected
- [x] 4.5 Đọc DDL hiện tại của `mv__fact_order_fulfillment_performance_by_product`
- [x] 4.6 Test SELECT của by_product MV standalone — file viết sẵn: `sql/04_mv_fact_ofp_by_product.sql` (cùng pattern)
- [x] 4.7 DROP + CREATE `mv__fact_order_fulfillment_performance_by_product` với `is_rush`
- [x] 4.8 Verify by_product MV: is_rush=1 count = 24,013 — khớp expected

## 5. Schema Docs + Changelog [gate: sau khi MV verified]

- [x] 5.1 Cập nhật `docs/schema/gea__silver.md` — thêm `is_rush` vào 2 fact tables
- [x] 5.2 Ghi `docs/CHANGELOG.md` — entry enrich-fact-ofp-rush-order done

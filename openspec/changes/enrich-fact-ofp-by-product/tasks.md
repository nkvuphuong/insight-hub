## 1. Explore [gate: Phuong confirm spec-confirmed]

- [x] 1.1 Đọc DDL của `fact_order_fulfillment_performance_by_product` — SharedReplacingMergeTree, version=updated_at, partition=toYYYYMM(paid_at_utc), sort=(paid_at_utc, product_type, ordx_fulfill_locate, order_id)
- [x] 1.2 Đọc DDL của `mv__fact_order_fulfillment_performance_by_product` — REFRESH EVERY 4 HOUR (full refresh), source: nh_transaction→nh_order→nh_order_item→nh_product_type→nh_order_extra→nh_order_activities
- [x] 1.3 Verify row counts: baseline by_product = 1,494,477 (567,025 Platform / 927,452 Standard via nh_order_source join)
- [x] 1.4 Confirm join key: by_product.order_id = UInt64, nh_order_source.ord_id = UInt64 — match, no cast needed
- [x] 1.5 design.md không cần update — approach (join fact_ofp) đơn giản hơn nên chuyển thành join nh_order_source trực tiếp (tương tự enrich-fact-ofp-platform); Refreshable MV không cần manual backfill

## 2. Step 1 — Add `is_platform` [gate: step1-verified]

- [x] 2.1 Test SELECT: by_product JOIN nh_order_source → is_label = 1 cho Platform orders — verified (20 sample rows đúng product types)
- [x] 2.2 Viết `sql/step1_add_is_platform.sql` — ALTER TABLE + DROP MV + CREATE MV mới với is_platform (join nh_order_source). Fix: toInt64(nh_order_source.ord_id) do type mismatch Int64/UInt64. SELECT verified qua MCP.
- [x] 2.3 Chạy ALTER TABLE + DROP MV + CREATE MV (Phuong chạy trực tiếp)
- [x] 2.4 Trigger refresh: SYSTEM REFRESH VIEW — done
- [x] 2.5 ~~Backfill~~ — không cần, Refreshable MV tự refresh toàn bộ history
- [x] 2.6 Verify: platform=567,099 / standard=927,543 / total=1,494,642 ✓ (±165 do new orders) | platform_with_scan=0 ✓ (Step 2 chưa chạy)

## 3. Step 2 — Fix tracking timestamps cho Platform [gate: step2-verified]

- [x] 3.1 Test SELECT: COALESCE logic verified — Platform 15350007 nhận first_scanned_at từ USPS (2026-01-29 15:15:08), Standard không đổi
- [x] 3.2 Viết `sql/step2_fix_tracking_timestamps.sql` — full MV DDL (is_platform + COALESCE tracking). Note: renamed nh_product_type alias pt → pt_type (conflict với USPS pt alias)
- [x] 3.3 DROP MV + CREATE MV mới (chạy trực tiếp trên ClickHouse — không qua MCP)
      → File: openspec/changes/enrich-fact-ofp-by-product/sql/step2_fix_tracking_timestamps.sql
- [x] 3.4 Trigger refresh: SYSTEM REFRESH VIEW gea__silver.mv__fact_order_fulfillment_performance_by_product
- [x] 3.5 Verify: countIf(is_platform=1 AND first_scan_day IS NOT NULL) > 0 (baseline=0)
      → platform_with_scan=118,267 ✓
- [x] 3.6 Verify: Standard rows không đổi — standard_with_scan ≈ 627,368, avg values nhất quán
      → standard_with_scan=627,417 ✓ | platform_total=567,221 | standard_total=928,225

## 4. Wrap-up [gate: done]

- [x] 4.1 Ghi `docs/CHANGELOG.md` — entry enrich-fact-ofp-by-product
- [x] 4.2 Update `openspec/changes/ops-sla-drilldown/tasks.md` — remove dependency note, confirm data ready

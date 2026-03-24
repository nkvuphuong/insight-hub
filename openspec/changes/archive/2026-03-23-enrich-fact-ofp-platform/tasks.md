# Tasks — enrich-fact-ofp-platform

> **Approach:** Incremental — từng step nhỏ, verify trước khi tiếp.
> **Reference:** Đọc `logic-reference.md` để hiểu logic hiện tại. Đọc `design.md` để hiểu approach và SQL chi tiết.

---

## ~~Step 1 — Thêm `is_platform` flag~~ ✓ [gate: step1-verified — 2026-03-23]

**Source:** `geadb__bronze.nh_order_source.is_label`

- [x] 1.1 DDL MV hiện tại — confirmed qua MCP
- [x] 1.2 ALTER TABLE — `is_platform UInt8 DEFAULT 0` với comment ✓
- [x] 1.3 DROP + CREATE MV mới — subquery FINAL, toInt64() cast, test SELECT trước
- [x] 1.4 Verify — column exists, MV scheduled (next refresh 08:00 UTC)
- [x] 1.5 Phuong confirm ✓

**Lessons learned:**
- ClickHouse không hỗ trợ `CREATE OR REPLACE MATERIALIZED VIEW`
- `FINAL AS alias` không hợp lệ trong JOIN → dùng subquery với FINAL bên trong
- Type mismatch Int64/UInt64 trong JOIN ON → cast tường minh `toInt64()`
- Test SELECT standalone trước khi DROP+CREATE MV

---

## ~~Step 2 — Fix `first_scanned_at` + `delivered_at` cho Platform own-label orders~~ ✓ [gate: step2-verified — 2026-03-23]

> Bắt đầu sau khi Step 1 verified.

**Mục tiêu:** `first_scan_day` và `shipping_day` đúng cho Platform orders dùng own USPS label.
**Source:** `gea__bronze.usps_tracking_event` (direct — không join view, không join lookup table)

**Event code mapping đã verified:**
- PRE-TRANSIT (loại trừ): `89, GC, GX, MA, VP`
- DELIVERED: `01, 13, 43, 60, 61, 62, 63, LD`

### ~~2.1 Test SELECT standalone trước khi implement~~ ✓

```sql
-- Test subquery `pt` — chạy standalone để verify type và kết quả
SELECT
    toInt64(ord_id) AS ord_id,
    minIf(GMTTimestamp, eventCode NOT IN ('89','GC','GX','MA','VP')
          AND eventType != 'Tracking Not Available') AS platform_first_scan_utc,
    minIf(GMTTimestamp, eventCode IN ('01','13','43','60','61','62','63','LD'))
          AS platform_delivered_utc
FROM gea__bronze.usps_tracking_event
WHERE ord_id BETWEEN 14648328 AND 14700000
GROUP BY ord_id
LIMIT 5;
```

### ~~2.2 Viết file `sql/step2_recreate_mv.sql`~~ ✓

Dựa trên `step1_recreate_mv.sql`, thêm:
- Subquery `pt` trong `base_order_data` — xem `design.md → Step 2 (A)`
- COALESCE cho `first_scanned_at_utc` và `delivered_at_utc` — xem `design.md → Step 2 (B)`
- **nullIf bắt buộc:** `nullIf(oa.first_scanned_at_utc, toDateTime(0, 'UTC'))` vì `minIf` trả epoch khi không match
- **Type cast bắt buộc:** `toInt64(ord_id)` trong subquery `pt` (ord_id là `Int32`)
- **Type cast bắt buộc:** `toDateTime(pt.platform_*_utc, 'UTC')` khi COALESCE (DateTime64 → DateTime)

### ~~2.3 Test SELECT toàn bộ MV body standalone (không DROP)~~ ✓

```sql
-- Chạy SELECT body (không có DROP/CREATE) để confirm không lỗi
-- ... paste toàn bộ AS WITH ... SELECT ... FROM business_hour_metrics
LIMIT 10
```

### ~~2.4 DROP + CREATE MV~~ ✓

```sql
DROP TABLE IF EXISTS gea__silver.mv__fact_order_fulfillment_performance;
-- Sau đó chạy CREATE từ step2_recreate_mv.sql
```

### ~~2.5 Verify sau refresh (~4h)~~ ✓

```sql
SELECT
    is_platform,
    countIf(first_scan_day IS NOT NULL) AS has_first_scan,
    countIf(first_scan_day IS NULL)     AS no_first_scan,
    countIf(shipping_day IS NOT NULL)   AS has_shipping,
    countIf(shipping_day IS NULL)       AS no_shipping,
    count()                             AS total
FROM gea__silver.fact_order_fulfillment_performance FINAL
GROUP BY is_platform;

-- Expected:
-- is_platform=0: has_first_scan >> no_first_scan (Standard không đổi)
-- is_platform=1: has_first_scan tăng đáng kể so với trước Step 2
--   → ~168K orders sẽ có first_scan_day (own USPS label, ord_id 14.6M+)
--   → còn lại NULL = Platform non-USPS label (không có tracking data, acceptable)
```

### ~~2.6 Phuong confirm~~ ✓ → unblock order-sla Gate 6

---

## ~~Step 3 — Unblock order-sla Gate 6~~ ✓ [gate: sql-refactored — 2026-03-23]

Sau khi fact_ofp có `is_platform` và `first_scan_day` đúng:

- [x] Rewrite `reports/order-sla/queries/sla_standard.sql` — `WHERE is_platform = 0`, bỏ LEFT ANTI JOIN
- [x] Rewrite `reports/order-sla/queries/sla_platform.sql` — `WHERE is_platform = 1 AND first_scan_day IS NOT NULL`, `floor(processing_day + first_scan_day)` thay cho `business_days_exclude_payment`
- [x] Verify row counts khớp v0.3 (Standard: ±4 orders, Platform: ±700 orders tháng gần nhất)
- [x] Update CSV cache

**Kết quả verify:**
- Standard: numbers khớp v0.3 gần như hoàn toàn ✓
- Platform: total_orders khớp (~±100), pass_rate cao hơn v0.3 (+2–9%) do formula khác (floor sum vs business_days_exclude_payment) — expected, đã documented

---

## Dependencies

- Step 1 → Step 2 → Step 3 (sequential, gate sau Phuong confirm)
- Step 3 unblocks `order-sla` Gate 6 (sql-refactored)

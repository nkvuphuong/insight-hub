## Context

Enrich 2 silver fact tables với `is_rush` flag từ `geadb__bronze.nh_rush_order_data`.

Pattern giống hệt `enrich-fact-ofp-platform` (đã done): ALTER TABLE + backfill UPDATE + MV update.

## Source Table — `nh_rush_order_data`

```
geadb__bronze.nh_rush_order_data   (SharedReplacingMergeTree, cần FINAL)
  rush_id          Int64    PK
  cro_id           Int64    Campaign/program ID (13 programs hiện tại, dominant = cro_id=6)
  rush_order_id    Int64    FK → nh_order.ord_id  (⚠️ Int64, fact table dùng UInt64 → cần cast)
  rush_status      Int16    0 = slot chưa dùng (rush_order_id = 0, không phải order thật)
                            1 = rush order xác nhận
  rush_over        Int16    0 = trong slot capacity
                            1 = vượt slot nhưng vẫn được accept
  rush_datetime    Int64    Ngày rush dạng YYYYMMDD (ví dụ: 20240602) — KHÔNG phải unix timestamp
  created_time     Int64    Unix timestamp — thời điểm slot được tạo/assign
  used_time        Int64    Unix timestamp — thời điểm order confirm rush
  updated_time     DateTime64(0,'UTC')
```

**Lọc rush orders thật:** `WHERE rush_status = 1` (loại bỏ `rush_status = 0` vì `rush_order_id = 0`)

**Duplicate handling:** ~50 orders có >1 row trong FINAL (CDC artifact). Dùng `FINAL` là đủ vì SharedReplacingMergeTree dedup theo `rush_id`.

## Decisions

### D1: `is_rush` = 1 khi và chỉ khi `rush_status = 1`

Cả `rush_over = 0` (trong slot) và `rush_over = 1` (vượt slot) đều là rush orders xác nhận → cùng flag `is_rush = 1`. Không expose `rush_over` riêng trừ khi có yêu cầu cụ thể.

### D2: Type cast bắt buộc — `toUInt64(rush_order_id)`

`rush_order_id` là `Int64`, `fact_ofp.order_id` là `UInt64`. ClickHouse không tự cast trong JOIN → luôn dùng `toUInt64(rush_order_id)` ở vế join.

### D3: LEFT JOIN (không phải INNER JOIN)

Hầu hết orders không phải rush → LEFT JOIN để giữ tất cả orders, `is_rush` = 0 cho non-rush.

### D4: Backfill bằng UPDATE, không rebuild

Giống `enrich-fact-ofp-platform`: `ALTER TABLE ADD COLUMN` → `ALTER TABLE UPDATE` để backfill. Không DROP + recreate table — tránh mất data và downtime.

## SQL Approach

### Step 1 — ALTER TABLE (cả 2 tables)

```sql
ALTER TABLE gea__silver.fact_order_fulfillment_performance
    ADD COLUMN IF NOT EXISTS is_rush UInt8 DEFAULT 0;

ALTER TABLE gea__silver.fact_order_fulfillment_performance_by_product
    ADD COLUMN IF NOT EXISTS is_rush UInt8 DEFAULT 0;
```

### Step 2 — Backfill UPDATE

```sql
-- Build rush order set
-- fact_order_fulfillment_performance
ALTER TABLE gea__silver.fact_order_fulfillment_performance
    UPDATE is_rush = 1
    WHERE order_id IN (
        SELECT toUInt64(rush_order_id)
        FROM geadb__bronze.nh_rush_order_data FINAL
        WHERE rush_status = 1
    );

-- fact_order_fulfillment_performance_by_product
ALTER TABLE gea__silver.fact_order_fulfillment_performance_by_product
    UPDATE is_rush = 1
    WHERE order_id IN (
        SELECT toUInt64(rush_order_id)
        FROM geadb__bronze.nh_rush_order_data FINAL
        WHERE rush_status = 1
    );
```

### Step 3 — Verify backfill

```sql
-- Expect: ~174K rows với is_rush = 1 trong fact_ofp
SELECT is_rush, count() FROM gea__silver.fact_order_fulfillment_performance FINAL
GROUP BY is_rush;

-- Expect: số tương tự hoặc cao hơn một chút trong by_product (nhiều rows/order)
SELECT is_rush, count() FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL
GROUP BY is_rush;
```

### Step 4 — MV Update

Thêm LEFT JOIN vào SELECT của cả 2 MV để orders mới được flag tự động:

```sql
-- Trong SELECT của MV:
LEFT JOIN (
    SELECT DISTINCT toUInt64(rush_order_id) AS oid
    FROM geadb__bronze.nh_rush_order_data FINAL
    WHERE rush_status = 1
) rush ON <order_id_expr> = rush.oid

-- Thêm vào SELECT list:
if(rush.oid > 0, 1, 0) AS is_rush
```

> ⚠️ **Test SELECT trước khi DROP+CREATE MV** — copy phần `AS (SELECT ...)` ra chạy standalone verify không có lỗi trước.

## Risks / Caveats

**[Risk] MV reads `nh_rush_order_data FINAL` tại insert time** — nếu rush assignment đến sau order insert, `is_rush` sẽ không được cập nhật tự động trong MV. Workaround: chạy backfill UPDATE định kỳ (hàng ngày), hoặc chấp nhận độ trễ nhỏ.

**[Caveat] `rush_datetime` là YYYYMMDD Int64** — không dùng `toDateTime()` trực tiếp, dùng `toDate(toString(rush_datetime))` nếu cần.

**[Caveat] `rush_status = 0` rows có `rush_order_id = 0`** — đây là capacity slots, không phải orders. Filter `rush_status = 1` là đủ để loại.

**[Caveat] Data coverage từ Nov 2023** — orders trước đó không có rush data. `is_rush = 0` cho tất cả pre-Nov 2023 orders là đúng về nghiệp vụ (chương trình chưa có).

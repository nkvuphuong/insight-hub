## Context

`fact_order_fulfillment_performance_by_product` (grain = order × product_type) được populate bởi `mv__fact_order_fulfillment_performance_by_product`. Hiện tại:

- Platform orders **có** trong bảng (confirmed) nhưng không có `is_platform` flag
- Tracking timestamps (`first_scanned_at`, `first_scan_hour`, `first_scan_day`, `delivered_at`, `shipping_hour`, `shipping_day`) của Platform orders = NULL — vì MV lấy từ `nh_order_activities`, Platform không có data ở đó

Sau `enrich-fact-ofp-platform`, `fact_order_fulfillment_performance` đã có `is_platform` và tracking timestamps đúng cho Platform. Change này propagate data đó sang `by_product`.

## Approach — Kế thừa từ enriched `fact_ofp`

Thay vì re-join `nh_order_source` và `usps_tracking_event` (đã làm trong `enrich-fact-ofp-platform`), join ngược `by_product.order_id → fact_ofp.order_id` để lấy:

```
fact_ofp (enriched):
  - is_platform                  → thêm vào by_product
  - first_scanned_at_utc         → COALESCE với by_product.first_scanned_at
  - delivered_at_utc             → COALESCE với by_product.delivered_at
  - first_scan_hour, first_scan_day   → COALESCE
  - shipping_hour, shipping_day       → COALESCE
```

Pattern join: `by_product.order_id = fact_ofp.order_id` — 1:1 (một order có 1 row trong fact_ofp, nhiều rows trong by_product do multi-product; join sẽ fanout nhưng fact_ofp values giống nhau).

## Decisions

### D1: Nguồn tracking data — fact_ofp, không re-join USPS events

`fact_ofp` đã có kết quả đúng (verified trong `enrich-fact-ofp-platform`). Join một bảng đã enriched đơn giản và an toàn hơn re-implement toàn bộ COALESCE logic. Dependency tường minh: `enrich-fact-ofp-by-product` depends on `enrich-fact-ofp-platform`.

### D2: COALESCE pattern — ưu tiên fact_ofp enriched values

```sql
COALESCE(
    nullIf(fact_ofp.first_scan_day, 0),
    by_product.first_scan_day
) AS first_scan_day
```

Lý do: `fact_ofp` đã COALESCE từ USPS events — nếu có data thì dùng, không thì fallback về `by_product` gốc (Standard sẽ có sẵn từ order_activities).

### D3: Recreate MV — cùng pattern với `enrich-fact-ofp-platform`

1. Add columns vào table DDL
2. DROP MV cũ
3. CREATE MV mới với JOIN `fact_ofp FINAL` để lấy `is_platform` và tracking timestamps
4. Backfill: INSERT INTO `by_product` SELECT ... từ source đầy đủ

### D4: `is_platform` type — UInt8, default 0

Consistent với `fact_order_fulfillment_performance.is_platform`.

## SQL Sketch

```sql
-- Trong MV mới, thêm JOIN:
LEFT JOIN (
    SELECT
        order_id,
        is_platform,
        first_scanned_at_utc,
        delivered_at_utc,
        first_scan_hour,
        first_scan_day,
        shipping_hour,
        shipping_day
    FROM gea__silver.fact_order_fulfillment_performance FINAL
) AS ofp ON by_product_source.order_id = ofp.order_id

-- Columns mới trong SELECT:
ofp.is_platform AS is_platform,
COALESCE(nullIf(ofp.first_scan_day, 0), source.first_scan_day) AS first_scan_day,
-- tương tự cho các timestamps khác
```

> **Note:** Cần đọc DDL của `mv__fact_order_fulfillment_performance_by_product` và `fact_order_fulfillment_performance_by_product` trước khi viết SQL chính xác — xác định source table của MV và ENGINE của destination table.

## Risks / Trade-offs

**[Risk] MV join `fact_ofp FINAL`** — MV trigger on insert, nhưng `fact_ofp FINAL` dedup at query time. Có thể có timing issue nếu `fact_ofp` chưa có row khi MV trigger. Mitigation: dùng `LEFT JOIN` (not INNER) — worst case `is_platform = 0` (default), không mất row.

**[Risk] Fanout trong JOIN** — by_product có nhiều rows/order (multi-product). JOIN với fact_ofp sẽ broadcast fact_ofp values → không phải vấn đề vì values là order-level, giống nhau cho tất cả product_type của cùng một order.

**[Risk] Backfill** — Sau khi recreate MV, phải INSERT lại toàn bộ history. Cần verify row count trước/sau.

# Spec: fact_order_fulfillment_performance_by_product (enriched)

## Purpose
Thêm `is_platform` và fix tracking timestamps cho Platform orders trong `fact_order_fulfillment_performance_by_product`.

## New Columns

| Column | Type | Source | Ghi chú |
|---|---|---|---|
| `is_platform` | UInt8 | `fact_ofp.is_platform` | 1 = Platform, 0 = Standard |
| `first_scanned_at` | Nullable(DateTime) | COALESCE(fact_ofp, existing) | Fix cho Platform |
| `first_scan_hour` | Nullable(Int32) | COALESCE(fact_ofp, existing) | |
| `first_scan_day` | Nullable(Float32) | COALESCE(fact_ofp, existing) | |
| `delivered_at` | Nullable(DateTime) | COALESCE(fact_ofp, existing) | |
| `shipping_hour` | Nullable(Int32) | COALESCE(fact_ofp, existing) | |
| `shipping_day` | Nullable(Float32) | COALESCE(fact_ofp, existing) | |

## Post-enrich State

- `WHERE is_platform = 0` → Standard orders với đầy đủ tracking data
- `WHERE is_platform = 1` → Platform orders với tracking data từ USPS events (via fact_ofp)
- Standard orders: existing columns không đổi (COALESCE fallback về giá trị cũ)

## Depends On

`enrich-fact-ofp-platform` (archived 2026-03-23) — `fact_ofp.is_platform` và tracking timestamps phải đúng trước.

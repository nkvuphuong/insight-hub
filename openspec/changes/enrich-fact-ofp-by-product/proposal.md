## Audience

**Data engineering / analytics** — enrich schema, không phải end-user report. Output là `fact_order_fulfillment_performance_by_product` có đầy đủ data cho cả Platform và Standard.

## Why

`fact_order_fulfillment_performance_by_product` hiện tại có cùng vấn đề với `fact_order_fulfillment_performance` trước khi có `enrich-fact-ofp-platform`:

1. **Không có `is_platform`** — không phân biệt được Platform vs Standard orders
2. **Platform orders có `first_scan_day`, `shipping_day` = NULL** — tracking timestamps lấy từ `order_activities`, Platform không có data ở đó; cần lấy từ USPS events

Hệ quả: `ops-sla-drilldown` (và bất kỳ báo cáo nào dùng `by_product`) không thể tách Platform/Standard, không tính được SLA pass rate đúng cho Platform.

`enrich-fact-ofp-platform` đã fix `fact_order_fulfillment_performance`. Change này áp dụng pattern tương tự cho `fact_order_fulfillment_performance_by_product`.

## What Changes

- **Thêm `is_platform` (UInt8)** vào `fact_order_fulfillment_performance_by_product` — source: `nh_order_source.is_label` (same as enrich-fact-ofp-platform)
- **Fix `first_scan_day`, `first_scan_hour`, `first_scanned_at`** cho Platform orders — COALESCE từ `fact_order_fulfillment_performance.first_scan_day` (đã được enrich-fact-ofp-platform fix) thay vì re-join USPS events
- **Fix `shipping_day`, `shipping_hour`, `delivered_at`** tương tự — COALESCE từ `fact_ofp` enriched

## Approach

Tận dụng `fact_order_fulfillment_performance` đã được enrich (có `is_platform` và tracking timestamps đúng) — join `by_product.order_id → fact_ofp.order_id` để lấy cả hai. Không cần re-join `usps_tracking_event` hay `nh_order_source` trực tiếp — đơn giản hơn `enrich-fact-ofp-platform`.

## Impact

- **Schema thay đổi:** `gea__silver.fact_order_fulfillment_performance_by_product` — thêm cột, recreate MV
- **Depends on:** `enrich-fact-ofp-platform` (archived 2026-03-23) — `fact_ofp` phải có `is_platform` và tracking timestamps đúng trước
- **Unblocks:** `ops-sla-drilldown` — SQL sẽ dùng `WHERE is_platform = 0/1` thay vì workaround
- **Không ảnh hưởng:** `order-sla` (dùng `fact_ofp` trực tiếp, không dùng `by_product`)

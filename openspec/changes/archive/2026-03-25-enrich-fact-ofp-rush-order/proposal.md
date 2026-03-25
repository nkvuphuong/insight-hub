## Audience

**Data team / SQL layer** — enrich 2 fact tables để downstream reports (order-sla, ops-sla-drilldown, và các báo cáo tương lai) có thể phân tích rush orders mà không cần JOIN thêm ở query layer.

**Downstream consumer:** BOD dashboard, ops drilldown, bất kỳ báo cáo SLA nào cần segment theo rush/non-rush.

## Why

SLA framework hiện tại có 3 tiers: **Rush ≤ 2 biz days**, Platform ≤ 3, Standard ≤ 4. Hiện tại chỉ có Platform và Standard đã được flag trong fact tables (`is_platform`). Rush tier chưa có identifier → không thể đo SLA pass rate cho rush orders.

`geadb__bronze.nh_rush_order_data` đã có data (~174K rush orders từ Nov 2023) nhưng chưa được join vào silver layer.

## What Changes

- **`gea__silver.fact_order_fulfillment_performance`**: thêm cột `is_rush UInt8` (1 = rush order, 0 = không)
- **`gea__silver.fact_order_fulfillment_performance_by_product`**: thêm cột `is_rush UInt8` (giống trên, cùng order_id)
- **MV cập nhật**: `mv__fact_order_fulfillment_performance` và `mv__fact_order_fulfillment_performance_by_product` thêm LEFT JOIN `nh_rush_order_data` để populate `is_rush` cho orders mới

## Capabilities

### New Capabilities

- Segment rush orders trong mọi query SLA: `WHERE is_rush = 1`
- Measure SLA pass rate riêng cho Rush tier (TAL ≤ 2 biz days)
- Cross-dimension: rush × Platform/Standard × product_type × facility

### Modified Capabilities

- `fact_order_fulfillment_performance` — +1 column
- `fact_order_fulfillment_performance_by_product` — +1 column

## Impact

- **Source:** `geadb__bronze.nh_rush_order_data FINAL` — `rush_status = 1` là rush orders xác nhận
- **Join key:** `toUInt64(rush_order_id)` → `fact_ofp.order_id` (type cast cần thiết: Int64 → UInt64)
- **Không thay đổi:** Schema existing columns, downstream reports hiện tại (is_rush = 0 default → backward compatible)
- **Pattern:** Giống `enrich-fact-ofp-platform` — ALTER + backfill UPDATE + MV update

## Biz Validation Questions

- Rush SLA target: ≤ 48 calendar hours hay ≤ 2 biz days? (Ảnh hưởng đến cách tính TAL)
- Ai là owner của rush SLA? Ops hay customer success?
- Có cần dashboard riêng cho rush không, hay chỉ cần filter trong dashboard hiện tại?
- `rush_over = 1` (vượt slot) có cùng SLA commitment không, hay khác tier?

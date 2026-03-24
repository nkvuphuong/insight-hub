# Spec: ops-sla-contribution

## Purpose
Stacked bar chart — avg `processing_day` vs avg `first_scan_day` theo product_type, tách Platform và Standard. Giúp ops identify bottleneck type (production vs carrier handoff) trước khi drill-down.

## Inputs
- `gea__silver.fact_order_fulfillment_performance_by_product FINAL` (Standard)
- `gea__silver.fact_order_fulfillment_performance FINAL` + `geadb__bronze.nh_order_item` + `gea__silver.dict_product_type` (Platform)

## Output Columns
| Column | Type | Ghi chú |
|---|---|---|
| group | String | 'Platform' hoặc 'Standard' |
| product_type | String | tên loại sản phẩm |
| avg_processing_day | Float | avg processing_day |
| avg_first_scan_day | Float | avg first_scan_day |
| avg_tal | Float | avg_processing_day + avg_first_scan_day |
| order_count | UInt64 | số rows (order × product_type) |

## Visualization
Grouped stacked bar: x = product_type, bars tách Platform/Standard, segments = production (xanh) + scan (cam). Reference line ở SLA threshold (3 cho Platform, 4 cho Standard).

## Filters
- Period: 6 tháng gần nhất
- `processing_day IS NOT NULL AND first_scan_day IS NOT NULL`

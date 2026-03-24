# Spec: ops-sla-product-breakdown

## Purpose
Bar chart SLA pass rate (%) theo product_type — 2 panels: Platform (≤3 biz days) và Standard (≤4 biz days). Ops xác định product_type nào cần prioritize.

## Output Columns
| Column | Type | Ghi chú |
|---|---|---|
| group | String | 'Platform' hoặc 'Standard' |
| product_type | String | |
| total_orders | UInt64 | số rows (order × product_type) |
| sla_pass | UInt64 | số rows đạt SLA |
| sla_pass_rate | Float | % đạt SLA |
| avg_processing_day | Float | |
| avg_first_scan_day | Float | |

## Visualization
Horizontal bar chart, sorted by sla_pass_rate ASC (worst on top). 2 panels side by side. Bar annotated với pass% và order count.

## Filters
- Period: 6 tháng gần nhất
- `processing_day IS NOT NULL AND first_scan_day IS NOT NULL`

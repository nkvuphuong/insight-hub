# Spec: ops-sla-location-breakdown

## Purpose
Bar chart SLA pass rate (%) theo `ordx_fulfill_locate` — Platform và Standard. Ops xác định facility nào là bottleneck.

## Output Columns
| Column | Type | Ghi chú |
|---|---|---|
| group | String | 'Platform' hoặc 'Standard' |
| fulfill_location | String | `ordx_fulfill_locate` |
| total_orders | UInt64 | |
| sla_pass | UInt64 | |
| sla_pass_rate | Float | % đạt SLA |
| avg_processing_day | Float | |
| avg_first_scan_day | Float | |

## Visualization
Grouped bar: x = fulfill_location, bars tách Platform/Standard. Annotate với pass% và order count.

## Filters
- Period: 6 tháng gần nhất
- `processing_day IS NOT NULL AND first_scan_day IS NOT NULL`

## Context

Escalation từ `order-sla` (BOD dashboard). Ops team cần drill-down để identify:
1. Bottleneck nào: production (`processing_day`) hay carrier handoff (`first_scan_day`)?
2. Product type nào đang kéo SLA xuống?
3. Facility nào là bottleneck?

Data khảo sát (6 tháng, MCP-verified):

| Group | Product | avg_prod | avg_scan | avg_tal | pass% |
|---|---|---|---|---|---|
| Platform | Poster | 1.58 | **1.96** | 3.53 | **65.3%** |
| Platform | Tumbler | **2.12** | 1.22 | 3.34 | 71.4% |
| Platform | Doormat | 0.91 | **2.54** | 3.45 | 71.8% |
| Platform | Mug | 1.89 | 1.16 | 3.05 | 76.6% |
| Standard | Tumbler | 2.02 | 1.18 | 3.20 | 84.6% |
| Standard | Poster | 1.42 | 1.62 | 3.04 | 87.5% |

SLA thresholds: Platform ≤ 3, Standard ≤ 4 biz days.

## Goals / Non-Goals

**Goals:**
- Contribution split: avg `processing_day` vs `first_scan_day` theo product_type — identify bottleneck type
- Pass rate breakdown: product_type × group — identify worst performers
- Pass rate breakdown: `ordx_fulfill_locate` × group — identify facility bottleneck

**Non-Goals:**
- Trend theo tháng (BOD đã có) — ops cần snapshot hiện tại, không cần historical
- Breakdown seller — quá granular cho ops prioritization
- Transit time (fulfilled → delivered) — ngoài scope TAL

## Decisions

### D1: Data source — `by_product` cho cả 2 groups (sau enrich)

> **Depends on: `enrich-fact-ofp-by-product`** — `by_product` phải có `is_platform` và `first_scan_day` đúng cho Platform trước khi viết SQL ở đây.

**Cả Platform và Standard** → `fact_order_fulfillment_performance_by_product FINAL`
- `product_type` có sẵn ở grain order × product_type — cho cả 2 groups
- `is_platform` được thêm bởi `enrich-fact-ofp-by-product`
- `first_scan_day` đúng cho Platform sau enrich
- Filter: `WHERE is_platform = 1` / `WHERE is_platform = 0`

~~Join `fact_ofp → nh_order_item → dict_product_type` cho Platform~~ — không cần sau enrich. by_product đã có product_type cho tất cả orders.

### D2: Grain = order × product_type — áp dụng cho cả 2 groups

by_product có grain order × product_type. Một order có nhiều product_types → nhiều rows, SLA metrics (processing_day, first_scan_day) lặp lại cho từng product_type của cùng order. Aggregate bằng AVG và countIf theo product_type là đúng về nghiệp vụ (weight theo item mix).

### D3: Period — 6 tháng gần nhất, không tách theo tháng

Ops cần snapshot hội tụ để identify pattern, không cần month-by-month granularity (BOD đã có trend). Filter: `paid_at_utc >= toStartOfMonth(now() - INTERVAL 6 MONTH)`.

### D4: 3 queries độc lập

1. `ops_contribution.sql` — avg processing_day + first_scan_day per product_type, cả Platform và Standard
2. `ops_product_breakdown.sql` — SLA pass rate per product_type, Platform và Standard
3. `ops_location_breakdown.sql` — SLA pass rate per `ordx_fulfill_locate`, Platform và Standard

### D5: TAL formula — kế thừa từ order-sla

`floor(processing_day + first_scan_day)` — unified cho cả 2 groups. SLA pass = `floor(TAL) <= threshold`.

## Data Sources

### Cả 2 groups — `fact_order_fulfillment_performance_by_product FINAL`

> Assumes `enrich-fact-ofp-by-product` đã hoàn tất.

```
-- Standard
SELECT product_type, ordx_fulfill_locate, processing_day, first_scan_day
FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL
WHERE is_platform = 0
  AND processing_day IS NOT NULL
  AND first_scan_day IS NOT NULL
  AND paid_at_utc >= toStartOfMonth(now() - INTERVAL 6 MONTH)

-- Platform
SELECT product_type, ordx_fulfill_locate, processing_day, first_scan_day
FROM gea__silver.fact_order_fulfillment_performance_by_product FINAL
WHERE is_platform = 1
  AND processing_day IS NOT NULL
  AND first_scan_day IS NOT NULL
  AND paid_at_utc >= toStartOfMonth(now() - INTERVAL 6 MONTH)
```

## Risks / Trade-offs

**[Dependency] `enrich-fact-ofp-by-product` phải hoàn tất trước** — SQL ở đây dùng `WHERE is_platform = 0/1` và expect `first_scan_day` đúng cho Platform. Nếu enrich chưa xong, queries sẽ sai hoặc thiếu data.

**[Risk] Multi-product orders** — một order có 2 product_types → 2 rows trong by_product. `count()` weight theo item mix — fair cho SLA rate theo product_type. Dùng `uniqExact(order_id)` chỉ khi cần "số đơn thực".

**[Risk] Platform orders thiếu tracking data** — `first_scan_day IS NOT NULL` sau enrich = USPS orders có data. Non-USPS Platform → NULL → nằm ngoài denominator. Footnote giống order-sla.

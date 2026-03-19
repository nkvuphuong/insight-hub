# Design: Order Performance — Production & Tracking SLA

## Metric Framework

```
Payment ──────────────────────────────────────► First Scan (Tracking Active)
         [  Production Time  ] [ Tracking Lag ]
         paid → fulfilled      fulfilled → first scan
         processing_day (d)    first_scan_day (d)  ← pre-calc in DB

         └──────────── Tracking Active Lead ──────────────┘
              processing_day + first_scan_day  (additive, pre-calc)
```

| Metric | Column / Formula | Unit |
|--------|-----------------|------|
| Tracking Active Lead | `processing_day + first_scan_day` | business days |
| Production Time | `processing_day` | business days |
| Tracking Lag | `first_scan_day` | business days |

## Data Source

**Primary table:** `gea__silver.fact_order_fulfillment_performance FINAL`

| Column | Meaning |
|--------|---------|
| `paid_at_utc` | Payment timestamp |
| `fulfilled_at` | Fulfilled/shipped timestamp |
| `first_scanned_at` | Carrier first scan timestamp |
| `processing_day` | Production Time, pre-calc **business days** |
| `first_scan_day` | Tracking Lag, pre-calc **business days** |
| `shipping_class` | Standard / Ground / Fastship / Other / Stamp |
| `ordx_fulfill_locate` | TX1, HB1, HB2 |
| `country_code` | US (~95%), CA, GB, AU |

## SQL Approach

**Why pre-calc columns:** `processing_day` and `first_scan_day` exclude overnight/weekend non-production time → ~0.46 days less than raw `dateDiff`. Consistent with how pipeline measures SLA.

**Key metrics:**
- Percentile: `quantile(0.5)()`, `quantile(0.9)()` — P50 = typical experience, P90 = worst-case common
- CDF: `countIf(metric <= N) / count()` — executive-friendly ("88% orders ship in 5 days")
- Segment: GROUP BY `ordx_fulfill_locate`, `shipping_class`

**Why NOT normal distribution:** Right-skewed data (Avg 4.57d >> P50 4.12d, long tail to P99 12.8d).

## Data Quality Caveats

1. **Coverage gap Aug–Oct 2025:** `processing_day` has 1–3% coverage → exclude these 3 months from time-series
2. **Coverage ~42–55% overall:** Only orders that completed full cycle. Recent 4–6 weeks naturally undercount (still in transit)
3. **Negative values:** Some `processing_day < 0` (data anomaly) → filter out

## Filters Applied

```sql
WHERE processing_day >= 0
  AND first_scan_day >= 0
  AND processing_day IS NOT NULL
  AND first_scan_day IS NOT NULL
  AND country_code = 'US'
  -- Exclude Aug–Oct 2025 in time-series
```

## Query Files

| File | Purpose | Scope |
|------|---------|-------|
| `queries/kpi.sql` | Overall KPI snapshot | Jan–Feb 2026 |
| `queries/segment.sql` | Breakdown by facility × shipping_class | Jan–Feb 2026 |
| `queries/cdf.sql` | CDF breakpoints for 3 metrics | Jan–Feb 2026 |
| `queries/main.sql` | Monthly time-series (Metabase reference) | Nov 2024–now |

## POC Charts (sql-verified)

| Chart | Query | Purpose |
|-------|-------|---------|
| KPI card | `kpi.sql` | P50/P90/Avg Active Lead + Same-day Scan Rate |
| Stacked bar | `kpi.sql` | Production vs Tracking Lag contribution |
| Production Time Distribution | `cdf.sql` | CDF curve — xưởng |
| Tracking Lag Distribution | `cdf.sql` | CDF curve — carrier |
| Tracking Active Lead Distribution | `cdf.sql` | CDF curve — total |
| Grouped bar — Production | `segment.sql` | P50 by facility × shipping class |
| Bar — Scan Rate | `segment.sql` | Same-day Scan Rate by facility × shipping class |

## Key Findings (Jan–Feb 2026)

- P50 Tracking Active Lead: ~2.38 biz days
- Tracking Lag (1.31d) > Production Time (1.16d) — carrier side dominates
- HB1/HB2 Production Time higher than TX1
- Same-day Scan Rate: HB1 Standard lowest at 27.8%

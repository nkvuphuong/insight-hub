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

| Metric | Column / Công thức | Unit |
|--------|-------------------|------|
| **Tracking Active Lead** | `processing_day + first_scan_day` | business days |
| **Production Time** | `processing_day` | business days |
| **Tracking Lag** | `first_scan_day` | business days |

> **Note về pre-calc columns (verified 2026-03-14):**
> - `processing_day` = paid → fulfilled, **business days** (loại bỏ overnight/weekend). P50 Standard US ≈ 1.1–1.4 biz days.
> - `first_scan_day` = fulfilled → first scan, **business days**. P50 Standard US ≈ 0.6–1.1 biz days.
> - `shipping_day` = fulfilled → delivered — **không dùng trong báo cáo này**.
> - `processing_day + first_scan_day` ≈ 0.46 days ít hơn `dateDiff(paid, first_scanned)/24` vì loại bỏ non-production time.

---

## Data Source

**Primary table:** `gea__silver.fact_order_fulfillment_performance FINAL`
**Data range:** Nov 2024 → nay

| Column | Ý nghĩa |
|--------|---------|
| `paid_at_utc` | Thời điểm thanh toán |
| `fulfilled_at` | Thời điểm fulfilled/shipped |
| `first_scanned_at` | Thời điểm carrier scan lần đầu |
| `processing_day` | Production Time: paid → fulfilled (pre-calc, **business days**) ⭐ |
| `first_scan_day` | Tracking Lag: fulfilled → first scan (pre-calc, **business days**) ⭐ |
| `shipping_class` | Standard / Ground / Fastship / Other / Stamp |
| `ordx_fulfill_locate` | TX1 (Texas), HB1, HB2 (Huntington Beach) |
| `country_code` | US (~95%), CA, GB, AU |

---

## Data Quality Caveats

1. **Coverage gap Aug–Oct 2025:** `processing_day` có 1–3% coverage cho tháng 8–10/2025 (pipeline issue đã xác nhận). **Loại bỏ 3 tháng này** khỏi time-series.
2. **Coverage tổng quát ~42–55%:** Chỉ tính cho đơn đã hoàn tất toàn bộ chu trình. Recent months (4–6 tuần gần nhất) tự nhiên bị undercount vì đơn còn trong transit.
3. **Giá trị âm:** Một số ít bản ghi `processing_day < 0` hoặc `first_scan_day < 0` — data anomaly, filter out.

---

## Dimensions

| Dimension | Column | Ví dụ | Ghi chú |
|-----------|--------|-------|---------|
| Tháng | `toStartOfMonth(paid_at_utc)` | 2025-01 | Granularity mặc định |
| Tuần | `toStartOfWeek(paid_at_utc)` | 2025-W01 | Drill-down |
| Shipping class | `shipping_class` | Standard, Fastship, Ground | Standard chiếm đa số |
| Facility | `ordx_fulfill_locate` | TX1, HB1, HB2 | |
| Quốc gia | `country_code` | US, CA, GB | Mặc định filter US |

---

## Metrics

### KPI Chính — Tracking Active Lead (paid → first scan)

| Metric | Công thức | Unit |
|--------|-----------|------|
| **Median Tracking Active Lead** | `quantile(0.5)(processing_day + first_scan_day)` | biz days |
| **P90 Tracking Active Lead** | `quantile(0.9)(processing_day + first_scan_day)` | biz days |
| Avg Tracking Active Lead | `avg(processing_day + first_scan_day)` | biz days |
| Order count | `count()` | orders |
| % ≤ 1 day | `countIf(processing_day + first_scan_day <= 1) / count()` | % |
| % ≤ 2 days | `countIf(processing_day + first_scan_day <= 2) / count()` | % |
| % ≤ 3 days | `countIf(processing_day + first_scan_day <= 3) / count()` | % |
| % ≤ 5 days | `countIf(processing_day + first_scan_day <= 5) / count()` | % |
| % ≤ 7 days | `countIf(processing_day + first_scan_day <= 7) / count()` | % |

### Thành phần 1 — Production Time (paid → fulfilled)

| Metric | Công thức | Unit |
|--------|-----------|------|
| **Median Production Time** | `quantile(0.5)(processing_day)` | biz days |
| **P90 Production Time** | `quantile(0.9)(processing_day)` | biz days |
| CDF — % ≤ 1 day | `countIf(processing_day <= 1) / count()` | % |
| CDF — % ≤ 2 days | `countIf(processing_day <= 2) / count()` | % |
| CDF — % ≤ 3 days | `countIf(processing_day <= 3) / count()` | % |
| CDF — % ≤ 5 days | `countIf(processing_day <= 5) / count()` | % |

### Thành phần 2 — Tracking Lag (fulfilled → first scan)

| Metric | Công thức | Unit |
|--------|-----------|------|
| **Median Tracking Lag** | `quantile(0.5)(first_scan_day)` | biz days |
| **P90 Tracking Lag** | `quantile(0.9)(first_scan_day)` | biz days |
| **Same-day Scan Rate** | `countIf(first_scan_day <= 1) / count()` | % |
| CDF — % ≤ 0.5d (12h) | `countIf(first_scan_day <= 0.5) / count()` | % |
| CDF — % ≤ 1d | `countIf(first_scan_day <= 1) / count()` | % |
| CDF — % ≤ 2d | `countIf(first_scan_day <= 2) / count()` | % |

---

## Phương Pháp Phân Tích

**Tại sao KHÔNG dùng Normal Distribution:**
Data thực tế right-skewed — Avg 4.57d >> P50 4.12d, P99 12.8d. Normal distribution cho kết quả sai lệch.

**Phương pháp:**
1. **Percentile (P50/P90)** — P50 = trải nghiệm điển hình, P90 = worst-case phổ biến (SLA-relevant)
2. **CDF** — "88% đơn ship trong 5 ngày" — trực quan cho executive, dễ compare period/facility
3. **Time-series trend** — P50 + P90 theo tháng, phát hiện deterioration sớm
4. **Segment comparison** — facility × shipping class, xác định outlier

---

## Filters

```sql
WHERE processing_day >= 0          -- loại anomaly âm
  AND first_scan_day >= 0          -- loại anomaly âm
  AND processing_day IS NOT NULL
  AND first_scan_day IS NOT NULL
  AND country_code = 'US'          -- default, ~95% volume
  -- Exclude Aug–Oct 2025 trong time-series (pipeline coverage gap)
```

Metabase filters (multi-select): shipping_class, ordx_fulfill_locate, date range

---

## Granularity

- Monthly — mặc định (executive view)
- Weekly — drill-down
- Daily — quá chi tiết cho leadership, không dùng

---

## Query Files

| File | Mục đích | Scope |
|------|---------|-------|
| `queries/kpi.sql` | Overall KPI snapshot | Jan–Feb 2026 |
| `queries/segment.sql` | Breakdown by facility × shipping_class | Jan–Feb 2026 |
| `queries/cdf.sql` | CDF breakpoints cho 3 metrics | Jan–Feb 2026 |
| `queries/main.sql` | Time-series monthly (Metabase reference) | Nov 2024–nay |

---

## Visualizations (POC — poc-done)

| Chart | Query | Mục đích |
|-------|-------|---------|
| KPI card | `kpi.sql` | P50/P90/Avg Active Lead + Same-day Scan Rate |
| Stacked bar ngang | `kpi.sql` | Production vs Tracking Lag — tỷ lệ đóng góp |
| Production Time Distribution | `cdf.sql` | CDF curve — xưởng |
| Tracking Lag Distribution | `cdf.sql` | CDF curve — carrier |
| Tracking Active Lead Distribution | `cdf.sql` | CDF curve — tổng |
| Grouped bar — Production | `segment.sql` | P50 Production Time: facility × shipping class |
| Bar — Scan Rate | `segment.sql` | Same-day Scan Rate: facility × shipping class |

---

## Key Findings (Jan–Feb 2026 snapshot)

- P50 Tracking Active Lead: ~2.38 biz days
- Tracking Lag (P50 1.31d) > Production Time (P50 1.16d) — carrier side chiếm nhiều hơn
- HB1/HB2 Production Time cao hơn TX1
- Same-day Scan Rate: HB1 Standard thấp nhất (27.8%)

---

## Open Questions

| # | Câu hỏi | Status |
|---|---------|--------|
| 1 | "Completed date" = `fulfilled_at`? | ✅ Confirmed |
| 2 | SLA target là bao nhiêu ngày? | 🔲 Backlog |
| 3 | Bỏ Aug–Oct 2025 hay investigate/fix? | ✅ Bỏ |
| 4 | Breakdown theo platform (Shopify, Etsy...)? | ✅ Chưa cần |
| 5 | Fastship có SLA/target riêng không? | ✅ Backlog |

---

## Business Questions (gate: poc-done → biz-validated)

> Cần Phuong confirm với Mr. Sang Do. Xem next steps tại `tasks.md`.

### Mục đích & audience

| # | Câu hỏi | Status |
|---|---------|--------|
| B1 | Monitor liên tục, review định kỳ, hay one-time? | 🔲 Chưa hỏi |
| B2 | Ngoài BOD, ai khác đọc? (Ops manager, warehouse lead?) | 🔲 Chưa hỏi |

### Charts & scope

| # | Câu hỏi | Status |
|---|---------|--------|
| B3 | Cần filter tự chọn trên Metabase không? | 🔲 Chưa hỏi |
| B4 | Cần so sánh 2 period trên cùng 1 chart không? | 🔲 Chưa hỏi |

### Định nghĩa "tốt/xấu" & SLA

| # | Câu hỏi | Status |
|---|---------|--------|
| B5 | P50 Active Lead = 2.38 biz days, Same-day Scan Rate 45% — ổn hay có vấn đề? | 🔲 Chưa hỏi |
| B6 | Có SLA cam kết với seller không? | 🔲 Chưa hỏi |
| B7 | Có ngưỡng escalate cụ thể không? | 🔲 Chưa hỏi |

### Impact & actionability

| # | Câu hỏi | Status |
|---|---------|--------|
| B8 | Khi Production Time tăng / Tracking Lag cao: ai chịu trách nhiệm? | 🔲 Chưa hỏi |
| B9 | Tracking Lag — GM có thể tác động được không? | 🔲 Chưa hỏi |
| B10 | Sau khi xem dashboard, workflow tiếp theo là gì? | 🔲 Chưa hỏi |

### Specific

| # | Câu hỏi | Status |
|---|---------|--------|
| B11 | POC có 7 charts — scope production: giữ/bớt/bổ sung? | 🔲 Chưa hỏi |
| B12 | Same-day Scan Rate 45% — vấn đề hay baseline? | 🔲 Chưa hỏi |
| B13 | Cần biết carrier cụ thể nào gây Tracking Lag cao không? | 🔲 Chưa hỏi |

---

## Backlog

- SLA Compliance Rate — cần confirm SLA target (đề xuất: 5 biz days = 88.5% Standard US đạt)
- Carrier dimension breakdown — thiếu dimension hiện tại
- Weekly drill-down time-series
- Period comparison (MoM overlay)

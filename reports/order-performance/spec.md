# Order Performance — Production & Tracking SLA

## Thông Tin Chung


| Field             | Value             |
| ----------------- | ----------------- |
| **Ngày tạo**      | 2026-03-13        |
| **Cập nhật**      | 2026-03-16        |
| **Người yêu cầu** | Mr. Sang Do (COO) |
| **Owner**         | Phuong            |
| **Status**        | `poc-done`        |
| **Version**       | v0.17             |
| **Metabase link** | (chưa có)         |


---

## Mục Tiêu

> Đo lường hiệu suất sản xuất và vận chuyển của GEA với khách hàng là POD sellers (Amazon, eBay, TikTok Shop, Etsy, Shopify...). Báo cáo trả lời: **Seller mất bao lâu từ lúc thanh toán đến khi hàng có tracking active?** — đây là thước đo trải nghiệm thực tế của seller. Đồng thời tách thành 2 thành phần để monitor nội bộ: hiệu suất xưởng và hiệu suất carrier.

### Metric Framework

```
Payment ──────────────────────────────────────► First Scan (Tracking Active)
         [  Production Time  ] [ Tracking Lag ]
         paid → fulfilled      fulfilled → first scan
         processing_day (d)    first_scan_day (d) ← pre-calc trong DB

         └──────────── Tracking Active Lead ──────────────┘
              processing_day + first_scan_day  (pre-calc, additive)
```


| Metric                   | Đo cái gì                | Column / Công thức                | Unit                    |
| ------------------------ | ------------------------ | --------------------------------- | ----------------------- |
| **Tracking Active Lead** | paid → first scan (tổng) | `processing_day + first_scan_day` | **business days** (pre-calc) |
| **Production Time**      | paid → fulfilled         | `processing_day` (pre-calc)       | **business days**       |
| **Tracking Lag**         | fulfilled → first scan   | `first_scan_day` (pre-calc)       | **business days**       |


> **Note về các pre-calc columns (verified 2026-03-14):**
>
> - `processing_day` = Production Time (paid → fulfilled), đơn vị **business days** (loại bỏ overnight/weekend non-production time). P50 Standard US ≈ 1.1–1.4 biz days.
> - `first_scan_day` = Tracking Lag (fulfilled → first scan), đơn vị **business days**. P50 Standard US ≈ 0.6–1.1 biz days.
> - `shipping_day` = Transit time (fulfilled → delivered) — **không dùng trong báo cáo này**.
> - `processing_day + first_scan_day` ≈ 0.46 days ít hơn `dateDiff(paid, first_scanned)/24` vì loại bỏ non-production overnight/weekend time.

### Câu hỏi cần trả lời

| # | Câu hỏi | Status POC |
|---|---|---|
| 1a | Tracking Active Lead đang ở mức nào? | ✅ Chart 01, 04b — snapshot Jan–Feb 2026 |
| 1b | Xu hướng theo tháng? | 🔲 Deferred — `main.sql` có sẵn nhưng chưa visualize |
| 2 | Phần nào chiếm nhiều thời gian hơn: xưởng hay carrier? | ✅ Chart 02 — Tracking Lag (1.31d) > Production (1.16d) |
| 3 | Facility nào / shipping class nào có Production Time cao? | ✅ Chart 05 — HB1/HB2 cao hơn TX1 |
| 4a | Location nào có Tracking Lag cao? | ✅ Chart 06 — HB1 Standard thấp nhất (27.8%) |
| 4b | Carrier nào có Tracking Lag cao? | 🔲 Không có — thiếu dimension carrier trong data/queries |

---

## Data Source

**Primary table:** `gea__silver.fact_order_fulfillment_performance FINAL`
**Data range:** Nov 2024 → nay


| Column dùng           | Ý nghĩa                                                                  |
| --------------------- | ------------------------------------------------------------------------ |
| `paid_at_utc`         | Thời điểm thanh toán (payment date)                                      |
| `fulfilled_at`        | Thời điểm fulfilled/shipped (completed date)                             |
| `first_scanned_at`    | Thời điểm carrier scan lần đầu                                           |
| `processing_day`      | Production Time: paid → fulfilled (pre-calc, **business days**) ⭐         |
| `first_scan_day`      | Tracking Lag: fulfilled → first scan (pre-calc, **business days**) ⭐     |
| `shipping_class`      | Standard / Ground / Fastship / Other / Stamp                             |
| `ordx_fulfill_locate` | TX1 (Texas), HB1, HB2 (Huntington Beach)                                 |
| `country_code`        | US (dominant ~95%), CA, GB, AU...                                        |


### Data Quality Caveats

1. **Coverage gap Aug–Oct 2025:** `processing_day` có 1–3% coverage cho tháng 8–10/2025 (pipeline issue đã xác nhận qua explore). **Loại bỏ 3 tháng này** khỏi time-series.
2. **Coverage tổng quát ~42–55%:** Chỉ tính cho đơn đã hoàn tất toàn bộ chu trình. Recent months (4–6 tuần gần nhất) tự nhiên bị undercount vì đơn còn trong transit.
3. **Giá trị âm:** Một số ít bản ghi `processing_day < 0` — data anomaly, filter out.

---

## Dimensions


| Dimension      | Column                        | Ví dụ                      | Ghi chú              |
| -------------- | ----------------------------- | -------------------------- | -------------------- |
| Tháng          | `toStartOfMonth(paid_at_utc)` | 2025-01, 2025-02           | Granularity mặc định |
| Tuần           | `toStartOfWeek(paid_at_utc)`  | 2025-W01                   | Drill-down           |
| Shipping class | `shipping_class`              | Standard, Fastship, Ground | Standard chiếm đa số |
| Facility       | `ordx_fulfill_locate`         | TX1, HB1, HB2              |                      |
| Quốc gia       | `country_code`                | US, CA, GB                 | Mặc định filter US   |


---

## Metrics

### KPI Chính — Tracking Active Lead (paid → first scan)

> Thước đo trải nghiệm thực tế của seller. Dùng pre-calculated columns (`processing_day + first_scan_day`) — consistent với cách pipeline tính Production Time và Tracking Lag.


| Metric                          | Công thức                                                              | Unit   |
| ------------------------------- | ---------------------------------------------------------------------- | ------ |
| **Median Tracking Active Lead** | `quantile(0.5)(processing_day + first_scan_day)`                       | biz days |
| **P90 Tracking Active Lead**    | `quantile(0.9)(processing_day + first_scan_day)`                       | biz days |
| Avg Tracking Active Lead        | `avg(processing_day + first_scan_day)`                                 | biz days |
| Order count                     | `count()`                                                              | orders |
| % ≤ 1 day                       | `countIf(processing_day + first_scan_day <= 1) / count()`              | %      |
| % ≤ 2 days                      | `countIf(processing_day + first_scan_day <= 2) / count()`              | %      |
| % ≤ 3 days                      | `countIf(processing_day + first_scan_day <= 3) / count()`              | %      |
| % ≤ 5 days                      | `countIf(processing_day + first_scan_day <= 5) / count()`              | %      |
| % ≤ 7 days                      | `countIf(processing_day + first_scan_day <= 7) / count()`              | %      |


---

### Thành phần 1 — Production Time (paid → fulfilled)

> Monitor hiệu suất xưởng sản xuất. Column `processing_day` pre-calculated (**business days**).


| Metric                     | Column / Công thức                       | Unit |
| -------------------------- | ---------------------------------------- | ---- |
| **Median Production Time** | `quantile(0.5)(processing_day)`          | biz days |
| **P90 Production Time**    | `quantile(0.9)(processing_day)`          | biz days |
| Avg Production Time        | `avg(processing_day)`                    | biz days |
| CDF — % ≤ 1 day            | `countIf(processing_day <= 1) / count()` | %    |
| CDF — % ≤ 2 days           | `countIf(processing_day <= 2) / count()` | %    |
| CDF — % ≤ 3 days           | `countIf(processing_day <= 3) / count()` | %    |
| CDF — % ≤ 5 days           | `countIf(processing_day <= 5) / count()` | %    |


---

### Thành phần 2 — Tracking Lag (fulfilled → first scan)

> Đánh giá hiệu suất carrier. Dùng `first_scan_day` pre-calculated (business days).


| Metric                       | Công thức                                  | Unit |
| ---------------------------- | ------------------------------------------ | ---- |
| **Median Tracking Lag**      | `quantile(0.5)(first_scan_day)`            | biz days |
| **P90 Tracking Lag**         | `quantile(0.9)(first_scan_day)`            | biz days |
| **Same-day Scan Rate**       | `countIf(first_scan_day <= 1) / count()`   | %    |
| CDF — % scanned ≤ 0.5d (12h) | `countIf(first_scan_day <= 0.5) / count()` | %    |
| CDF — % scanned ≤ 1d (24h)   | `countIf(first_scan_day <= 1) / count()`   | %    |
| CDF — % scanned ≤ 2d (48h)   | `countIf(first_scan_day <= 2) / count()`   | %    |


---

### Backlog (chưa làm phase này)

- **SLA Compliance Rate** — cần confirm SLA target với business/CS team trước
- **SLA target đề xuất:** 5 business days (dựa trên data: 88.5% Standard US đạt trong 5 ngày)

---

## Phương Pháp Phân Tích

### Tại sao KHÔNG dùng Normal Distribution

Data thực tế (Standard US, 2025):

```
Avg = 4.57 ngày  >>  P50 = 4.12 ngày  (avg >> median = right-skewed)
P90 = 6.9 ngày,  P99 = 12.8 ngày     (long tail rõ ràng)
```

→ Phân phối lệch phải. Normal distribution cho kết quả sai lệch. Không dùng.

### Phương pháp đề xuất

**1. Percentile (P50 / P90)** — thước đo chính cho leadership

- P50: không bị kéo bởi outliers → phản ánh đúng "trải nghiệm điển hình"
- P90: "worst-case phổ biến" — 90% khách hàng trải nghiệm ≤ X ngày → SLA-relevant

**2. CDF — Cumulative Share (% orders ≤ N days)** — "share pct cumulative"

- Trực quan cho executive: *"88% đơn ship trong 5 ngày"*
- Cho thấy toàn bộ distribution trong 1 chart
- Dễ so sánh tháng/facility bằng cách overlay 2 CDF curves

**3. Time-series trend** — P50 + P90 + SLA rate theo tháng

- Phát hiện deterioration sớm
- Single KPI line chart cho leadership dashboard

**4. Segment comparison** — theo facility × shipping class

- Xác định outlier: facility nào underperform?

---

## Filters

- **Date range** — mặc định 12 tháng gần nhất (bỏ Aug–Oct 2025)
- `processing_day >= 0` — loại anomaly âm
- `first_scan_day >= 0` — loại anomaly (fulfilled > first_scanned timestamps)
- `processing_day IS NOT NULL AND first_scan_day IS NOT NULL` — chỉ đơn đã hoàn tất
- Shipping class (multi-select, default: All)
- Facility (multi-select, default: All)
- Country code (default: US)

---

## Granularity

- Monthly (mặc định — executive view)
- Weekly (drill-down)
- Daily (quá chi tiết cho leadership)

---

## Visualizations (POC)

**Approach: snapshot cho 1 time range cố định** (Jan–Feb 2026) — không dùng time-series trend.


| Chart                                  | Query         | Mục đích                                              |
| -------------------------------------- | ------------- | ----------------------------------------------------- |
| KPI card                               | `kpi.sql`     | P50 / P90 / Avg Active Lead + Same-day Scan Rate      |
| Stacked bar ngang                      | `kpi.sql`     | Production vs Tracking Lag — tỷ lệ đóng góp (avg)     |
| Production Time Distribution           | `cdf.sql`     | X = days, Y = cumulative % — distribution xưởng       |
| Tracking Lag Distribution              | `cdf.sql`     | X = biz days, Y = cumulative % — distribution carrier |
| Tracking Active Lead Distribution      | `cdf.sql`     | X = days, Y = cumulative % — tổng distribution        |
| Grouped bar — Production               | `segment.sql` | P50 Production Time: facility × shipping class        |
| Bar chart — Scan Rate                  | `segment.sql` | Same-day Scan Rate: facility × shipping class         |


---

## SQL

> Source of truth: `queries/` — không lưu SQL inline trong spec để tránh drift.


| File                  | Mục đích                                 | Scope        |
| --------------------- | ---------------------------------------- | ------------ |
| `queries/kpi.sql`     | Overall KPI snapshot                     | Jan–Feb 2026 |
| `queries/segment.sql` | Breakdown by facility × shipping_class   | Jan–Feb 2026 |
| `queries/cdf.sql`     | CDF breakpoints cho 3 metrics            | Jan–Feb 2026 |
| `queries/main.sql`    | Time-series monthly (Metabase reference) | Nov 2024–nay |


---

## Open Questions (cần confirm trước khi SQL verified)


| #   | Câu hỏi                                            | Status               | Tác động                |
| --- | -------------------------------------------------- | -------------------- | ----------------------- |
| 1   | "Completed date" = `fulfilled_at`?                 | ✅ Confirmed          | Mapping đúng            |
| 2   | SLA target là bao nhiêu ngày?                      | 🔲 Backlog           | Sẽ làm phase sau        |
| 3   | Bỏ Aug–Oct 2025 hay cần investigate/fix?           | ✅ Bỏ                 | Filter ra khỏi query    |
| 4   | Có cần breakdown theo platform (Shopify, Etsy...)? | ✅ Chưa cần           | POC không làm           |
| 5   | Fastship có SLA/target riêng không?                | ✅ Có, nhưng chưa cần | POC không làm — backlog |


---

## Business Questions (gate: poc-done → biz-validated)

> Cần Phuong confirm với Mr. Sang Do trước khi move sang `biz-validated` và build Metabase.

### Mục đích & audience  *(từ template)*

| # | Câu hỏi | Status |
|---|---|---|
| B1 | Report dùng để làm gì: monitor liên tục, review định kỳ (weekly/monthly meeting), hay one-time? | 🔲 Chưa hỏi |
| B2 | Ngoài BOD, ai khác đọc report này? (Ops manager, warehouse lead?) | 🔲 Chưa hỏi |

### Charts & scope  *(từ template)*

| # | Câu hỏi | Status |
|---|---|---|
| B3 | Cần filter tự chọn trên Metabase không (date range, facility, shipping class)? Hay cố định scope? | 🔲 Chưa hỏi |
| B4 | Cần so sánh 2 period trên cùng 1 chart không (ví dụ: Jan vs Feb)? | 🔲 Chưa hỏi |

### Định nghĩa "tốt/xấu" & SLA  *(từ template)*

| # | Câu hỏi | Status |
|---|---|---|
| B5 | P50 Active Lead = 2.38 biz days, Same-day Scan Rate 45% — anh thấy đây là ổn hay đang có vấn đề? | 🔲 Chưa hỏi |
| B6 | Có SLA cam kết với seller không (ví dụ: "tracking active trong X ngày")? Nếu có: bao nhiêu ngày? | 🔲 Chưa hỏi |
| B7 | Có ngưỡng cụ thể nào mà khi vượt qua cần escalate không? (Ví dụ: P90 > 5 ngày → họp ops) | 🔲 Chưa hỏi |

### Impact & actionability  *(từ template)*

| # | Câu hỏi | Status |
|---|---|---|
| B8 | Khi Production Time tăng / Tracking Lag cao: ai chịu trách nhiệm xử lý, bằng cách nào? | 🔲 Chưa hỏi |
| B9 | Tracking Lag — GM có thể tác động được không, hay phụ thuộc hoàn toàn vào carrier? | 🔲 Chưa hỏi |
| B10 | Sau khi xem dashboard, workflow tiếp theo là gì? Ai làm gì, trong bao lâu? | 🔲 Chưa hỏi |

### Specific cho report này

| # | Câu hỏi | Status |
|---|---|---|
| B11 | Yêu cầu ban đầu là "CDF của Production Time và Tracking Active Lead" — POC đã build thêm 5 charts. Confirm scope production: giữ nguyên, bớt, hay bổ sung? Nếu chỉ giữ 1 chart, anh chọn chart nào? | 🔲 Chưa hỏi |
| B12 | Same-day Scan Rate 45% — đây là vấn đề hay baseline bình thường? Có benchmark ngành không? | 🔲 Chưa hỏi |
| B13 | Cần biết carrier cụ thể (USPS, FedEx...) nào gây Tracking Lag cao không? | 🔲 Chưa hỏi |

---

> **Changelog:** xem `changelog.md`


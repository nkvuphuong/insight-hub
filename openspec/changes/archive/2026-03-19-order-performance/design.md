# Design: Order Performance — Production & Tracking SLA

## Metric Framework

```
Payment ──────────────────────────────────────────────► First Scan
         [     Production Time      ] [ Tracking Lag ]
         paid → fulfilled              fulfilled → first scan
         sản xuất + đóng gói           carrier pickup
         = sẵn sàng bàn giao           (chưa phải đã bàn giao)
         processing_day (biz days)     first_scan_day (biz days)

         └──────────── Tracking Active Lead ─────────────┘
                  processing_day + first_scan_day
                  KPI chính — trải nghiệm của seller
```

**Underlying measures:**

| Metric                   | Đo cái gì                           | Vai trò                                                      |
| ------------------------ | ----------------------------------- | ------------------------------------------------------------ |
| **Tracking Active Lead** | paid → first scan                   | KPI chính — customer perspective                             |
| **Production Time**      | paid → fulfilled (ready)            | Component — GEA internal, quan trọng ngang Tracking Lag      |
| **Tracking Lag**         | fulfilled → first scan              | Component — carrier pickup, quan trọng ngang Production Time |

**Output — 2 metrics được báo cáo (≤30s decision):**

| # | Metric | Câu hỏi trả lời | Chart |
|---|--------|----------------|-------|
| 1 | **SLA Compliance Rate** — % đơn ≤ 2 BD | Đang đạt TikTok Shop SLA không? | `07_tiktok_sla_compliance.png` |
| 2 | **Component vs SLA Budget** — P50 Production + Tracking Lag stacked vs SLA line | Bottleneck ở component nào? | `08_stacked_vs_sla.png` |

> Metric 3 (facility comparison) bị loại bỏ — không trả lời trực tiếp câu hỏi "cải thiện thế nào". HOW to improve là phân tích của action owner sau khi đọc 2 số trên.


> **Production Time — định nghĩa chính xác:** `fulfilled` = đơn đã sản xuất xong + đóng gói + sẵn sàng để bàn giao. Chưa phải lúc carrier thực sự đến lấy. Không dùng "bàn giao cho carrier" để tránh nhầm với first scan.

> **SLA Target (confirmed 2026-03-19):** TikTok Shop = 2 BD (paid → first carrier scan). GEA compliance: 37.1% — CRITICAL.

> **Note về pre-calc columns (verified 2026-03-14):**
>
> - `processing_day` = paid → fulfilled, **business days** (loại bỏ overnight/weekend). P50 Standard US ≈ 1.1–1.4 biz days.
> - `first_scan_day` = fulfilled → first scan, **business days**. P50 Standard US ≈ 0.6–1.1 biz days.
> - `shipping_day` = fulfilled → delivered — **không dùng trong báo cáo này**.
> - `processing_day + first_scan_day` ≈ 0.46 days ít hơn `dateDiff(paid, first_scanned)/24` vì loại bỏ non-production time.

---

## Data Source

**Primary table:** `gea__silver.fact_order_fulfillment_performance FINAL`
**Data range:** Nov 2024 → nay


| Column                | Ý nghĩa                                                              |
| --------------------- | -------------------------------------------------------------------- |
| `paid_at_utc`         | Thời điểm thanh toán                                                 |
| `fulfilled_at`        | Thời điểm fulfilled/shipped                                          |
| `first_scanned_at`    | Thời điểm carrier scan lần đầu                                       |
| `processing_day`      | Production Time: paid → fulfilled (pre-calc, **business days**) ⭐    |
| `first_scan_day`      | Tracking Lag: fulfilled → first scan (pre-calc, **business days**) ⭐ |
| `shipping_class`      | Standard / Ground / Fastship / Other / Stamp                         |
| `ordx_fulfill_locate` | TX1 (Texas), HB1, HB2 (Huntington Beach)                             |
| `country_code`        | US (~95%), CA, GB, AU                                                |


---

## Data Quality Caveats

1. **Coverage gap Aug–Oct 2025:** `processing_day` có 1–3% coverage cho tháng 8–10/2025 (pipeline issue đã xác nhận). **Loại bỏ 3 tháng này** khỏi time-series.
2. **Coverage tổng quát ~42–55%:** Chỉ tính cho đơn đã hoàn tất toàn bộ chu trình. Recent months (4–6 tuần gần nhất) tự nhiên bị undercount vì đơn còn trong transit.
3. **Giá trị âm:** Một số ít bản ghi `processing_day < 0` hoặc `first_scan_day < 0` — data anomaly, filter out.

---

## Dimensions


| Dimension      | Column                        | Ví dụ                      | Ghi chú              |
| -------------- | ----------------------------- | -------------------------- | -------------------- |
| Tháng          | `toStartOfMonth(paid_at_utc)` | 2025-01                    | Granularity mặc định |
| Tuần           | `toStartOfWeek(paid_at_utc)`  | 2025-W01                   | Drill-down           |
| Shipping class | `shipping_class`              | Standard, Fastship, Ground | Standard chiếm đa số |
| Facility       | `ordx_fulfill_locate`         | TX1, HB1, HB2              |                      |
| Quốc gia       | `country_code`                | US, CA, GB                 | Mặc định filter US   |


---

## Metrics

### KPI Chính — Tracking Active Lead (paid → first scan)


| Metric                          | Công thức                                                 | Unit     |
| ------------------------------- | --------------------------------------------------------- | -------- |
| **Median Tracking Active Lead** | `quantile(0.5)(processing_day + first_scan_day)`          | biz days |
| **P90 Tracking Active Lead**    | `quantile(0.9)(processing_day + first_scan_day)`          | biz days |
| Avg Tracking Active Lead        | `avg(processing_day + first_scan_day)`                    | biz days |
| Order count                     | `count()`                                                 | orders   |
| % ≤ 1 day                       | `countIf(processing_day + first_scan_day <= 1) / count()` | %        |
| % ≤ 2 days                      | `countIf(processing_day + first_scan_day <= 2) / count()` | %        |
| % ≤ 3 days                      | `countIf(processing_day + first_scan_day <= 3) / count()` | %        |
| % ≤ 5 days                      | `countIf(processing_day + first_scan_day <= 5) / count()` | %        |
| % ≤ 7 days                      | `countIf(processing_day + first_scan_day <= 7) / count()` | %        |


### Thành phần 1 — Production Time (paid → fulfilled)


| Metric                     | Công thức                                | Unit     |
| -------------------------- | ---------------------------------------- | -------- |
| **Median Production Time** | `quantile(0.5)(processing_day)`          | biz days |
| **P90 Production Time**    | `quantile(0.9)(processing_day)`          | biz days |
| CDF — % ≤ 1 day            | `countIf(processing_day <= 1) / count()` | %        |
| CDF — % ≤ 2 days           | `countIf(processing_day <= 2) / count()` | %        |
| CDF — % ≤ 3 days           | `countIf(processing_day <= 3) / count()` | %        |
| CDF — % ≤ 5 days           | `countIf(processing_day <= 5) / count()` | %        |


### Thành phần 2 — Tracking Lag (fulfilled → first scan)


| Metric                  | Công thức                                  | Unit     |
| ----------------------- | ------------------------------------------ | -------- |
| **Median Tracking Lag** | `quantile(0.5)(first_scan_day)`            | biz days |
| **P90 Tracking Lag**    | `quantile(0.9)(first_scan_day)`            | biz days |
| **Same-day Scan Rate**  | `countIf(first_scan_day <= 1) / count()`   | %        |
| CDF — % ≤ 0.5d (12h)    | `countIf(first_scan_day <= 0.5) / count()` | %        |
| CDF — % ≤ 1d            | `countIf(first_scan_day <= 1) / count()`   | %        |
| CDF — % ≤ 2d            | `countIf(first_scan_day <= 2) / count()`   | %        |


---

## Phương Pháp Phân Tích

**Tại sao KHÔNG dùng Normal Distribution:**
Data thực tế right-skewed — Avg 4.57d >> P50 4.12d, P99 12.8d. Normal distribution cho kết quả sai lệch.

**Phương pháp:**

1. **SLA Compliance Rate** — % đơn ≤ SLA target, metric chính cho executive decision
2. **Percentile (P50)** — median component breakdown per segment (stacked vs SLA budget)
3. **Segment breakdown** — facility × shipping class để xác định bottleneck
4. *Supplementary:* CDF distribution curves cho các component (production, tracking lag, active lead)

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


| File                  | Mục đích                                 | Scope        |
| --------------------- | ---------------------------------------- | ------------ |
| `queries/kpi.sql`     | Overall KPI snapshot                              | Jan–Feb 2026 |
| `queries/segment.sql` | Breakdown by facility × shipping_class            | Jan–Feb 2026 |
| `queries/cdf.sql`     | CDF breakpoints cho 3 metrics                     | Jan–Feb 2026 |
| `queries/sla.sql`     | SLA Compliance Rate by facility × shipping_class  | Jan–Feb 2026 |
| `queries/main.sql`    | Time-series monthly (Metabase reference)          | Nov 2024–nay |


---

## Visualizations (v1.1)


**Primary (dashboard `00_dashboard.png`):**

| Chart | Query | Mục đích |
|-------|-------|---------|
| `07_tiktok_sla_compliance.png` | `sla.sql` | **Metric 1** — SLA Compliance Rate by facility × class |
| `08_stacked_vs_sla.png`        | `sla.sql` | **Metric 2** — Stacked Production + Tracking Lag vs SLA line |

**Supplementary (detail charts):**

| Chart | Query | Mục đích |
|-------|-------|---------|
| `01_kpi_summary.png`        | `kpi.sql`     | P50/P90/Avg Active Lead snapshot |
| `02_lead_breakdown.png`     | `kpi.sql`     | Production vs Tracking Lag breakdown |
| `03_production_cdf.png`     | `cdf.sql`     | Production Time distribution |
| `04_tracking_lag_cdf.png`   | `cdf.sql`     | Tracking Lag distribution |
| `04b_active_lead_cdf.png`   | `cdf.sql`     | Tracking Active Lead distribution |
| `05_production_by_segment.png` | `segment.sql` | P50 Production by facility × class |
| `06_scan_rate_by_segment.png`  | `segment.sql` | Same-day Scan Rate by segment |


---

## Key Findings (Jan–Feb 2026 snapshot)

**Overall (Standard US):**
- P50 Tracking Active Lead: 2.42 BD, P90: 4.37 BD
- TikTok Shop SLA compliance (≤2 BD): **37.1%** — CRITICAL
- eBay/Etsy SLA compliance (≤5 BD): 95.6% — an toàn

**Breakdown by facility (sla.sql — sorted by TikTok SLA compliance):**

| Facility | Shipping | Orders | TikTok SLA% | P50 Production | P50 Tracking Lag |
|---|---|---|---|---|---|
| HB2 | Standard | 113 | **9.7%** | 1.46d | 1.88d |
| HB1 | Standard | 5,049 | **19.4%** | 1.33d | 1.88d |
| TX1 | Standard | 4,797 | **56.4%** | 1.17d | 0.96d |
| TX1 | Ground | 1,026 | 60.6% | 0.54d | 1.00d |
| TX1 | Fastship | 291 | 60.5% | 0.50d | 1.00d |

**Root cause:** Tracking Lag tại HB1/HB2 = 1.88d — **gấp đôi TX1 (0.96d)**. Carrier pickup tại HB facilities là bottleneck chính. Production Time giữa các facility tương đối đồng đều (1.17–1.46d).

---

## Open Questions


| #   | Câu hỏi                                     | Status      |
| --- | ------------------------------------------- | ----------- |
| 1   | "Completed date" = `fulfilled_at`?          | ✅ Confirmed |
| 2   | SLA target là bao nhiêu ngày?               | ✅ TikTok Shop = 2 BD (confirmed 2026-03-19) |
| 3   | Bỏ Aug–Oct 2025 hay investigate/fix?        | ✅ Bỏ        |
| 4   | Breakdown theo platform (Shopify, Etsy...)? | ✅ Chưa cần  |
| 5   | Fastship có SLA/target riêng không?         | ✅ Backlog   |


---

## Biz-Validated Gate (confirmed 2026-03-19)

Gate đã passed. Kết quả confirm:

| Câu hỏi | Kết quả |
|---------|---------|
| Performance hiện tại? | TikTok SLA compliance 37.1% — CRITICAL |
| Cải thiện thế nào? | Giảm Tracking Lag tại HB1/HB2 (carrier pickup ×2 chậm hơn TX1) |
| Format output? | Analysis report (PNG/CSV) giao các team + Metabase monitoring |
| Action owners? | 4 teams — xem Action Owner Matrix |

---

## Action Owner Matrix


| Metric xấu                      | Team                  | Lever                                                           |
| ------------------------------- | --------------------- | --------------------------------------------------------------- |
| Production Time ↑               | Xưởng sản xuất        | Tối ưu quy trình sản xuất, đóng gói, bàn giao cho carrier       |
| Tracking Lag ↑ (systemic)       | Vận hành & Phát triển | Cải thiện background ops, handover process                      |
| Tracking Lag ↑ (carrier/vendor) | Leadership cấp cao    | Làm việc với carrier partners, giải quyết bottleneck khách quan |
| Customer impact                 | CS & MKT              | Hỗ trợ khách hàng xử lý khiếu nại sản xuất/vận chuyển           |


---

## SLA Benchmark (verified 2026-03-19)


| Platform           | SLA (paid → first scan)            | "Shipped" =                         | Penalty threshold                             | Risk GEA   |
| ------------------ | ---------------------------------- | ----------------------------------- | --------------------------------------------- | ---------- |
| **TikTok Shop US** | **2 BD**                           | First carrier scan                  | LDR >4% phạt, >10% suspend; auto-cancel >5 BD | **HIGH**   |
| **Amazon FBM**     | **1–2 BD** (default, configurable) | Seller Central confirm + first scan | LSR >4% deactivation risk                     | **MEDIUM** |
| **eBay US**        | Seller-set (recommend ≤2 BD)       | First carrier scan                  | LSR >3% mất Top Rated                         | **LOW**    |
| **Etsy US**        | Seller-set processing time         | Marked shipped in dashboard         | On-time <80% account risk                     | **LOW**    |


**GEA thực tế (Standard US, Jan–Feb 2026, n=9,965):**


| Threshold                            | % đạt     | Đánh giá             |
| ------------------------------------ | --------- | -------------------- |
| ≤2 BD (TikTok Shop / Amazon default) | **37.1%** | ⚠️ 62.9% vi phạm SLA |
| ≤3 BD                                | 66.3%     | —                    |
| ≤5 BD (eBay/Etsy safe zone)          | **95.6%** | ✓ An toàn            |


P50 = **2.42 BD**, P90 = **4.37 BD**

- **TikTok Shop: CRITICAL** — chỉ 37.1% đơn đạt SLA 2 BD. Auto-cancel risk với ~4.4% orders (>5 BD)
- **Amazon FBM:** Nếu set handling time ≥3 BD trong listing → trong SLA
- **eBay/Etsy:** 95.6% within 5 BD → an toàn với cả hai sàn

**SLA Compliance Rate formulas:**

```sql
-- TikTok Shop / Amazon default (2 BD)
countIf(processing_day + first_scan_day <= 2) / count()

-- eBay / Etsy safe zone (5 BD)
countIf(processing_day + first_scan_day <= 5) / count()
```

---

## Backlog

- Carrier dimension breakdown — thiếu dimension hiện tại
- Weekly drill-down time-series
- Period comparison (MoM overlay)


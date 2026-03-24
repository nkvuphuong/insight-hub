## Context

Gearment cam kết SLA với khách hàng theo Tracking Active Lead (TAL = paid → first scan). Hiện tại chưa có báo cáo đo **tỷ lệ đơn đạt SLA** — team chỉ biết thời gian trung bình, không biết % đơn thực sự đạt chuẩn cam kết.

Có 3 nhóm SLA (2 active, 1 pending data):

| Nhóm | Identifier | SLA (TAL) | Status |
|---|---|---|---|
| Rush | (chưa có field phân biệt) | ≤ 2 biz days | Future — data bổ sung sau |
| Platform | `is_platform = 1` trong `fact_order_fulfillment_performance` | ≤ 3 biz days | ✓ Active |
| Standard | `is_platform = 0` trong `fact_order_fulfillment_performance` | ≤ 4 biz days | ✓ Active |

## Goals / Non-Goals

**Goals:**
- Tính **SLA pass rate** (% đơn đạt TAL ≤ threshold) cho từng nhóm Platform và Standard
- Scorecard: pass rate hiện tại + MoM delta (↑/↓) — đọc ngay tình hình tháng này
- Trend 12 tháng — phát hiện degradation sớm
- Footnote: tỷ lệ đơn thiếu tracking data (Standard ~36%) — context cho người đọc, không phải metric chính

**Non-Goals (BOD view):**
- Breakdown theo segment (location × country) — ops-level, BOD escalate xuống ops để investigate
- Chart production time vs tracking lag contribution — ops-level, không cần ở BOD view
- Rush orders — chưa có data field phân biệt, bổ sung sau
- Transit time (fulfilled → delivered) — không trong scope hiện tại
- Non-USPS order labels — chưa có data, bổ sung sau
- Internal benchmark / color threshold — chưa có target, dùng trend thay thế; propose target sau khi có data thực

## Decisions

### D1: Metric chính là Tracking Active Lead (TAL), không phải end-to-end

TAL = paid → first scan = production time + tracking lag. Đây là metric Gearment kiểm soát được và là basis của SLA commitment. Transit time (fulfilled → delivered) nằm ngoài scope hiện tại.

### D2: Tách 2 nhóm Platform vs Standard — không gộp chung

**Định nghĩa dựa trên nguồn gốc label, không phải `shipping_class`:**
- **Platform (Ship by Seller)** = đơn khách hàng cung cấp label (own USPS label hoặc Ship by GM) → `is_platform = 1` trong `fact_order_fulfillment_performance`
- **Standard (Ship by Gearment)** = đơn GM mua label qua hệ thống riêng → `is_platform = 0`

Source of truth: `nh_order_source.is_label` (populated vào `fact_ofp.is_platform` qua `enrich-fact-ofp-platform`). `shipping_class` không đủ tin cậy để phân biệt.

### D3: Data sources per group

> **[Updated — sql-refactored 2026-03-23]** Cả 2 groups đều lấy từ `fact_order_fulfillment_performance FINAL` sau khi `enrich-fact-ofp-platform` đã thêm `is_platform` và fix `first_scan_day` cho Platform.

**Standard (Ship by Gearment)** — `fact_order_fulfillment_performance FINAL`:

| Metric | Column | Đơn vị |
|---|---|---|
| Production time | `processing_day` | Float32, fractional biz days |
| Tracking lag | `first_scan_day` | Float32, fractional biz days |
| TAL | `floor(processing_day + first_scan_day)` | integer biz days elapsed (payment → first scan) |
| SLA pass | TAL ≤ 4 | biz days |

Filter: `is_platform = 0 AND first_scan_day IS NOT NULL AND processing_day IS NOT NULL`

**Platform (Ship by Seller / Order Label)** — `fact_order_fulfillment_performance FINAL`:

| Metric | Column | Đơn vị |
|---|---|---|
| Production time | `processing_day` | Float32, fractional biz days |
| Tracking lag | `first_scan_day` | Float32, fractional biz days (từ USPS tracking via enrich step) |
| TAL | `floor(processing_day + first_scan_day)` | integer biz days elapsed |
| SLA pass | TAL ≤ 3 | biz days |

Filter: `is_platform = 1 AND first_scan_day IS NOT NULL AND processing_day IS NOT NULL`
— `first_scan_day IS NOT NULL` = Platform orders có USPS tracking (own label); non-USPS label → NULL, nằm ngoài denominator

~~Join pattern cũ: `v__usps_paided` driving → INNER JOIN `fact_ofp FINAL`~~ — Replaced by `is_platform` flag

### D4: TAL dùng `floor(processing_day + first_scan_day)` cho cả 2 nhóm

Cả `processing_day` và `first_scan_day` là fractional biz days. Cộng tổng rồi `floor()` để ra integer biz days elapsed. Same-day fulfillment = 0, qua 1 ngày = 1, đúng với e-commerce SLA standard (payment day = Day 0, không tính). Unified formula cho cả Standard và Platform.

### D7: Dashboard structure — BOD view

Audience là BOD (≤30s scan), escalation-only workflow → chart structure đơn giản:

```
View 1 — Scorecard (tháng hiện tại):
  Platform: XX%  ↑/↓ +X% vs tháng trước
  Standard:  XX%  ↑/↓ +X% vs tháng trước
             (*) Chỉ tính đơn có tracking data

View 2 — Trend (12 tháng):
  Line chart: Platform vs Standard, TAL pass rate theo tháng
```

Production time vs tracking lag contribution và breakdown theo segment (location × country) **không hiển thị** ở BOD view — ops team dùng query trực tiếp để drill down khi được escalate.

Benchmark/color threshold (xanh/vàng/đỏ) sẽ bổ sung sau khi BOD xem data thực và team propose target.

### D5: Tách thành 3 queries độc lập

1. `sla_standard.sql` — Standard group: TAL pass rate theo tháng
2. `sla_platform.sql` — Platform group: TAL pass rate theo tháng
3. (Future) `sla_rush.sql` — khi có field phân biệt Rush orders

Mỗi query độc lập, dễ debug và reuse trên Metabase.

### D6: Period — 12 tháng gần nhất, grain tháng

Filter: `paid_at_utc >= toStartOfMonth(now() - INTERVAL 12 MONTH)`

## Risks / Trade-offs

**[Note] `processing_day` và `first_scan_day` là fractional biz days** → Cả 2 = `*_hour / 24`, trong đó `*_hour` đã loại trừ weekend và federal holiday. Không áp dụng working hours trong ngày vì không khả thi về nghiệp vụ. Kết quả là Float32 fractional — `floor()` để ra integer days elapsed.

**[Risk] Standard: ~36% đơn không có `first_scan_day`** → không tính vào SLA pass rate. Denominator = chỉ đơn có `first_scan_day IS NOT NULL`. Xử lý: thêm footnote "(*) Chỉ tính đơn có tracking data" trên chart.

**[Risk] Platform chỉ cover USPS order labels** → `is_platform = 1` nhưng non-USPS label → `first_scan_day = NULL` → nằm ngoài denominator. Mitigation: filter `first_scan_day IS NOT NULL` là đủ — acceptable caveat, documented.

**[Risk] Rush orders chưa có identifier** → thiếu 1/3 SLA framework. Mitigation: bổ sung sau khi có data field — không đưa vào dashboard hiện tại.

## Open Questions

~~SLA thresholds~~ → Confirmed: Standard ≤ 4 biz days, Platform ≤ 3 biz days, Rush ≤ 2 biz days

~~Order label in scope?~~ → Confirmed: Option A, 2 sections trong cùng 1 báo cáo

~~Đơn vị calendar vs business days?~~ → Confirmed: business days, dùng day columns, ceil() để đồng bộ

~~`business_days_exclude_payment` vs `business_days_inclusive`~~ → Confirmed: dùng `business_days_exclude_payment` (SLA tính sau ngày thanh toán)

~~Rush orders field~~ → Confirmed: field sẽ bổ sung sau, query design extensible là đủ

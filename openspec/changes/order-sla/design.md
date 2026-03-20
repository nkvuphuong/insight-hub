## Context

Gearment cam kết SLA với khách hàng theo Tracking Active Lead (TAL = paid → first scan). Hiện tại chưa có báo cáo đo **tỷ lệ đơn đạt SLA** — team chỉ biết thời gian trung bình, không biết % đơn thực sự đạt chuẩn cam kết.

Có 3 nhóm SLA (2 active, 1 pending data):

| Nhóm | Identifier | SLA (TAL) | Status |
|---|---|---|---|
| Rush | (chưa có field phân biệt) | ≤ 2 biz days | Future — data bổ sung sau |
| Platform | có trong `v__usps_paided_to_first_scan_days` | ≤ 3 biz days | ✓ Active |
| Standard | KHÔNG có trong `v__usps_paided_to_first_scan_days` | ≤ 4 biz days | ✓ Active |

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
- **Platform (Ship by Seller)** = đơn khách hàng cung cấp USPS label → có trong `v__usps_paided_to_first_scan_days`
- **Standard (Ship by Gearment)** = đơn GM mua label → KHÔNG có trong `v__usps_paided_to_first_scan_days`

`shipping_class` không đủ tin cậy để phân biệt — `v__usps_paided` chứa cả Standard và Other shipping class. Source of truth là sự có mặt trong `v__usps_paided`.

### D3: Data sources per group

**Standard (Ship by Gearment)** — từ `fact_order_fulfillment_performance FINAL`:

| Metric | Column | Đơn vị |
|---|---|---|
| Production time | `processing_day` | Float32, fractional biz days (= processing_hour / 24, hour đã loại weekend + federal holiday) |
| Tracking lag | `first_scan_day` | Float32, fractional biz days (= first_scan_hour / 24, hour đã loại weekend + federal holiday) |
| TAL | `floor(processing_day + first_scan_day)` | integer biz days elapsed (payment → first scan) |
| SLA pass | TAL ≤ 4 | biz days |

Join pattern: `fact_ofp FINAL` (subquery) `LEFT ANTI JOIN v__usps_paided` ON `toInt64(order_id) = toInt64(ord_id)`
Filter thêm: `first_scan_day IS NOT NULL`, `processing_day IS NOT NULL`

**Platform (Ship by Seller / Order Label)** — JOIN 2 tables qua `ord_id`:

| Metric | Table | Column | Đơn vị |
|---|---|---|---|
| Production time | `fact_ofp` | `processing_day` | Float32, days |
| TAL | `v__usps_paided_to_first_scan_days` | `business_days_exclude_payment` | Int64, biz days |
| SLA pass | TAL ≤ 3 | biz days |

Filter: tất cả orders có trong `v__usps_paided_to_first_scan_days` — không filter theo `shipping_class`

Join: `v__usps_paided` driving → INNER JOIN `fact_ofp FINAL` (subquery)
— FINAL trực tiếp + JOIN gây timeout trên bảng lớn; tách FINAL vào subquery để tránh.
— Cast: `toInt64()` cả 2 phía (UInt64 vs Int32)

### D4: TAL Standard dùng `floor(processing_day + first_scan_day)`

Cả `processing_day` và `first_scan_day` là fractional biz days. Cộng tổng rồi `floor()` để ra integer biz days elapsed — đồng bộ với convention của Platform (`business_days_exclude_payment`, floor-rounded). Same-day fulfillment = 0, qua 1 ngày = 1, đúng với e-commerce SLA standard (payment day = Day 0, không tính).

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

**[Note] `processing_day` và `first_scan_day` là fractional biz days** → Cả 2 = `*_hour / 24`, trong đó `*_hour` đã loại trừ weekend và federal holiday (trừ đi số ngày × 24h). Không áp dụng working hours trong ngày vì không khả thi về nghiệp vụ. Kết quả là Float32 fractional — ví dụ 1.5305 ngày. `ceil()` trên `processing_day` round lên ngày nguyên trước khi cộng với `first_scan_day`, consistent với cách `business_days_exclude_payment` tính integer days cho Platform.

**[Risk] Standard: ~36% đơn không có `first_scan_day`** → không tính vào SLA pass rate. Denominator = chỉ đơn có `first_scan_day IS NOT NULL`. Xử lý: thêm footnote "(*) Chỉ tính đơn có tracking data" trên chart — không tách thành metric riêng để tránh phức tạp hóa BOD view.

**[Risk] Platform chỉ cover USPS order labels** → non-USPS order labels không có data trong `v__usps_paided`. Mitigation: Platform = tất cả orders có trong `v__usps_paided` (source of truth), các order label khác nằm ngoài scope hiện tại.

**[Caveat] `v__usps_paided_to_first_scan_days` count() có thể trả partial result** → `SELECT count()` trên view này đã từng trả 16,025 (sai) thay vì 143,562 (đúng) do MCP chỉ scan partial shards. Khi cần row count chính xác, dùng `uniqExact(ord_id)` hoặc aggregate query thay vì `count()` đơn thuần.

**[Risk] Rush orders chưa có identifier** → thiếu 1/3 SLA framework. Mitigation: bổ sung sau khi có data field — không đưa vào dashboard hiện tại.

## Open Questions

~~SLA thresholds~~ → Confirmed: Standard ≤ 4 biz days, Platform ≤ 3 biz days, Rush ≤ 2 biz days

~~Order label in scope?~~ → Confirmed: Option A, 2 sections trong cùng 1 báo cáo

~~Đơn vị calendar vs business days?~~ → Confirmed: business days, dùng day columns, ceil() để đồng bộ

~~`business_days_exclude_payment` vs `business_days_inclusive`~~ → Confirmed: dùng `business_days_exclude_payment` (SLA tính sau ngày thanh toán)

~~Rush orders field~~ → Confirmed: field sẽ bổ sung sau, query design extensible là đủ

# Logic Reference — enrich-fact-ofp-platform

> Tài liệu này capture logic hiện tại của 3 objects liên quan. Mục đích: review + tái sử dụng khi viết MV mới. Không cần re-explore MCP.

---

## 1. `mv__fact_order_fulfillment_performance` — MV chính (Standard orders)

**Type:** Materialized View `REFRESH EVERY 4 HOUR` → full refresh (không incremental)
**Target:** `gea__silver.fact_order_fulfillment_performance` (ReplacingMergeTree)

### Sources

| Table | Join type | Điều kiện |
|---|---|---|
| `geadb__bronze.nh_transaction` | base | — |
| `geadb__bronze.nh_order` | INNER JOIN | `transaction_id`, `ord_id >= 13500000` |
| `geadb__bronze.nh_order_extra` | INNER JOIN | `ord_id` |
| `geadb__bronze.nh_country` | INNER JOIN | `ord_cus_country = country_id` |
| `geadb__bronze.nh_order_activities` | ANY LEFT JOIN | `ord_id`, filter: `IN ('pickup', 'fulfilled', 'delivered')` |
| `gea__silver.dim_time_bd` | ANY LEFT JOIN × 4 | join theo date: production, fulfilled, first_scanned, delivered |

### CTE Chain

```
nh_transaction + nh_order + nh_order_extra + nh_country + nh_order_activities
        │
        ▼ [base_order_data]
order_id, ordx_fulfill_locate, shipping_scope, shipping_class,
country_code, country_name, fulfill_timezone,
paid_at_utc, paid_at_local,
fulfilled_at_utc, first_scanned_at_utc, delivered_at_utc
        │
        ▼ [production_schedule]
cutoff_hour = if month IN (5,6,12) → 6, else → 12
production_at = if paid_hour <= cutoff → paid_at_local, else → next_day 08:00
is_shifted_production = 0 / 1
        │
        ▼ [lifecycle_timestamps]
Convert tất cả timestamps sang local timezone (HB1/HB2 → LA, TX1 → Chicago)
Lấy Date32 cho: production_date, fulfilled_date, first_scanned_date, delivered_date
        │
        ▼ [business_day_indices]
JOIN dim_time_bd 4 lần để lấy business_day_seq:
  production_idx, fulfilled_idx, first_scanned_idx, delivered_idx
        │
        ▼ [raw_time_differences]
pf_hour = dateDiff('hour', production_at, fulfilled_at)
pf_day  = dateDiff('day', production_at, fulfilled_at)
ff_hour = dateDiff('hour', fulfilled_at, first_scanned_at)
ff_day  = dateDiff('day', fulfilled_at, first_scanned_at)
fd_hour = dateDiff('hour', fulfilled_at, delivered_at)
fd_day  = dateDiff('day', fulfilled_at, delivered_at)
        │
        ▼ [business_hour_metrics]
processing_hour = pf_hour - (pf_day - (fulfilled_idx - production_idx)) * 24
first_scan_hour = ff_hour - (ff_day - (first_scanned_idx - fulfilled_idx)) * 24
shipping_hour   = fd_hour - (fd_day - (delivered_idx - fulfilled_idx)) * 24
        │
        ▼ [SELECT final]
processing_day = processing_hour / 24
first_scan_day = first_scan_hour / 24
shipping_day   = shipping_hour / 24
```

### Business Day Formula (pattern dùng lại)

```sql
-- Biz hours giữa 2 timestamps A → B:
diff_hour - (dateDiff('day', A, B) - (B_idx - A_idx)) * 24

-- Ý nghĩa: tổng hours thực, trừ đi hours của các ngày non-business
-- dim_time_bd.business_day_seq = sequence number chỉ đếm business days
```

### Output columns

| Column | Type | Ý nghĩa |
|---|---|---|
| `order_id` | UInt64 | — |
| `ordx_fulfill_locate` | String | Kho: HB1, HB2, TX1 |
| `shipping_scope` | String | Domestic / International |
| `shipping_class` | String | Standard / Fastship / Ground / Stamp / Other |
| `country_code` | FixedString(2) | — |
| `paid_at_utc` | DateTime | Thời điểm thanh toán (UTC) |
| `paid_at_local` | DateTime | Thời điểm thanh toán (local timezone kho) |
| `production_at` | Nullable(DateTime) | Mốc bắt đầu SLA (cutoff logic) |
| `is_shifted_production` | UInt8 | 1 nếu paid sau cutoff → production sang ngày hôm sau |
| `fulfilled_at` | Nullable(DateTime) | Fulfilled (local) |
| `first_scanned_at` | Nullable(DateTime) | First USPS scan (local) |
| `delivered_at` | Nullable(DateTime) | Delivered (local) |
| `processing_hour/day` | Nullable(Int16/Float32) | production → fulfilled (biz hours/days) |
| `first_scan_hour/day` | Nullable(Int16/Float32) | fulfilled → first scan (biz hours/days) |
| `shipping_hour/day` | Nullable(Int16/Float32) | fulfilled → delivered (biz hours/days) |

### Điểm quan trọng

- `first_scanned_at_utc` lấy từ `nh_order_activities WHERE oact_activity = 'pickup'`
- **Platform orders không có 'pickup' event trong `nh_order_activities`** → `first_scanned_at` = NULL → `first_scan_day` = NULL
- TAL (paid → first scan) trong `order-sla` = `ceil(processing_day) + first_scan_day`

---

## 2. `v__usps_fulfilled_to_first_scan_days` — Platform: fulfilled → first scan

**Type:** View
**Mục đích:** Tính biz days từ fulfilled → first USPS scan, cho Platform orders

### Sources

| Table | Join type | Điều kiện |
|---|---|---|
| `geadb__bronze.nh_order_activities` | base | `oact_activity = 'fulfilled'`, `oact_time >= '2025-08-01 16:31:00'` |
| `gea__silver.v__usps_tracking_first_scan` | INNER JOIN | `ord_id` |
| `geadb__bronze.nh_order` | INNER JOIN | `ord_id >= 12000000` |
| `gea__silver.dim_time_bd` | INNER JOIN × 2 | join theo date: fulfilled_date, first_scan_date |

### Logic

```sql
fulfilled_time = max(oact_time) WHERE oact_activity = 'fulfilled'  -- per ord_id

first_scan_time = từ v__usps_tracking_first_scan (xem mục 3)

fulfilled_to_first_scan_days = greatest(
    dt_scan.business_day_seq - dt_fulfilled.business_day_seq,
    0
)
-- Dùng dim_time_bd.business_day_seq (khác với dim_time.cum_bd ở view kế tiếp)
```

### Output columns

| Column | Ý nghĩa |
|---|---|
| `cus_id` | Customer ID |
| `ord_id` | Order ID |
| `tracking_number` | USPS tracking number |
| `fulfilled_time` | DateTime (UTC) |
| `first_scan_time` | DateTime64(3, UTC) |
| `fulfilled_to_first_scan_days` | UInt32 — biz days fulfilled → first scan |

---

## 3. `v__usps_paided_to_first_scan_days` — Platform: paid → first scan (TAL)

**Type:** View
**Mục đích:** Tính biz days từ payment → first USPS scan, cho Platform orders. Đây là TAL metric dùng trong `order-sla`.

### Sources

| Table | Join type | Điều kiện |
|---|---|---|
| `geadb__bronze.nh_order` | base | — |
| `gea__silver.v__usps_fulfilled_to_first_scan_days` | LEFT JOIN | `ord_id` |
| `gea__silver.dim_time` | LEFT JOIN × 2 | join theo date: payment_date, first_scan_date |

> **Lưu ý:** View này dùng `dim_time` (có `cum_bd` — cumulative), khác với MV chính dùng `dim_time_bd` (có `business_day_seq`). Hai table khác nhau nhưng cùng tính business days.

### Logic

```sql
payment_date_la = toDate(
    parseDateTimeBestEffortOrNull(toString(ord_payment_datetime), 'America/Los_Angeles'),
    'America/Los_Angeles'
)
-- ord_payment_datetime là Int32 (Unix timestamp dạng số)

first_scan_date_la = toDate(toTimeZone(first_scan_time, 'America/Los_Angeles'))

-- dim_time: cumulative business days từ đầu lịch sử
business_days_exclude_payment = cum_bd(first_scan_date) - cum_bd(payment_date)
business_days_inclusive        = business_days_exclude_payment + is_business_day(payment_date)

-- Clamped versions (floor at 0):
business_days_exclude_payment_clamped = greatest(..., 0)
business_days_inclusive_clamped       = greatest(..., 0)
```

### Output columns

| Column | Ý nghĩa |
|---|---|
| `ord_id` | Order ID |
| `ord_payment_datetime` | Int32 — Unix timestamp (raw từ nh_order) |
| `tracking_number` | USPS tracking number |
| `payment_date_la` | Date (LA timezone) |
| `first_scan_time_utc` | DateTime64(3, UTC) |
| `first_scan_date_la` | Date (LA timezone) |
| `calendar_days_diff` | Nullable(Int64) |
| `business_days_exclude_payment` | **Int64 — TAL metric dùng trong order-sla** |
| `business_days_inclusive` | Int64 |
| `*_clamped` | Phiên bản floor at 0 |

---

## 4. `v__usps_tracking_first_scan` — Platform: raw first scan event

**Type:** View
**Source:** `gea__bronze.v__usps_tracking_event_with_gearment`

```sql
SELECT ord_id, trackingNumber AS tracking_number, GMTTimestamp AS first_scan_time
FROM gea__bronze.v__usps_tracking_event_with_gearment
WHERE eventType != 'Tracking Not Available'
  AND gearment_event_code = 'IN TRANSIT'
ORDER BY trackingNumber, GMTTimestamp
LIMIT 1 BY trackingNumber   -- ← first event per tracking number, NOT per ord_id
```

> **Caveat:** `LIMIT 1 BY trackingNumber` — nếu 1 ord_id có nhiều tracking numbers, view có thể trả nhiều rows. Cần `LIMIT 1 BY ord_id` hoặc `min(GMTTimestamp) GROUP BY ord_id` khi join vào MV.

---

## 5. Định Nghĩa "Platform Order"

**Source of truth:** `geadb__bronze.nh_order_source.is_label = 1`

Platform orders bao gồm:
- **Own label:** Customer tự mang shipping label (USPS qua account riêng, hoặc carrier khác)
- **Ship by GM:** GM mua label thay cho customer (nhưng vẫn là label order về mặt OMS)

```
Volume (ord_id >= 13500000):
  is_label = 0 (Standard):  1,235,605 orders
  is_label = 1 (Platform):    678,081 orders

is_label=1 breakdown theo platform:
  Tiktok    465,659
  Poshmark  177,849
  Etsy       20,256
  Ebay       13,355
  Amazon        962

Gearment (pla_id=1): is_label = 0 hoàn toàn → luôn là Standard
```

**USPS tracking subset:**
- `gea__bronze.usps_tracking_event`: 168,939 unique ord_id (ord_id >= 13500000)
- Đây là Platform orders dùng own USPS label mà tracking được import vào hệ thống
- Là **subset** của is_label=1, không phải tất cả

---

## 6. So Sánh Logic Standard vs Platform

| Dimension | Standard (MV hiện tại) | Platform (views hiện tại) |
|---|---|---|
| **First scan source** | `nh_order_activities` (`pickup`) | `gea__bronze.v__usps_tracking_event_with_gearment` (`IN TRANSIT`) |
| **Payment time source** | `nh_transaction.transaction_time` → `paid_at_utc` | `nh_order.ord_payment_datetime` (Int32 Unix ts) |
| **Timezone** | Local (per kho: LA/Chicago) | LA cố định |
| **Business day table** | `dim_time_bd` (`business_day_seq`) | `dim_time` (`cum_bd`) |
| **TAL output column** | `first_scan_day` (Float32, hours/24) | `business_days_exclude_payment` (Int64, whole days) |
| **TAL = paid → first scan** | `ceil(processing_day) + first_scan_day` | `business_days_exclude_payment` trực tiếp |

---

## 7. Event Code Mapping — `usps_scan_events_with_gearment_status`

Lookup table 186 rows, join key: `USPS EVENT CODE` → `eventCode` trong `usps_tracking_event`.

| Gearment Status Category | Event Codes |
|---|---|
| **PRE-TRANSIT** | `89` (pre-shipment), `GC` (return receipt), `GX` (label created/cancelled), `MA` (pre-shipment info), `VP` (carrier pickup scheduled) |
| **IN TRANSIT** | Tất cả codes còn lại (80+ codes) — acceptance, processing, in transit, out for delivery, exceptions |
| **DELIVERED** | `01` (delivered), `13` (to authorized agent), `43` (picked up), `60` (to college/agent), `61` (received by agent), `62` (recipient notified), `63` (delivered to recipient by agent), `LD` (arrival at destination) |
| **FAILED DELIVERY** | `04, 09, 11, 21–33, 44, 64, 86, 87, F3, F4, F6, MT, SU` |

**Lưu ý:** Một số eventCode xuất hiện trong nhiều category (e.g., `01` trong cả DELIVERED và FAILED DELIVERY, `10` trong cả IN TRANSIT và FAILED DELIVERY, `44` trong cả hai). Approach inline dùng explicit code list tránh ambiguity này.

**Cách inline thay vì join lookup:**
- First scan: `eventCode NOT IN ('89','GC','GX','MA','VP') AND eventType != 'Tracking Not Available'` — loại PRE-TRANSIT, lấy min timestamp
- Delivered: `eventCode IN ('01','13','43','60','61','62','63','LD')` — lấy min timestamp

**Type info:**
- `usps_tracking_event.ord_id`: `Int32` (range 14,648,328–15,414,116 as of 2026-03-23)
- `usps_tracking_event.GMTTimestamp`: `DateTime64(3,'UTC')`
- `usps_tracking_event.eventCode`: `LowCardinality(String)`
- `usps_tracking_event.eventType`: `LowCardinality(String)`

**Verified (sample ~61K orders, ord_id 14.6M–15.0M):**
- 86% có first_scan (52,770 / 61,317)
- 86% có delivered (52,698 / 61,317)
- 14% NULL = label created nhưng không drop off, hoặc sparse tracking

---

## 6. Hướng Unified (kết luận từ explore session)

Thay vì join `v__usps_paided_to_first_scan_days` (3 lớp views), thêm trực tiếp vào MV:

```sql
-- Thêm vào base_order_data (sau nh_order_activities subquery):
ANY LEFT JOIN (
    SELECT ord_id, min(GMTTimestamp) AS platform_first_scan_utc
    FROM gea__bronze.v__usps_tracking_event_with_gearment
    WHERE eventType != 'Tracking Not Available'
      AND gearment_event_code = 'IN TRANSIT'
    GROUP BY ord_id
) AS pt ON o.ord_id = pt.ord_id

-- Trong SELECT của base_order_data:
COALESCE(oa.first_scanned_at_utc, pt.platform_first_scan_utc) AS first_scanned_at_utc,
if(pt.ord_id IS NOT NULL, 1, 0) AS is_platform
```

**Kết quả:**
- `fact_ofp.first_scan_day` → đúng cho cả Standard và Platform
- `fact_ofp.is_platform` → flag để filter
- `platform_tal_days` → **không cần** (bỏ khỏi design cũ)
- Phần còn lại của MV không đổi

**Câu hỏi còn mở:** `v__usps_tracking_event_with_gearment` là view hay table? Nếu là view, cần xem thêm 1 layer để inline hoàn toàn.

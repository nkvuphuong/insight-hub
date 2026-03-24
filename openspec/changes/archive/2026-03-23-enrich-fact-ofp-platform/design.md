# Design — enrich-fact-ofp-platform

> Xem `logic-reference.md` để hiểu logic hiện tại của MV và các views liên quan trước khi đọc file này.

## Context

`fact_order_fulfillment_performance` là bảng ReplacingMergeTree được populate bởi MV `mv__fact_order_fulfillment_performance` chạy full refresh mỗi 4 giờ.

**Platform order** = đơn có `is_label = 1` trong `nh_order_source`. Đây là những đơn đính kèm shipping label từ bên thứ 3 — customer tự mang label hoặc GM mua thay (Ship by GM). Khác với Standard (Gearment mua label qua hệ thống riêng).

Hiện tại MV không join `nh_order_source` → không có thông tin `is_label` → `is_platform` = NULL → không phân biệt được hai nhóm.

Ngoài ra, Platform orders dùng own label (không phải Ship by GM) có tracking qua USPS system riêng → `first_scanned_at` từ `nh_order_activities` là NULL cho nhóm này → `first_scan_day` = NULL.

## Approach — Unified

```
Step 1: Thêm is_platform — join nh_order_source, lấy is_label
Step 2: Fix first_scanned_at — COALESCE Standard tracking và Platform USPS tracking
        → first_scan_day đúng cho cả hai nhóm
```

---

## Step 1 — Thêm `is_platform` flag

### Column Spec

| Column | Type | Default | Ý nghĩa |
|---|---|---|---|
| `is_platform` | `UInt8` | `0` | `1` = Platform order (`is_label = 1` trong `nh_order_source`), `0` = Standard |

**Định nghĩa Platform order:**
- Customer tự mang label (own 3rd-party label, bao gồm USPS qua account riêng)
- Hoặc GM mua label thay cho customer (Ship by GM)
- Source of truth: `nh_order_source.is_label = 1`

**Lưu ý:**
- Platform orders dùng Ship by GM: tracking qua `nh_order_activities` (giống Standard) → `first_scan_day` đã đúng
- Platform orders dùng own USPS label: tracking qua `gea__bronze.usps_tracking_event` → `first_scan_day` = NULL cho đến khi Step 2

### ALTER TABLE

```sql
-- Thêm column is_platform vào fact table
-- DEFAULT 0 để backward compatible — existing rows có giá trị 0 cho đến khi MV refresh
ALTER TABLE gea__silver.fact_order_fulfillment_performance
    ADD COLUMN IF NOT EXISTS is_platform UInt8 DEFAULT 0
        COMMENT 'Platform order flag: 1 = is_label=1 trong nh_order_source (customer tự mang label hoặc Ship by GM), 0 = Standard (Gearment mua label qua hệ thống riêng)';
```

### MV — Thay đổi

Thêm JOIN `nh_order_source` vào `base_order_data`, propagate `is_platform` qua các CTEs, thêm vào SELECT cuối.

**JOIN thêm vào `base_order_data` (sau `oa` subquery):**

```sql
-- is_platform: join nh_order_source để lấy is_label
-- nh_order_source là SharedReplacingMergeTree → cần FINAL
-- ANY LEFT JOIN: nếu ord_id không có trong nh_order_source → is_platform = 0 (DEFAULT)
ANY LEFT JOIN geadb__bronze.nh_order_source FINAL AS os ON o.ord_id = os.ord_id
```

**Thêm vào SELECT của `base_order_data`:**

```sql
-- is_platform: 1 nếu is_label=1 trong nh_order_source, 0 nếu Standard hoặc không có record
-- toUInt8() để match type của column trong fact table
-- Lưu ý: is_label là UInt16 trong source → cast sang UInt8
if(os.is_label = 1, toUInt8(1), toUInt8(0)) AS is_platform
```

**Propagate qua các CTEs:**

Thêm `is_platform` vào SELECT của mỗi CTE trung gian (pass-through, không transform):

```sql
-- production_schedule, lifecycle_timestamps, business_day_indices,
-- raw_time_differences, business_hour_metrics — mỗi CTE thêm:
is_platform
```

**Thêm vào column list và SELECT cuối của MV:**

```sql
-- Column list (AS block):
`is_platform` UInt8

-- SELECT cuối:
is_platform  -- pass-through từ business_hour_metrics
```

### Verification sau Step 1

```sql
-- 1. Kiểm tra column tồn tại với đúng type
DESCRIBE TABLE gea__silver.fact_order_fulfillment_performance;
-- → thấy is_platform UInt8

-- 2. Sau MV refresh (~4h): kiểm tra phân phối is_platform
SELECT
    is_platform,
    count()            AS order_count,
    min(paid_at_utc)   AS earliest_order,
    max(paid_at_utc)   AS latest_order
FROM gea__silver.fact_order_fulfillment_performance FINAL
GROUP BY is_platform
ORDER BY is_platform;
-- → is_platform=0 chiếm đa số, is_platform=1 là minority

-- 3. Cross-check với source: so sánh Platform count
SELECT uniqExact(ord_id) AS platform_source_count
FROM geadb__bronze.nh_order_source FINAL
WHERE ord_id >= 13500000
  AND is_label = 1;
-- → Số này phải khớp với countIf(is_platform = 1) từ fact_ofp FINAL
-- (sai số nhỏ chấp nhận được do timing giữa MV refresh và query)
```

---

## Step 2 — Fix `first_scanned_at` và `delivered_at` cho Platform own-label orders (planned)

> Implement sau khi Step 1 verified.

Platform orders dùng own USPS label có tracking trong `gea__bronze.usps_tracking_event`.
Cần COALESCE để unify `first_scanned_at_utc` và `delivered_at_utc`.

**Nguồn:** `gea__bronze.usps_tracking_event` — query trực tiếp, không join view (view scan toàn bộ 8.6M rows, chậm).

**Event code mapping** (từ `usps_scan_events_with_gearment_status`):

| Gearment Category | Event Codes |
|---|---|
| PRE-TRANSIT (loại trừ) | `89, GC, GX, MA, VP` |
| IN TRANSIT (first scan) | Tất cả codes còn lại khi `eventType != 'Tracking Not Available'` |
| DELIVERED | `01, 13, 43, 60, 61, 62, 63, LD` |

**Type notes:**
- `usps_tracking_event.ord_id` là `Int32` → cần `toInt64()` khi join với `nh_order.ord_id` (`Int64`)
- `usps_tracking_event.GMTTimestamp` là `DateTime64(3,'UTC')` → cast sang `DateTime('UTC')` khi COALESCE với `oa.*_at_utc`
- `minIf()` trả về epoch (1970-01-01) khi không có row nào match → cần `nullIf(..., toDateTime(0, 'UTC'))` trước COALESCE

```sql
-- (A) Subquery trong base_order_data — sau `oa` subquery, trước closing paren
ANY LEFT JOIN (
    SELECT
        toInt64(ord_id) AS ord_id,
        -- First non-PRE-TRANSIT event = USPS first physical scan
        minIf(GMTTimestamp, eventCode NOT IN ('89','GC','GX','MA','VP')
              AND eventType != 'Tracking Not Available') AS platform_first_scan_utc,
        -- First DELIVERED event
        minIf(GMTTimestamp, eventCode IN ('01','13','43','60','61','62','63','LD'))
              AS platform_delivered_utc
    FROM gea__bronze.usps_tracking_event
    GROUP BY ord_id
) AS pt ON o.ord_id = pt.ord_id

-- (B) Thay oa.first_scanned_at_utc và oa.delivered_at_utc trong SELECT base_order_data:
-- nullIf để convert epoch → NULL (minIf trả về epoch khi không match, không phải NULL)
COALESCE(
    nullIf(oa.first_scanned_at_utc, toDateTime(0, 'UTC')),
    nullIf(toDateTime(pt.platform_first_scan_utc, 'UTC'), toDateTime(0, 'UTC'))
) AS first_scanned_at_utc,
COALESCE(
    nullIf(oa.delivered_at_utc, toDateTime(0, 'UTC')),
    nullIf(toDateTime(pt.platform_delivered_utc, 'UTC'), toDateTime(0, 'UTC'))
) AS delivered_at_utc
```

**Verification data (sample ~61K orders, ord_id 14.6M–15.0M):**
- 86% có `platform_first_scan_utc` (52,770 / 61,317)
- 86% có `platform_delivered_utc` (52,698 / 61,317)
- 14% NULL = đơn chỉ có PRE-TRANSIT events (label created nhưng chưa drop off) hoặc sparse tracking

Sau Step 2:
- `first_scan_day`, `shipping_day` đúng cho Standard, Platform Ship-by-GM, Platform own-USPS-label
- Platform non-USPS own-label: `first_scan_day` = NULL (không có tracking data — acceptable caveat)

---

## Risks / Caveats

**[Safety] Dùng `CREATE OR REPLACE` thay vì `DROP + CREATE`** → nếu DDL lỗi, MV cũ vẫn còn nguyên, không bị mất. Áp dụng cho mọi lần chỉnh sửa MV.

**[Caveat] Platform non-USPS label** → `is_platform = 1` nhưng `first_scan_day = NULL`. Downstream queries cần `WHERE first_scan_day IS NOT NULL` khi tính SLA cho Platform.

**[Caveat] `usps_tracking_event` partial scan** (Step 2) → dùng `uniqExact(ord_id)` khi verify, không dùng `count()`.

**[Note] Backward compatible** → `is_platform DEFAULT 0`. Existing queries không bị ảnh hưởng.

**[Note] `nh_order_source` cần FINAL** → SharedReplacingMergeTree, dedup cần thiết.

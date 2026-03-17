# Schema: gea__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 14 (incl. views và backup tables)

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `usps_tracking_event` | ~8.3M | USPS tracking events |
| `ai_ocr_parser` | ~186K | OCR parsed shipping labels |
| `ocr` | ~186K | Raw OCR data |
| `usps_scan_events_with_gearment_status` | 186 | Mapping USPS event code → Gearment status |
| `ai_ocr_parser__backup` | ~110K | Backup OCR parser data |
| `ocr_backup` | ~110K | Backup OCR raw data |
| `usps_tracking_event__backup` | ~1M | Backup tracking events |
| `v__usps_active_ocr` | View | Active OCR records |
| `v__usps_active_tracking_last14d` | View | Tracking active trong 14 ngày |
| `v__usps_not_yet_delivered` | View | Chưa được giao |
| `v__usps_not_yet_get_tracking` | View | Chưa có tracking |
| `v__usps_tracking_event_with_gearment` | View | Tracking + Gearment status |
| `v__usps_tracking_not_available` | View | Tracking không khả dụng |
| `schema_migrations` | 7 | Migration history |

---

## `usps_tracking_event` 🔵

> Engine: SharedMergeTree | Rows: ~8.3M
> Không phải ReplacingMergeTree — không cần FINAL. Dữ liệu tracking events từ USPS API.

| Column | Type | Ghi chú |
|---|---|---|
| `ord_id` | Int32 | Internal order ID (legacy) |
| `trackingNumber` | String | USPS tracking number |
| `tracking_hash` | UInt64 | Hash của tracking number |
| `eventCity` | LowCardinality(String) | Thành phố sự kiện |
| `eventCode` | LowCardinality(String) | Mã sự kiện USPS |
| `eventState` | LowCardinality(String) | Bang |
| `eventTimestamp` | LowCardinality(String) | Timestamp dạng string |
| `eventType` | LowCardinality(String) | Loại sự kiện |
| `eventZIPCode` | String | ZIP code |
| `GMTTimestamp` | DateTime64(3,'UTC') | Thời gian UTC |
| `GMTOffset` | String | GMT offset |
| `mailingDate` | Nullable(String) | Ngày gửi |
| `_processed_at` | DateTime64(3,'UTC') | |

---

## `ai_ocr_parser` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~186K
> Dùng `FINAL` khi query để dedup. Kết quả OCR parse shipping labels.

| Column | Type | Ghi chú |
|---|---|---|
| `ord_id` | Int32 | Internal order ID |
| `link` | String | Link ảnh label |
| `source` | String | Nguồn |
| `source_time` | DateTime64(3,'UTC') | |
| `carrier` | Nullable(String) | Carrier nhận dạng được |
| `tracking_number` | String | Tracking number parsed |
| `sender_city` | Nullable(String) | |
| `sender_state` | Nullable(String) | |
| `sender_zip` | Nullable(String) | |
| `sender_country` | Nullable(String) | |
| `receiver_city` | Nullable(String) | |
| `receiver_state` | Nullable(String) | |
| `receiver_zip` | Nullable(String) | |
| `receiver_country` | Nullable(String) | |
| `tracking_hash` | UInt64 | |
| `_processed_at` | DateTime64(3,'UTC') | |

---

## `ocr` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~186K
> Dùng `FINAL` khi query để dedup. Raw OCR text từ ảnh label.

| Column | Type | Ghi chú |
|---|---|---|
| `ord_id` | Int32 | |
| `link` | String | Link ảnh |
| `text` | String | Raw OCR text |
| `source_time` | DateTime64(3,'UTC') | |
| `ocr_json` | String | JSON result từ OCR engine |
| `source` | String | |
| `error_message` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |

---

## `usps_scan_events_with_gearment_status` 🔵

> Engine: SharedMergeTree | Rows: 186
> Lookup table: mapping USPS event codes → Gearment status categories.

| Column | Type | Ghi chú |
|---|---|---|
| `USPS EVENT CODE` | String | Mã sự kiện USPS |
| `Internal/Intranet Description` | Nullable(String) | |
| `Customer Extract Description` | Nullable(String) | |
| `External (USPS.com) Second Level Scripting` | Nullable(String) | |
| `External (USPS.com) First Level Scripting` | Nullable(String) | |
| `External (USPS.com) Status Category` | Nullable(String) | |
| `Event Description` | Nullable(String) | |
| `Start the Clock Event?` | Nullable(String) | |
| `Stop the Clock Event?` | Nullable(String) | |
| `Last update` | Nullable(String) | |
| `Gearment Status Category` | Nullable(String) | Mapping vào trạng thái Gearment |

---

## Views 👁️

### `v__usps_active_ocr`
> Fields: `ord_id`, `link`, `source_time`

### `v__usps_active_tracking_last14d`
> Fields: `ord_id`, `tracking_number`

### `v__usps_not_yet_delivered`
> Fields: `ord_id`, `tracking_number`

### `v__usps_not_yet_get_tracking`
> Fields: `ord_id`, `tracking_number`

### `v__usps_tracking_event_with_gearment`
> Fields: full tracking event + `gearment_event_code` (joined với lookup table)

### `v__usps_tracking_not_available`
> Fields: `ord_id`, `tracking_number`

---

## Internal Tables (excluded)

- `ai_ocr_parser__backup` — ~110K rows, backup data cũ
- `ocr_backup` — ~110K rows
- `usps_tracking_event__backup` — ~1M rows

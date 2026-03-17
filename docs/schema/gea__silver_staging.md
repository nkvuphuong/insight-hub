# Schema: gea__silver_staging

**Layer:** Silver Staging (USPS shipping analysis)
**Last updated:** 2026-03-14
**Total tables:** 7 (2 MergeTree + 5 Views)

---

## Tổng quan

Database staging chuyên về **USPS shipping SLA** — đo thời gian từ lúc fulfill đến lúc giao hàng. Phụ thuộc vào `gea__bronze_staging` (chưa explore) và `gea_silver.dim_time`.

| Table | Engine | Rows | Mô tả |
|---|---|---|---|
| `dim_shipping_event_code` | SharedReplacingMergeTree | 130 | Mapping event code → GM event code (multi-carrier) |
| `dim_usps_event_code` | SharedReplacingMergeTree | 75 | Mapping event code → GM event code (USPS only) |
| `usps_shipping_day` | View | — | Shipping time (business days) per order |
| `usps_label_event_first_scan` | View | — | Thời điểm first scan in-transit per tracking |
| `usps_label_percent_violate_sla` | View | — | % đơn vi phạm SLA theo ngày fulfill |
| `usps_label_zipcode_diff_warehouse` | View | — | Đơn có zip sender khác warehouse |
| `usps_label_zipcode_diff_warehouse_top` | View | — | Top sellers có zip sender khác warehouse |

---

## Dimension Tables

### dim_shipping_event_code
**Engine:** SharedReplacingMergeTree | **Sort:** provider, carrier, event_code | **Rows:** 130
**Mô tả:** Chuẩn hóa event codes từ nhiều carrier về GM event codes

| Column | Type | Mô tả |
|---|---|---|
| event_code | String | Code gốc từ carrier |
| gm_event_code | LowCardinality(String) | Code chuẩn hóa GM (vd: `in-transit`, `delivered`) |
| event_description | String | Mô tả event |
| provider | LowCardinality(String) | Provider (USPS, DHL...) |
| carrier | LowCardinality(String) | Carrier cụ thể |
| created_at | DateTime | |
| updated_at | DateTime | Version key cho ReplacingMergeTree |

---

### dim_usps_event_code
**Engine:** SharedReplacingMergeTree | **Sort:** provider, event_code | **Rows:** 75
**Mô tả:** Giống `dim_shipping_event_code` nhưng chỉ cho USPS (không có cột `carrier`)

| Column | Type | Mô tả |
|---|---|---|
| event_code | String | USPS event code |
| gm_event_code | LowCardinality(String) | GM event code |
| event_description | String | Mô tả |
| provider | LowCardinality(String) | Provider (USPS) |
| created_at | DateTime | |
| updated_at | DateTime | |

---

## Views

### usps_shipping_day
**Engine:** View | **Mô tả:** Tính số ngày vận chuyển (business days) từ fulfilled → delivered, per order

| Column | Type | Mô tả |
|---|---|---|
| cus_id | Int32 | Customer ID |
| ord_id | Int32 | Order ID |
| tracking_number | Nullable(String) | Tracking number |
| fulfilled_time | DateTime | Thời điểm fulfilled |
| delivered_time | DateTime64(3, UTC) | Thời điểm delivered |
| shipping_time_business_days | UInt64 | Số ngày giao hàng (business days) |

> **Logic:** Join `nh_order_activities` (fulfilled event) + USPS tracking (delivered event) + `gea_silver.dim_time` (calendar). Chỉ tính từ ord_id >= 14,000,000.

---

### usps_label_event_first_scan
**Engine:** View | **Mô tả:** Thời điểm first in-transit scan per tracking, và số ngày từ fulfilled → first scan

| Column | Type | Mô tả |
|---|---|---|
| ord_id | Int32 | Order ID |
| trackingNumber | String | Tracking number |
| fulfilled_time | DateTime | Thời điểm fulfilled |
| first_scan_time | DateTime64(3, UTC) | Thời điểm scan in-transit đầu tiên |
| fulfilled_to_first_scan_days | Int64 | Số ngày từ fulfilled → first scan |

> **Logic:** Lấy event có `gm_event_code = 'in-transit'` sớm nhất, join với `usps_shipping_day`.

---

### usps_label_percent_violate_sla
**Engine:** View | **Mô tả:** % đơn vi phạm SLA (> 5 business days) theo ngày fulfill

| Column | Type | Mô tả |
|---|---|---|
| fulfill_date | Date | Ngày fulfilled |
| late_delivery_percentage | Float64 | % đơn giao trễ (shipping_time > 5 business days) |

> **SLA threshold:** 5 business days.

---

### usps_label_zipcode_diff_warehouse
**Engine:** View | **Mô tả:** Các đơn có sender zip khác với warehouse standard (92843=CA, 77478=TX)

| Column | Type | Mô tả |
|---|---|---|
| id | String | Order ID |
| tracking_number | Nullable(String) | Tracking number |
| sender_zip | Nullable(String) | Zip gửi thực tế (từ OCR label) |
| cus_id | Int32 | Customer ID |

> **Dùng để phát hiện:** Label in sai địa chỉ kho, hoặc đơn gửi từ địa điểm không phải warehouse.

---

### usps_label_zipcode_diff_warehouse_top
**Engine:** View | **Mô tả:** Tổng hợp số tracking bất thường theo customer

| Column | Type | Mô tả |
|---|---|---|
| cus_id | Int32 | Customer ID |
| total_tracking | UInt64 | Số tracking có zip bất thường |

---

## Ghi Chú

- Database này phụ thuộc `gea__bronze_staging` — chưa explore database đó
- `dim_time` được reference từ `gea_silver.dim_time` (không có trong gea_silver tables list — có thể đã rename hoặc dùng bản khác)
- Views ở đây chỉ có giá trị cho báo cáo **USPS SLA / delivery performance**
- **Không dùng** cho báo cáo order performance tổng quát

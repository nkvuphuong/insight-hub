# Schema: gea__silver

**Layer:** Silver (fact tables, dimensions, enriched từ geadb__bronze)
**Last updated:** 2026-03-24
**Tables:** 41 (bao gồm views và internal materialized views)
**Main tables:** 37 (trừ 4 internal `mv__`* tables)

---

## Quick Reference — Tables theo nhóm

### Dictionaries (in-memory lookup, không cần JOIN)

- `dict_attribute` — attribute ID → quantity
- `dict_exproduct` — external product ID → name, SKU
- `dict_item_status` — item status code → business status *(mới, columns chưa explore)*
- `dict_order_payment_method` — payment method code → name *(mới, columns chưa explore)*
- `dict_order_status` — ord_status_custom → business status
- `dict_payment_status` — payment_status → business status
- `dict_platform` — platform lookup *(mới, columns chưa explore)*
- `dict_platform_label` — method_insert_subtype → pla_id + business_status_name (4 rows: ebay, etsy, poshmark, tiktok)
- `dict_product_type` — ordi_type → type_name

### Dimensions

- `dim_business_day` — calendar of business days (~7.7K rows)
- `dim_facility` — fulfill facilities (3 rows: US, VN, etc.)
- `dim_item_status` — item status lookup (7 rows) *(mới, columns chưa explore)*
- `dim_order_identity` — order ID mapping: OMS ID ↔ vendor_ref ↔ seller/store (~14.6M rows)
- `dim_order_payment_method` — payment method lookup (4 rows) *(mới, columns chưa explore)*
- `dim_order_status_mapping` — order status code → business status (16 rows)
- `dim_payment_status_mapping` — payment status code → business status (4 rows)
- `dim_platform_label` — platform label mapping (4 rows: ebay, etsy, poshmark, tiktok) *(mới)*
- `dim_seller` — seller dimension (0 rows — empty)
- `dim_time` — date dimension (~11.3K rows) ⭐
- `dim_time_bd` — date dimension with business day sequence (~11.3K rows)

### Fact Tables

- `fact_order` — enriched orders (0 rows — empty)
- `fact_order_event` — order events / CDC-style events (0 rows — empty)
- `fact_order_fulfillment_performance` — fulfillment SLA per order (~1.73M rows) ⭐ — *+`is_platform` 2026-03-23*
- `fact_order_fulfillment_performance_by_product` — fulfillment SLA per order+product (~1.5M rows) — *+`is_platform` 2026-03-23*
- `fact_order_line` — order line items (0 rows — empty, dùng `v__fact_order_line` thay thế)
- `fact_production_order_sla_tracker` — live SLA tracker per order item (~1.9K rows)
- `fact_production_order_sla_tracker_daily_snapshot` — daily snapshots of SLA (~270K rows)

> ⚠️ `fact_order_v1` và `fact_order_v3` không còn tồn tại trong ClickHouse (verified 2026-03-24).

### Views (không cần FINAL)

- `v__fact_order_line` — view trên fact_order_line
- `v__g5000_dtg_campaign_2025` — G5000 DTG campaign 2025 data
- `v__order_production_sla_backlog_daily_clearance` — daily backlog clearance
- `v__usps_fulfilled_to_delivered_days` — USPS fulfilled → delivered days
- `v__usps_fulfilled_to_first_scan_days` — USPS fulfilled → first scan days
- `v__usps_paided_to_first_scan_days` — USPS paid → first scan days
- `v__usps_shipping_day` — USPS shipping days (business days)
- `v__usps_tracking_first_scan` — first scan events
- `v_production_backlog_clearance_intraday` — intraday backlog clearance

### Internal (không query trực tiếp)

- `mv__fact_order_fulfillment_performance` — MV populating fact_order_fulfillment_performance
- `mv__fact_order_fulfillment_performance_by_product` — MV populating by_product variant
- `mv__fact_production_order_sla_tracker` — MV populating sla_tracker
- `mv__g5000_dtg_campaign_2025` — MV for DTG campaign
- `g5000_dtg_campaign_2025__mv` — backing table cho `v__g5000_dtg_campaign_2025` (~11.9K rows)

---

## Tables (chi tiết)

> 🔄 = SharedReplacingMergeTree (cần FINAL)
> 🔵 = SharedMergeTree / Dictionary / View (không cần FINAL)

---

### `dict_attribute` 🔵

> Engine: Dictionary | Rows: -
> In-memory lookup: attribute ID → quantity


| Column        | Type    | Ghi chú |
| ------------- | ------- | ------- |
| attr_id       | UInt64  | PK      |
| attr_quantity | Float64 |         |


---

### `dict_exproduct` 🔵

> Engine: Dictionary | Rows: -
> In-memory lookup: external product info


| Column   | Type   | Ghi chú      |
| -------- | ------ | ------------ |
| exp_id   | UInt64 | PK           |
| exp_name | String | tên sản phẩm |
| exp_sku  | String | SKU          |


---

### `dict_order_status` 🔵

> Engine: Dictionary | Rows: -
> In-memory lookup: ord_status_custom → business status


| Column               | Type   | Ghi chú                                        |
| -------------------- | ------ | ---------------------------------------------- |
| ord_status_custom    | UInt64 | PK (lookup key)                                |
| business_status_code | Int8   | business status code                           |
| business_status_name | String | human-readable status ⭐                        |
| status_group         | String | status group (e.g. 'fulfilled', 'cancelled') ⭐ |
| ord_status           | Int8   | raw ord_status                                 |
| is_terminal          | UInt8  | 1 = terminal state                             |
| is_success           | UInt8  | 1 = successful terminal                        |
| is_failure           | UInt8  | 1 = failed terminal                            |


---

### `dict_payment_status` 🔵

> Engine: Dictionary | Rows: -
> In-memory lookup: payment_status → business status


| Column               | Type   | Ghi chú             |
| -------------------- | ------ | ------------------- |
| payment_status       | UInt64 | PK (lookup key)     |
| business_status_name | String | human-readable name |
| description          | String |                     |
| is_terminal          | UInt8  |                     |
| is_success           | UInt8  |                     |
| is_failure           | UInt8  |                     |


---

### `dict_product_type` 🔵

> Engine: Dictionary | Rows: -
> In-memory lookup: ordi_type → type_name


| Column    | Type   | Ghi chú                        |
| --------- | ------ | ------------------------------ |
| ordi_type | UInt64 | PK (= nh_order_item.ordi_type) |
| type_name | String | product type name ⭐            |


---

### `dim_business_day` 🔵

> Engine: SharedMergeTree | Rows: ~7.7K
> Business day calendar


| Column      | Type   | Ghi chú                         |
| ----------- | ------ | ------------------------------- |
| full_date   | Date   | PK / ORDER BY                   |
| biz_day_idx | UInt32 | business day index (sequential) |


---

### `dim_facility` 🔵

> Engine: SharedMergeTree | Rows: 3
> Fulfill facility lookup (US, VN, etc.)


| Column     | Type   | Ghi chú              |
| ---------- | ------ | -------------------- |
| id         | String | PK (e.g. 'US', 'VN') |
| name       | String | facility name        |
| state_code | String | state/location code  |


---

### `dim_order_identity` 🔄

> Engine: SharedReplacingMergeTree | Rows: ~14.6M
> **Cần FINAL khi query**
> Maps order_key ↔ order IDs ↔ seller/store info


| Column     | Type                | Ghi chú                   |
| ---------- | ------------------- | ------------------------- |
| order_key  | UInt64              | surrogate key (PK)        |
| vendor_ref | String              | internal vendor reference |
| order_id   | String              | order ID string           |
| seller_id  | String              | seller ID ⭐               |
| team_id    | String              | team ID ⭐                 |
| store_id   | String              | store ID ⭐                |
| created_at | DateTime64(3,'UTC') |                           |
| updated_at | DateTime64(3,'UTC') |                           |


---

### `dim_order_status_mapping` 🔵

> Engine: SharedMergeTree | Rows: 16
> Order status mapping table (relational version of dict_order_status)


| Column               | Type   | Ghi chú                  |
| -------------------- | ------ | ------------------------ |
| ord_status_custom    | Int8   | order custom status code |
| business_status_code | Int8   |                          |
| business_status_name | String | human-readable ⭐         |
| status_group         | String | status group ⭐           |
| ord_status           | Int8   | raw status               |
| is_terminal          | UInt8  |                          |
| is_success           | UInt8  |                          |
| is_failure           | UInt8  |                          |


---

### `dim_payment_status_mapping` 🔵

> Engine: SharedMergeTree | Rows: 4
> Payment status mapping table


| Column               | Type   | Ghi chú             |
| -------------------- | ------ | ------------------- |
| payment_status       | Int8   | payment status code |
| business_status_name | String |                     |
| description          | String |                     |
| is_terminal          | UInt8  |                     |
| is_success           | UInt8  |                     |
| is_failure           | UInt8  |                     |


---

### `dim_item_status` 🔵 *(mới — 2026-03-24)*

> Engine: SharedMergeTree | Rows: 7
> Item status lookup table

*Columns chưa explore (system.columns không accessible cho bảng này)*

---

### `dim_order_payment_method` 🔵 *(mới — 2026-03-24)*

> Engine: SharedMergeTree | Rows: 4
> Payment method lookup table

*Columns chưa explore (system.columns không accessible cho bảng này)*

---

### `dim_platform_label` 🔵 *(mới — 2026-03-24)*

> Engine: SharedMergeTree | Rows: 4
> Platform label mapping — dùng để identify TikTok, Etsy, eBay, Poshmark


| Column                | Type   | Ghi chú                                              |
| --------------------- | ------ | ---------------------------------------------------- |
| method_insert_subtype | Int8   | PK (lookup key = method_insert_subtype từ orders)    |
| pla_id                | Int8   | platform label ID                                    |
| business_status_name  | String | platform name: 'ebay', 'etsy', 'poshmark', 'tiktok' |

---

### `dim_seller` 🔄

> Engine: SharedReplacingMergeTree | Rows: 0 (empty)
> **Cần FINAL khi query**
> Seller dimension (currently empty — data not populated)


| Column      | Type                | Ghi chú       |
| ----------- | ------------------- | ------------- |
| seller_key  | UInt64              | surrogate key |
| seller_id   | String              | seller ID     |
| email       | String              |               |
| team_id     | String              |               |
| system_code | String              |               |
| created_at  | DateTime64(3,'UTC') |               |
| updated_at  | DateTime64(3,'UTC') |               |


---

### `dim_time` 🔵

> Engine: SharedMergeTree | Rows: ~11.3K
> Full date dimension — thường dùng cho time intelligence


| Column                         | Type             | Ghi chú                           |
| ------------------------------ | ---------------- | --------------------------------- |
| date_key                       | Int32            | YYYYMMDD integer key              |
| full_date                      | Date             | date value ⭐                      |
| year                           | Int16            |                                   |
| quarter                        | Int8             | 1-4                               |
| month                          | Int8             | 1-12                              |
| month_name                     | String           | 'January'...'December'            |
| week_of_year                   | Int8             |                                   |
| day_of_month                   | Int8             |                                   |
| day_of_week                    | Int8             |                                   |
| day_name                       | String           | 'Monday'...'Sunday'               |
| is_weekend                     | Bool             |                                   |
| is_month_start                 | Bool             |                                   |
| is_month_end                   | Bool             |                                   |
| is_quarter_start               | Bool             |                                   |
| is_quarter_end                 | Bool             |                                   |
| is_year_start                  | Bool             |                                   |
| is_year_end                    | Bool             |                                   |
| is_business_day                | Bool             |                                   |
| is_holiday                     | Bool             |                                   |
| holiday_name                   | Nullable(String) |                                   |
| holiday_type                   | Nullable(String) |                                   |
| season                         | String           | 'Spring'/'Summer'/'Fall'/'Winter' |
| is_last_business_day_of_month  | Bool             |                                   |
| is_business_day_before_holiday | Bool             |                                   |
| is_business_day_after_holiday  | Bool             |                                   |
| is_long_weekend                | Bool             |                                   |


---

### `dim_time_bd` 🔵

> Engine: SharedMergeTree | Rows: ~11.3K
> Date dimension with business day sequence counter


| Column           | Type   | Ghi chú                         |
| ---------------- | ------ | ------------------------------- |
| full_date        | Date   | PK                              |
| is_business_day  | UInt8  | 1 = business day                |
| business_day_seq | UInt32 | sequential business day counter |


---

### `fact_order` 🔄

> Engine: SharedReplacingMergeTree | Rows: 0 (empty)
> **Cần FINAL khi query**
> Enriched order fact table — hiện rỗng, xem `fact_order_v1` hoặc `fact_order_v3`


| Column                | Type                   | Ghi chú              |
| --------------------- | ---------------------- | -------------------- |
| ord_id                | Int64                  | PK = nh_order.ord_id |
| ord_name              | Nullable(String)       |                      |
| ord_total             | Decimal(20,2)          |                      |
| ord_subtotal          | Decimal(20,2)          |                      |
| ord_profit            | Decimal(20,2)          |                      |
| ord_promotion         | Decimal(20,2)          |                      |
| ord_discount          | Decimal(20,2)          |                      |
| ord_total_discount    | Decimal(20,2)          |                      |
| ord_type_discount     | Int16                  |                      |
| ord_fee_shipping      | Decimal(20,2)          |                      |
| ord_handle_fee        | Decimal(20,2)          |                      |
| ord_vat_total         | Decimal(20,2)          |                      |
| ord_is_vat            | Nullable(Int16)        |                      |
| ord_payment_status    | Nullable(Int16)        |                      |
| ord_payment_method    | Int16                  |                      |
| ord_payment_datetime  | Int64                  | unix payment time    |
| ord_status            | Int16                  |                      |
| ord_deleted           | Int16                  |                      |
| ord_archived          | Int16                  |                      |
| is_approve            | Int16                  |                      |
| ord_tracking_status   | Int16                  |                      |
| ord_status_custom     | Nullable(Int16)        | custom status ⭐      |
| ord_priority          | Int16                  |                      |
| is_issue              | Int16                  |                      |
| ord_issue_status      | Int16                  |                      |
| cus_id                | Int64                  | seller FK            |
| ord_cus_name          | Nullable(String)       | end customer name    |
| ord_cus_email         | String                 | end customer email   |
| ord_cus_country       | Int64                  |                      |
| ord_cus_state         | Int64                  |                      |
| ord_cus_city          | String                 |                      |
| ord_cus_province      | String                 |                      |
| store_id              | Int64                  |                      |
| cam_id                | Int64                  |                      |
| platform_id           | Int16                  |                      |
| promotion_id          | Int64                  |                      |
| method_insert         | Int16                  |                      |
| method_insert_subtype | Int16                  |                      |
| marketplace_id        | Nullable(String)       |                      |
| online_id             | Nullable(String)       |                      |
| online_name           | Nullable(String)       |                      |
| ord_shipping_method   | Int16                  |                      |
| ord_shipping_location | Nullable(Int16)        |                      |
| ord_is_single         | Int16                  |                      |
| ord_is_split          | Nullable(Int16)        |                      |
| is_import             | Int16                  |                      |
| multiple_type         | Int16                  |                      |
| ord_print_provider    | Int16                  |                      |
| ord_time              | DateTime               |                      |
| ord_time_approve      | Int64                  |                      |
| total_line_items      | Int32                  |                      |
| total_quantity        | Int64                  |                      |
| total_line_revenue    | Decimal(20,2)          |                      |
| total_line_profit     | Decimal(20,2)          |                      |
| total_base_cost       | Decimal(20,2)          |                      |
| distinct_products     | Int32                  |                      |
| ord_date              | Date                   | order date ⭐         |
| ord_month             | String                 | 'YYYY-MM'            |
| ord_year              | UInt16                 |                      |
| ord_day_of_week       | UInt8                  |                      |
| is_paid               | UInt8                  | 1 = paid ⭐           |
| is_cancelled          | UInt8                  | 1 = cancelled        |
| margin_rate           | Decimal(10,4)          | profit / revenue     |
| discount_rate         | Decimal(10,4)          |                      |
| _processed_at         | DateTime64(3,'UTC')    |                      |
| _action               | LowCardinality(String) |                      |
| _timestamp            | DateTime64(3,'UTC')    |                      |


---

### `fact_order_event` 🔵

> Engine: SharedMergeTree | Rows: 0 (empty)
> Event sourcing / CDC-style order events — currently empty


| Column       | Type                   | Ghi chú                    |
| ------------ | ---------------------- | -------------------------- |
| event_time   | DateTime64(3,'UTC')    | event timestamp ⭐          |
| event_date   | Date                   | partition key              |
| order_id     | UInt64                 | FK → nh_order              |
| cus_id       | UInt32                 | FK → nh_customer           |
| user_id      | UInt32                 | FK → nh_user               |
| entity_name  | LowCardinality(String) | entity changed             |
| entity_id    | UInt64                 | entity PK                  |
| item_id      | UInt64                 | FK → order_item            |
| event_domain | LowCardinality(String) | domain                     |
| event_type   | LowCardinality(String) | event type ⭐               |
| action       | Enum8                  | 'insert'/'update'/'delete' |
| amount       | Decimal(18,4)          |                            |
| currency     | FixedString(3)         | 'USD'                      |
| value_type   | Enum8                  | value type discriminator   |
| value_str    | String                 | string value               |
| value_i64    | Int64                  | integer value              |
| value_f64    | Float64                | float value                |
| value_dec    | Decimal(18,4)          | decimal value              |
| value_bool   | UInt8                  | bool value                 |
| value_ts     | DateTime64(3,'UTC')    | timestamp value            |
| tags         | Map(String,String)     | additional tags            |
| payload_json | String                 | raw JSON payload           |
| source_table | LowCardinality(String) | source table name          |
| source_pk    | UInt64                 | source PK                  |
| cdc_ts       | DateTime64(3,'UTC')    | CDC timestamp              |
| ingested_at  | DateTime64(3,'UTC')    | ingest time                |
| event_id     | UUID                   | unique event ID            |


---

### `fact_order_fulfillment_performance` 🔄 ⭐

> Engine: SharedReplacingMergeTree | Rows: ~1.73M
> **Cần FINAL khi query**
> Fulfillment SLA tracking per order: paid → production → fulfilled → scanned → delivered
> *2026-03-23: +`is_platform` (enrich-fact-ofp-platform); MV updated (join nh_order_source + COALESCE USPS tracking)*


| Column                | Type                           | Ghi chú                                                                                                |
| --------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------ |
| order_id              | UInt64                         | PK = nh_order.ord_id                                                                                   |
| ordx_fulfill_locate   | LowCardinality(String)         | fulfill location ⭐                                                                                     |
| shipping_scope        | LowCardinality(String)         | shipping scope                                                                                         |
| shipping_class        | LowCardinality(String)         | shipping class (Standard/Express) ⭐                                                                    |
| country_code          | LowCardinality(FixedString(2)) | destination country ⭐                                                                                  |
| country_name          | LowCardinality(String)         | destination country name                                                                               |
| fulfill_timezone      | LowCardinality(String)         | IANA timezone of facility                                                                              |
| paid_at_utc           | DateTime('UTC')                | payment time UTC ⭐                                                                                     |
| paid_at_local         | DateTime                       | payment time local                                                                                     |
| production_at         | Nullable(DateTime)             | production start time                                                                                  |
| fulfilled_at          | Nullable(DateTime)             | fulfillment (ship) time ⭐                                                                              |
| first_scanned_at      | Nullable(DateTime)             | first carrier scan ⭐ — COALESCE(Standard tracking, Platform USPS tracking)                             |
| delivered_at          | Nullable(DateTime)             | delivery time ⭐ — COALESCE(Standard tracking, Platform USPS tracking)                                  |
| is_shifted_production | UInt8                          | 1 = production shifted to next business day                                                            |
| processing_hour       | Nullable(Int16)                | Production Time in hours (paid → fulfilled, production-adjusted)                                       |
| first_scan_hour       | Nullable(Int16)                | Tracking Lag in hours (fulfilled → first scan) ⭐                                                       |
| shipping_hour         | Nullable(Int16)                | Transit time in hours (fulfilled → delivered, calendar hours)                                          |
| processing_day        | Nullable(Float32)              | **Production Time** (paid → fulfilled, production-adjusted days = processing_hour/24) ⭐                |
| first_scan_day        | Nullable(Float32)              | **Tracking Lag** (fulfilled → first scan, **business days**) ⭐                                         |
| shipping_day          | Nullable(Float32)              | Transit time (fulfilled → delivered, calendar days = shipping_hour/24) — **không phải paid→fulfilled** |
| updated_at            | DateTime64(3,'UTC')            |                                                                                                        |
| **is_platform**       | **UInt8**                      | **🆕 1 = Platform order (is_label=1 trong nh_order_source), 0 = Standard** ⭐                           |


---

### `fact_order_fulfillment_performance_by_product` 🔄

> Engine: SharedReplacingMergeTree | Rows: ~1.5M
> **Cần FINAL khi query**
> Same as fact_order_fulfillment_performance but granularity = order + product_type
> *2026-03-23: +`is_platform` (enrich-fact-ofp-by-product); MV updated (join nh_order_source + COALESCE USPS tracking)*


| Column                | Type                   | Ghi chú                                                    |
| --------------------- | ---------------------- | ---------------------------------------------------------- |
| order_id              | UInt64                 | FK → nh_order (sort key)                                   |
| product_type          | LowCardinality(String) | product type name ⭐ (sort key)                             |
| ordx_fulfill_locate   | LowCardinality(String) | fulfill location (sort key)                                |
| fulfill_timezone      | LowCardinality(String) |                                                            |
| paid_at_utc           | DateTime('UTC')        | partition key (toYYYYMM)                                   |
| paid_at_local         | DateTime               |                                                            |
| production_at         | Nullable(DateTime)     |                                                            |
| is_shifted_production | UInt8                  | 1 = production shifted                                     |
| fulfilled_at          | Nullable(DateTime)     |                                                            |
| first_scanned_at      | Nullable(DateTime)     | COALESCE(Standard tracking, Platform USPS tracking)        |
| delivered_at          | Nullable(DateTime)     | COALESCE(Standard tracking, Platform USPS tracking)        |
| processing_hour       | Nullable(Int32)        |                                                            |
| first_scan_hour       | Nullable(Int32)        |                                                            |
| shipping_hour         | Nullable(Int32)        |                                                            |
| processing_day        | Nullable(Float32)      |                                                            |
| first_scan_day        | Nullable(Float32)      |                                                            |
| shipping_day          | Nullable(Float32)      |                                                            |
| updated_at            | DateTime64(3,'UTC')    | version key (ReplacingMergeTree)                           |
| **is_platform**       | **UInt8**              | **🆕 1 = Platform order (is_label=1), 0 = Standard** ⭐    |


---

### `fact_order_line` 🔄

> Engine: SharedReplacingMergeTree | Rows: 0 (empty)
> **Cần FINAL khi query**
> Order line items enriched — hiện rỗng, dùng `v__fact_order_line` thay thế


| Column                | Type                    | Ghi chú                    |
| --------------------- | ----------------------- | -------------------------- |
| item_id               | Int64                   | PK = nh_order_item.ordi_id |
| order_id              | Int64                   | FK → nh_order              |
| order_status          | Int16                   |                            |
| order_payment_status  | Nullable(Int16)         |                            |
| order_payment_method  | Int16                   |                            |
| seller_id             | Int64                   | seller (cus_id)            |
| seller_email          | String                  |                            |
| team_id               | String                  | team ID ⭐                  |
| store_id              | String                  | store ID ⭐                 |
| campaign_id           | Int64                   | FK → nh_campaigns          |
| platform_id           | Int16                   |                            |
| payment_date_utc      | DateTime                | payment datetime UTC ⭐     |
| order_time            | DateTime                | order created time         |
| order_date            | Date                    | order date ⭐               |
| order_month           | String                  | 'YYYY-MM'                  |
| order_type            | String                  | order type label           |
| fulfill_location      | String                  | fulfill location ⭐         |
| fulfill_timezone      | String                  |                            |
| tracking_number       | Nullable(String)        |                            |
| item_price            | Decimal(20,2)           | item selling price ⭐       |
| item_price_original   | Decimal(20,2)           |                            |
| price_extra           | Decimal(20,2)           |                            |
| item_quantity         | Int64                   | quantity ⭐                 |
| units_per_item        | Int16                   |                            |
| item_fee_shipping     | Decimal(20,2)           |                            |
| item_base_cost        | Nullable(Decimal(20,2)) | base cost                  |
| item_printing_cost    | Nullable(Decimal(20,2)) | printing cost              |
| item_vat_total        | Decimal(20,2)           |                            |
| item_handle_fee       | Decimal(20,2)           |                            |
| item_subtotal         | Decimal(20,2)           |                            |
| item_total            | Decimal(20,2)           | item total ⭐               |
| item_profit           | Decimal(20,2)           | item profit ⭐              |
| item_base_price       | Decimal(20,2)           |                            |
| item_time             | DateTime                |                            |
| item_status           | Nullable(Int16)         | item status                |
| item_deleted          | Nullable(Int16)         |                            |
| item_quantity_printed | Nullable(Int16)         |                            |
| item_quantity_error   | Nullable(Int16)         |                            |
| product_group         | String                  | product group ⭐            |
| product_type          | String                  | product type ⭐             |
| product               | String                  | product name ⭐             |
| product_sku           | String                  | SKU ⭐                      |
| item_name             | Nullable(String)        |                            |
| product_campaign_id   | Nullable(Int64)         |                            |
| item_size             | Nullable(Int64)         | size ID                    |
| item_color            | Nullable(Int64)         | color ID                   |
| item_material_id      | Nullable(Int64)         |                            |
| item_print_type       | Nullable(Int64)         |                            |
| item_variant_id       | Nullable(Int64)         |                            |
| source_system         | String                  | 'v1'/'v3'                  |
| _processed_at         | DateTime64(3,'UTC')     |                            |


---

### `fact_order_v1` 🔄 ⭐

> Engine: SharedReplacingMergeTree | Rows: ~14.5M
> **Cần FINAL khi query**
> Main active orders fact table (V1 system orders)


| Column       | Type                | Ghi chú                  |
| ------------ | ------------------- | ------------------------ |
| order_id_oms | Int64               | PK = nh_order.ord_id ⭐   |
| order_id_v3  | String              | V3 system order ID       |
| seller_id    | String              | seller ID ⭐              |
| team_id_v3   | String              | team ID (V3 format) ⭐    |
| store_id_v1  | String              | store ID (V1 format) ⭐   |
| created_at   | DateTime64(3,'UTC') | order created time ⭐     |
| updated_at   | DateTime64(3,'UTC') |                          |
| date_id      | Int32               | FK → dim_time.date_key ⭐ |
| order_total  | Decimal(20,2)       | order total ⭐            |
| shipping_fee | Decimal(20,2)       | shipping fee             |


---

### `fact_order_v3` 🔄

> Engine: SharedReplacingMergeTree | Rows: ~80.5K
> **Cần FINAL khi query**
> V3 system orders fact table


| Column       | Type                | Ghi chú                |
| ------------ | ------------------- | ---------------------- |
| order_id_oms | Int64               | PK = nh_order.ord_id   |
| order_id_v3  | String              | V3 order ID ⭐          |
| seller_id    | String              |                        |
| team_id_v3   | String              |                        |
| store_id_v3  | String              | store ID (V3 format)   |
| created_at   | DateTime64(3,'UTC') |                        |
| updated_at   | DateTime64(3,'UTC') |                        |
| date_id      | Int32               | FK → dim_time.date_key |
| order_total  | Decimal(20,2)       |                        |
| shipping_fee | Decimal(20,2)       |                        |


---

### `fact_production_order_sla_tracker` 🔄 ⭐

> Engine: SharedReplacingMergeTree | Rows: ~1.3K
> **Cần FINAL khi query**
> Live production SLA tracker — active orders in production with deadline tracking


| Column              | Type                   | Ghi chú                                 |
| ------------------- | ---------------------- | --------------------------------------- |
| order_id            | UInt64                 | FK → nh_order                           |
| order_item_id       | UInt64                 | FK → nh_order_item                      |
| product_group       | LowCardinality(String) | product group ⭐                         |
| product_type        | LowCardinality(String) | product type ⭐                          |
| product             | String                 | product name                            |
| product_sku         | LowCardinality(String) | SKU                                     |
| qty                 | UInt32                 | quantity                                |
| units               | UInt32                 | total units                             |
| fulfill_location    | LowCardinality(String) | fulfill location ⭐                      |
| order_type          | LowCardinality(String) | order type                              |
| payment_date        | Date                   | payment date                            |
| payment_date_local  | DateTime               | payment date local                      |
| start_date          | Date                   | production start date                   |
| production_start_at | DateTime               | production start time                   |
| DD                  | Int32                  | deadline day (business days since paid) |
| SLA                 | UInt8                  | SLA target (business days)              |
| priority_score      | Int32                  | calculated priority                     |
| priority_level      | LowCardinality(String) | 'Critical'/'High'/'Medium'/'Low' ⭐      |
| days_to_deadline    | Int32                  | days remaining to SLA deadline ⭐        |
| deadline_status     | String                 | 'On Track'/'At Risk'/'Overdue' ⭐        |
| sla_utilization_pct | Float64                | % of SLA used (0-100+) ⭐                |
| updated_at          | DateTime               |                                         |


---

### `fact_production_order_sla_tracker_daily_snapshot` 🔵

> Engine: SharedMergeTree | Rows: ~228.6K
> Daily snapshots of production SLA tracker — historical record

Cùng columns với `fact_production_order_sla_tracker`, thêm:


| Column              | Type                   | Ghi chú                          |
| ------------------- | ---------------------- | -------------------------------- |
| order_id            | UInt64                 |                                  |
| order_item_id       | UInt64                 |                                  |
| product_group       | LowCardinality(String) |                                  |
| product_type        | LowCardinality(String) |                                  |
| product             | String                 |                                  |
| product_sku         | LowCardinality(String) |                                  |
| qty                 | UInt32                 |                                  |
| units               | UInt32                 |                                  |
| fulfill_location    | LowCardinality(String) |                                  |
| order_type          | LowCardinality(String) |                                  |
| payment_date        | Date                   |                                  |
| payment_date_local  | DateTime               |                                  |
| start_date          | Date                   |                                  |
| production_start_at | DateTime               |                                  |
| DD                  | Int32                  |                                  |
| SLA                 | UInt8                  |                                  |
| priority_score      | Int32                  |                                  |
| priority_level      | LowCardinality(String) |                                  |
| days_to_deadline    | Int32                  |                                  |
| deadline_status     | String                 |                                  |
| sla_utilization_pct | Float64                |                                  |
| updated_at          | DateTime               |                                  |
| snapshot_date       | Date                   | date of snapshot ⭐               |
| snapshot_time       | DateTime               | time of snapshot                 |
| inserted_at         | DateTime               |                                  |
| period_marker       | Enum8                  | 'intraday'/'eod' snapshot marker |


---

### Views

#### `v__fact_order_line` 🔵

> View trên `fact_order_line` — cùng columns, types non-nullable (coalesced 0 thay vì NULL)
> Dùng thay vì `fact_order_line` trực tiếp (bảng gốc hiện rỗng)


| Column                  | Type                      | Ghi chú                     |
| ----------------------- | ------------------------- | --------------------------- |
| `order_id`              | Int64                     | FK → nh_order ⭐             |
| `item_id`               | Int64                     | PK = nh_order_item.ordi_id  |
| `order_status`          | Int16                     |                             |
| `order_payment_status`  | Nullable(Int16)           |                             |
| `order_payment_method`  | Int16                     |                             |
| `seller_id`             | Nullable(String)          | seller (cus_id) ⭐           |
| `seller_email`          | Nullable(String)          |                             |
| `team_id`               | String                    | team ID ⭐                   |
| `store_id`              | String                    | store ID ⭐                  |
| `campaign_id`           | Int64                     | FK → nh_campaigns           |
| `platform_id`           | Int16                     |                             |
| `payment_date_utc`      | Nullable(DateTime('UTC')) | thời điểm thanh toán UTC ⭐  |
| `order_time`            | DateTime                  | thời điểm tạo order         |
| `order_date`            | Date                      | ngày tạo order ⭐            |
| `order_month`           | String                    | 'YYYY-MM'                   |
| `order_type`            | String                    | loại order                  |
| `fulfill_location`      | String                    | facility fulfill ⭐          |
| `fulfill_timezone`      | String                    | IANA timezone của facility  |
| `tracking_number`       | Nullable(String)          |                             |
| `item_price`            | Decimal(18,2)             | giá bán item ⭐              |
| `item_price_original`   | Decimal(18,2)             | giá gốc trước discount      |
| `price_extra`           | Decimal(18,2)             | phí extra                   |
| `item_quantity`         | Int64                     | số lượng ⭐                  |
| `units_per_item`        | Float64                   | units per item (thường = 1) |
| `item_fee_shipping`     | Decimal(18,2)             | phí shipping của item       |
| `item_base_cost`        | Decimal(18,2)             | base cost (giá vốn)         |
| `item_printing_cost`    | Decimal(18,2)             | chi phí in                  |
| `item_vat_total`        | Decimal(18,2)             | VAT                         |
| `item_handle_fee`       | Decimal(20,2)             | handling fee                |
| `item_subtotal`         | Decimal(18,2)             | subtotal                    |
| `item_total`            | Decimal(18,2)             | tổng giá item ⭐             |
| `item_profit`           | Decimal(18,2)             | profit của item ⭐           |
| `item_base_price`       | Decimal(20,2)             |                             |
| `item_time`             | DateTime                  | thời điểm tạo item          |
| `item_status`           | Int16                     | trạng thái item             |
| `item_deleted`          | Int16                     | 1 = đã xóa                  |
| `item_quantity_printed` | Int16                     | số lượng đã in              |
| `item_quantity_error`   | Int16                     | số lượng lỗi                |
| `product_group`         | String                    | nhóm sản phẩm ⭐             |
| `product_type`          | String                    | loại sản phẩm ⭐             |
| `product`               | String                    | tên sản phẩm ⭐              |
| `product_sku`           | String                    | SKU ⭐                       |
| `item_name`             | Nullable(String)          | tên item (custom)           |
| `product_campaign_id`   | Int64                     | FK → nh_product_campaigns   |
| `item_size`             | Int64                     | size ID                     |
| `item_color`            | Int64                     | color ID                    |
| `item_material_id`      | Int64                     |                             |
| `item_print_type`       | Int64                     |                             |
| `item_variant_id`       | Int64                     |                             |
| `source_system`         | String                    | 'v1' / 'v3'                 |
| `_processed_at`         | DateTime64(3)             |                             |


---

#### `v__g5000_dtg_campaign_2025` 🔵

> View — Dữ liệu đặc biệt cho campaign G5000 DTG năm 2025


| Column            | Type                   | Ghi chú           |
| ----------------- | ---------------------- | ----------------- |
| `_order_id`       | String                 | order ID          |
| `_order_line_id`  | Int64                  | order line ID     |
| `_paid_at`        | Nullable(Date)         | ngày thanh toán   |
| `_seller_email`   | Nullable(String)       | email seller      |
| `_version`        | String                 | version hệ thống  |
| `_variant_size`   | Nullable(String)       | size variant      |
| `_units`          | Nullable(Int32)        | số units          |
| `_price`          | Nullable(Decimal(9,2)) | giá bán           |
| `_promo_price`    | Float64                | giá khuyến mãi    |
| `_cashback`       | Nullable(Decimal(9,2)) | cashback per unit |
| `_cashback_total` | Nullable(Decimal(9,2)) | tổng cashback     |


---

#### `v__order_production_sla_backlog_daily_clearance` 🔵

> View — Daily backlog clearance: backlog đầu ngày, cuối ngày, và số units được xử lý
> Aggregated by: product_group, product_type, priority_level, fulfill_location, order_type


| Column                | Type                   | Ghi chú                          |
| --------------------- | ---------------------- | -------------------------------- |
| `snapshot_date`       | Date                   | ngày snapshot ⭐                  |
| `product_group`       | LowCardinality(String) | nhóm sản phẩm ⭐                  |
| `product_type`        | LowCardinality(String) | loại sản phẩm ⭐                  |
| `priority_level`      | LowCardinality(String) | Critical / High / Medium / Low ⭐ |
| `fulfill_location`    | LowCardinality(String) | facility fulfill ⭐               |
| `order_type`          | LowCardinality(String) | loại order                       |
| `start_backlog_units` | UInt64                 | backlog units đầu ngày           |
| `end_backlog_units`   | UInt64                 | backlog units cuối ngày          |
| `processed`           | Int64                  | units đã xử lý trong ngày        |


---

#### `v__usps_fulfilled_to_delivered_days` 🔵

> View — USPS transit time: fulfilled → delivered (calendar days)


| Column                        | Type                 | Ghi chú                            |
| ----------------------------- | -------------------- | ---------------------------------- |
| `cus_id`                      | Int32                | seller ID                          |
| `ord_id`                      | Int32                | FK → nh_order                      |
| `tracking_number`             | Nullable(String)     |                                    |
| `fulfilled_time`              | DateTime             | thời điểm fulfill                  |
| `delivered_time`              | DateTime64(3, 'UTC') | thời điểm delivered                |
| `tracking_hash`               | UInt64               | hash của tracking number           |
| `fulfilled_to_delivered_days` | UInt32               | số ngày từ fulfilled → delivered ⭐ |


---

#### `v__usps_fulfilled_to_first_scan_days` 🔵

> View — USPS tracking lag: fulfilled → first carrier scan (**business days**)


| Column                         | Type                 | Ghi chú                                          |
| ------------------------------ | -------------------- | ------------------------------------------------ |
| `cus_id`                       | Int32                | seller ID                                        |
| `ord_id`                       | Int32                | FK → nh_order                                    |
| `tracking_number`              | Nullable(String)     |                                                  |
| `fulfilled_time`               | DateTime             | thời điểm fulfill                                |
| `first_scan_time`              | DateTime64(3, 'UTC') | thời điểm scan đầu tiên                          |
| `fulfilled_to_first_scan_days` | UInt32               | số **business** days từ fulfilled → first scan ⭐ |


---

#### `v__usps_paided_to_first_scan_days` 🔵

> View — USPS end-to-end: paid → first scan, tính cả business days
> Lưu ý: `ord_payment_datetime` là unix timestamp (Int32)


| Column                                  | Type                 | Ghi chú                                  |
| --------------------------------------- | -------------------- | ---------------------------------------- |
| `ord_id`                                | Int32                | FK → nh_order                            |
| `ord_payment_datetime`                  | Int32                | unix timestamp của payment               |
| `tracking_number`                       | Nullable(String)     |                                          |
| `payment_date_la`                       | Nullable(Date)       | ngày thanh toán (LA timezone)            |
| `first_scan_time_utc`                   | DateTime64(3, 'UTC') | thời điểm first scan UTC                 |
| `first_scan_date_la`                    | Date                 | ngày first scan (LA timezone)            |
| `calendar_days_diff`                    | Nullable(Int64)      | calendar days (paid → first scan)        |
| `business_days_exclude_payment`         | Int64                | business days, không tính ngày payment ⭐ |
| `business_days_inclusive`               | Int64                | business days, tính cả ngày payment      |
| `business_days_exclude_payment_clamped` | Int64                | như trên nhưng clamp về 0 nếu âm         |
| `business_days_inclusive_clamped`       | Int64                | như trên nhưng clamp về 0 nếu âm         |


---

#### `v__usps_shipping_day` 🔵

> View — USPS transit time tính theo business days: fulfilled → delivered


| Column                        | Type                 | Ghi chú                                     |
| ----------------------------- | -------------------- | ------------------------------------------- |
| `cus_id`                      | Int32                | seller ID                                   |
| `ord_id`                      | Int32                | FK → nh_order                               |
| `tracking_number`             | Nullable(String)     |                                             |
| `fulfilled_time`              | DateTime             | thời điểm fulfill                           |
| `delivered_time`              | DateTime64(3, 'UTC') | thời điểm delivered                         |
| `shipping_time_business_days` | UInt64               | số business days từ fulfilled → delivered ⭐ |


---

#### `v__usps_tracking_first_scan` 🔵

> View — First scan event per tracking number (deduplicated)


| Column            | Type                 | Ghi chú                   |
| ----------------- | -------------------- | ------------------------- |
| `ord_id`          | Int32                | FK → nh_order             |
| `tracking_number` | String               | tracking number ⭐         |
| `first_scan_time` | DateTime64(3, 'UTC') | thời điểm scan đầu tiên ⭐ |


---

#### `v_production_backlog_clearance_intraday` 🔵

> View — Intraday backlog snapshot: tổng hợp backlog tại thời điểm hiện tại (live)


| Column             | Type                   | Ghi chú                             |
| ------------------ | ---------------------- | ----------------------------------- |
| `product_group`    | LowCardinality(String) | nhóm sản phẩm ⭐                     |
| `product_type`     | LowCardinality(String) | loại sản phẩm ⭐                     |
| `fulfill_location` | LowCardinality(String) | facility fulfill ⭐                  |
| `backlog_units`    | UInt64                 | tổng units trong backlog hiện tại ⭐ |
| `remaining_units`  | UInt64                 | units còn lại chưa xử lý            |
| `processed_units`  | Int64                  | units đã xử lý                      |


---

## Internal Tables (không query trực tiếp)


| Table                                               | Description                                           |
| --------------------------------------------------- | ----------------------------------------------------- |
| `mv__fact_order_fulfillment_performance`            | MaterializedView → fact_order_fulfillment_performance |
| `mv__fact_order_fulfillment_performance_by_product` | MaterializedView → by_product variant                 |
| `mv__fact_production_order_sla_tracker`             | MaterializedView → sla_tracker                        |
| `mv__g5000_dtg_campaign_2025`                       | MaterializedView → DTG campaign view                  |


---

## Patterns thường dùng

```sql
-- Lấy order với status label
SELECT
    o.ord_id,
    o.ord_time,
    dictGet('gea__silver.dict_order_status', 'business_status_name', toUInt64(o.ord_status_custom)) AS status_name,
    dictGet('gea__silver.dict_order_status', 'status_group', toUInt64(o.ord_status_custom)) AS status_group
FROM geadb__bronze.nh_order FINAL o
WHERE o.ord_deleted = 0

-- Join fact_order_v1 với dim_time
SELECT
    t.year,
    t.month,
    count() AS orders,
    sum(f.order_total) AS revenue
FROM gea__silver.fact_order_v1 FINAL f
JOIN gea__silver.dim_time t ON f.date_id = t.date_key
GROUP BY t.year, t.month
ORDER BY t.year, t.month

-- Fulfillment SLA average
SELECT
    ordx_fulfill_locate,
    country_code,
    avg(first_scan_day) AS avg_first_scan_days,
    avg(shipping_day) AS avg_shipping_days
FROM gea__silver.fact_order_fulfillment_performance FINAL
WHERE paid_at_utc >= '2025-01-01'
GROUP BY ordx_fulfill_locate, country_code
```


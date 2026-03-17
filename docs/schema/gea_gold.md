# Schema: gea_gold

**Layer:** Gold (pre-computed metrics & views)
**Last updated:** 2026-03-13
**Tables:** 7

---

## `dim_order_method` 🔵

> Engine: SharedMergeTree | ORDER BY method_id

| Column | Type | Ghi chú |
|---|---|---|
| method_id | UInt8 | PK |
| method_name | String | |

---

## `nextapp_order_metrics` 🔵

> Engine: SharedMergeTree | PARTITION BY time_period | ORDER BY (metric_date, time_period)
> Rows: ~336 | Pre-computed daily/weekly/monthly metrics cho NextApp orders

| Column | Type | Ghi chú |
|---|---|---|
| metric_date | Date | |
| time_period | LowCardinality(String) | 'daily' / 'weekly' / 'monthly' |
| total_orders_pushed_to_oms | UInt32 | |
| successful_pushes | UInt32 | |
| failed_pushes | UInt32 | |
| push_success_rate_percent | Float32 | |
| pending_orders_over_2h | UInt32 | |
| total_orders_in_production | UInt32 | |
| total_orders_packed | UInt32 | |
| total_orders_fulfilled | UInt32 | |
| fulfillment_success_rate_percent | Float32 | |
| total_orders_with_tracking | UInt32 | |
| tracking_delivered | UInt32 | |
| tracking_failed | UInt32 | |
| tracking_success_rate_percent | Float32 | |
| tracking_sync_rate_percent | Float32 | |
| total_orders_via_webhook | UInt32 | |
| successful_webhook_pulls | UInt32 | |
| failed_webhook_pulls | UInt32 | |
| webhook_success_rate_percent | Float32 | |
| total_imported_orders | UInt32 | |
| total_import_with_label | UInt32 | |
| total_import_manual | UInt32 | |
| successful_imports | UInt32 | |
| failed_imports | UInt32 | |
| import_success_rate_percent | Float32 | |
| import_with_label_rate_percent | Float32 | |
| total_manual_orders | UInt32 | |
| total_api_orders | UInt32 | |
| total_pull_orders | UInt32 | |
| auto_approved_orders | UInt32 | |
| auto_approval_rate_percent | Float32 | |
| manual_creation_rate | Float32 | |
| import_creation_rate | Float32 | |
| webhook_creation_rate | Float32 | |
| api_creation_rate | Float32 | |
| pull_creation_rate | Float32 | |
| total_orders_manual | UInt32 | |
| total_orders_import | UInt32 | |
| total_orders_webhook | UInt32 | |
| total_orders_api | UInt32 | |
| total_orders_pull | UInt32 | |
| successful_payments | UInt32 | |
| auto_payment_success_rate_percent | Float32 | |
| successful_product_matches | UInt32 | |
| auto_match_success_rate_percent | Float32 | |
| total_orders | UInt32 | |
| total_draft_orders | UInt32 | |
| total_packages | UInt32 | |
| total_items | UInt64 | |
| total_revenue | Float64 | |
| calculated_at | DateTime | |

---

## `next_app_platform_distribution` ☁️

> Engine: DeltaLakeS3 (S3: gold/next_app/next_app_platform_distribution/)

| Column | Type | Ghi chú |
|---|---|---|
| metric_date | Nullable(DateTime64(6)) | |
| time_period | Nullable(String) | |
| order_platform | Nullable(String) | |
| order_count | Nullable(Int64) | |
| percentage | Nullable(Float64) | |
| draft_orders | Nullable(Int64) | |
| sale_orders | Nullable(Int64) | |
| calculated_at | Nullable(DateTime64(6)) | |

---

## `next_app_processing_time` ☁️

> Engine: DeltaLakeS3 (S3: gold/next_app/next_app_processing_time/)

| Column | Type | Ghi chú |
|---|---|---|
| metric_date | Nullable(DateTime64(6)) | |
| time_period | Nullable(String) | |
| avg_total_processing_hours | Nullable(Float64) | |
| min_total_processing_hours | Nullable(Int64) | |
| max_total_processing_hours | Nullable(Int64) | |
| avg_awaiting_production_hours | Nullable(Float64) | |
| avg_in_production_hours | Nullable(Float64) | |
| avg_packed_hours | Nullable(Float64) | |
| calculated_at | Nullable(DateTime64(6)) | |

---

## `next_app_user_activity` ☁️

> Engine: DeltaLakeS3 (S3: gold/next_app/next_app_user_activity/)

| Column | Type | Ghi chú |
|---|---|---|
| metric_date | Nullable(DateTime64(6)) | |
| time_period | Nullable(String) | |
| daily_active_users | Nullable(Int64) | |
| total_sessions | Nullable(Int64) | |
| avg_session_duration_minutes | Nullable(Float64) | |
| calculated_at | Nullable(DateTime64(6)) | |

---

## `order_shipping_zone` 👁️

> Engine: View — joins geadb__bronze.nh_order + nh_order_extra + nh_shipping_zones
> Filter: US orders (ord_cus_country = 231), origin từ HB1 (CA) hoặc TX1 (TX)

| Column | Type | Ghi chú |
|---|---|---|
| ord_id | Int32 | FK → nh_order |
| from_state | Nullable(String) | 'CA' hoặc 'TX' |
| to_state | String | destination state |
| zipcode_from | Nullable(String) | first 3 digits |
| zipcode_to | String | first 3 digits |
| shipping_zone | String | |

---

## `v_easypost_rate_usps` 👁️

> Engine: View — joins gea_silver.easypost_rate_usps_california + texas

| Column | Type | Ghi chú |
|---|---|---|
| carrier | String | |
| service | String | USPS service type |
| zone | Int64 | shipping zone number |
| weight | Int64 | weight in oz |
| rate | Float64 | CA rate |
| tx.rate | Float64 | TX rate |
| pct | Float64 | (CA/TX - 1) rate diff % |
| collected_at | DateTime64(9) | |
| display_weight | String | e.g. '1 oz', '1 lb' |

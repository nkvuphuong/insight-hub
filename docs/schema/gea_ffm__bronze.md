# Schema: gea_ffm__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 12 (excl. schema_migrations)

> Fulfillment service — quản lý đơn hàng fulfillment qua kho (WMS). Khác với seller orders (gea_seller__bronze), đây là đơn B2B/3PL.

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `ffm_product_variant` | ~1.4K | Variants sản phẩm FFM |
| `ffm_order` | 88 | Đơn FFM |
| `ffm_order_address` | 88 | Địa chỉ đơn FFM |
| `ffm_order_line_item` | 91 | Line items đơn FFM |
| `ffm_order_package` | 83 | Packages |
| `ffm_order_package_line` | 84 | Package lines |
| `ffm_order_package_tracking` | 83 | Tracking packages |
| `ffm_order_import_session_detail` | 99 | Chi tiết import session |
| `ffm_order_import_session` | 30 | Import sessions |
| `ffm_product_image` | 44 | Product images |
| `ffm_product_import_session` | 9 | Product import sessions |
| `ffm_seller_config` | 8 | Cấu hình seller FFM |
| `schema_migrations` | 21 | |

---

## `ffm_order` 🔵

> Engine: SharedMergeTree | Rows: 88
> Không phải ReplacingMergeTree. Đơn FFM (B2B fulfillment).

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `store_id` | String | |
| `store_name` | Nullable(String) | |
| `order_id` | Nullable(String) | UUID đơn |
| `order_date` | Nullable(DateTime64(6,'UTC')) | |
| `name` | Nullable(String) | Order name/ref |
| `platform` | Nullable(String) | |
| `reference_id` | Nullable(String) | |
| `import_id` | Nullable(String) | |
| `tracking_no` | Nullable(String) | |
| `label_url` | Nullable(String) | |
| `processing_status` | Nullable(String) | |
| `status` | Nullable(String) | |
| `order_total` | Nullable(Int64) | cents |
| `surcharge_fee` | Nullable(Int64) | |
| `shipping_fee` | Nullable(Int64) | |
| `handle_fee` | Nullable(Int64) | |
| `is_cancelled` | Nullable(Bool) | |
| `shipped_at` | Nullable(DateTime64(6,'UTC')) | |
| `warehouse_received_at` | Nullable(DateTime64(6,'UTC')) | |
| `ready_for_shipping_at` | Nullable(DateTime64(6,'UTC')) | |
| `completed_at` | Nullable(DateTime64(6,'UTC')) | |
| `tracking_carrier` | Nullable(String) | |
| `tracking_service` | Nullable(String) | |
| `tracking_url` | Nullable(String) | |
| `capture_status` | Nullable(String) | |
| `capture_error` | Nullable(String) | |
| `legacy_external_id` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |

---

## `ffm_order_address` 🔵

> Engine: SharedMergeTree | Rows: 88

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `type` | Nullable(String) | shipping / billing |
| `team_id` | String | |
| `order_id` | Nullable(String) | |
| `line1` | Nullable(String) | |
| `line2` | Nullable(String) | |
| `locality` | Nullable(String) | City |
| `admin_area` | Nullable(String) | State/Province |
| `region_code` | Nullable(String) | |
| `region` | Nullable(String) | |
| `country_code` | Nullable(String) | |
| `country` | Nullable(String) | |
| `postal_code` | Nullable(String) | |
| `first_name` | Nullable(String) | |
| `last_name` | Nullable(String) | |
| `phone_no` | Nullable(String) | |
| `email` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |

---

## `ffm_order_line_item` 🔵

> Engine: SharedMergeTree | Rows: 91

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | |
| `team_id` | String | |
| `line_number` | Nullable(Int64) | |
| `variant_id` | Nullable(String) | |
| `variant_sku` | Nullable(String) | |
| `variant_name` | Nullable(String) | |
| `match_status` | Nullable(String) | |
| `image_url` | Nullable(String) | |
| `quantity` | Nullable(Int64) | |
| `note` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |

---

## `ffm_order_package` 🔵

> Engine: SharedMergeTree | Rows: 83

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | |
| `team_id` | String | |
| `platform` | Nullable(String) | |
| `package_id` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `vendor_id` | Nullable(String) | |
| `outbound_code` | Nullable(String) | WMS outbound code |
| `inbound_plan_id` | Nullable(String) | |
| `tracking_no` | Nullable(String) | |
| `label_url` | Nullable(String) | |
| `tracking_carrier` | Nullable(String) | |
| `tracking_service` | Nullable(String) | |
| `tracking_status` | Nullable(String) | |
| `tracking_url` | Nullable(String) | |
| `status` | Nullable(String) | |
| `fulfillment_strategy` | Nullable(String) | |
| `is_label_attached` | Nullable(Bool) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |

---

## `ffm_order_package_tracking` 🔵

> Engine: SharedMergeTree | Rows: 83

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | |
| `package_id` | Nullable(String) | |
| `team_id` | String | |
| `request_id` | Nullable(String) | |
| `outbound_code` | Nullable(String) | |
| `status` | Nullable(String) | |
| `wms_status` | Nullable(String) | |
| `parcel_status` | Nullable(String) | |
| `tracking_no` | Nullable(String) | |
| `tracking_carrier` | Nullable(String) | |
| `tracking_service` | Nullable(String) | |
| `tracking_url` | Nullable(String) | |
| `type` | Nullable(String) | |
| `fulfillment_strategy` | Nullable(String) | |
| `is_label_attached` | Nullable(Bool) | |
| `need_relabel` | Nullable(Bool) | |
| `error` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |

---

## `ffm_product_variant` 🔵

> Engine: SharedMergeTree | Rows: ~1.4K

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `product_id` | Nullable(String) | |
| `variant_id` | Nullable(String) | |
| `import_id` | Nullable(String) | |
| `reference_id` | Nullable(String) | |
| `reference_sku` | Nullable(String) | |
| `sku` | Nullable(String) | |
| `name` | Nullable(String) | |
| `description` | Nullable(String) | |
| `weight` | Nullable(Decimal(38,18)) | |
| `width` | Nullable(Decimal(38,18)) | |
| `height` | Nullable(Decimal(38,18)) | |
| `length` | Nullable(Decimal(38,18)) | |
| `status` | Nullable(String) | |
| `wms_status` | Nullable(String) | |
| `hs_code` | Nullable(String) | |
| `option1/2/3/4/5` | Nullable(String) | |
| `is_warehouse_dimension_measured` | Nullable(Bool) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |

---

## `ffm_seller_config` 🔵

> Engine: SharedMergeTree | Rows: 8

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `default_store_id` | String | |
| `wms_client_id` | String | WMS client ID |
| `warehouse_code` | Nullable(String) | |
| `create_at` | DateTime64(6,'UTC') | |
| `update_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |

---

## Internal Tables (excluded)

Không có `__mv_to_latest` trong database này (dùng SharedMergeTree thay vì SharedReplacingMergeTree).

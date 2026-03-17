# Schema: gea_shipping__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 3 (excl. schema_migrations)

> Shipping label purchase service — mua label vận chuyển.

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `shp_label_purchase_request` | 29 | Yêu cầu mua label |
| `shp_label_purchase_request_detail` | 29 | Chi tiết yêu cầu mua label |
| `shp_label_purchase_address` | Empty | Địa chỉ cho label |
| `schema_migrations` | 9 | |

---

## `shp_label_purchase_request` 🔵

> Engine: SharedReplacingMergeTree | Rows: 29
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `request_id` | Nullable(String) | UUID |
| `reference_id` | Nullable(String) | Ref đến package |
| `client_id` | Nullable(String) | |
| `status` | Nullable(String) | pending / success / failed |
| `tracking_no` | Nullable(String) | |
| `label_url` | Nullable(String) | |
| `tracking_url` | Nullable(String) | |
| `tracking_carrier` | Nullable(String) | |
| `tracking_service` | Nullable(String) | |
| `tracking_status` | Nullable(String) | |
| `purchase_error` | Nullable(String) | |
| `quantity` | Nullable(Int64) | Số lượng labels |
| `note` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `shp_label_purchase_request_detail` 🔵

> Engine: SharedReplacingMergeTree | Rows: 29
> Dùng `FINAL` khi query để dedup. Chi tiết package dimensions & carrier.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `request_id` | Nullable(String) | FK -> shp_label_purchase_request |
| `request_carrier` | Nullable(String) | Carrier requested |
| `request_service` | Nullable(String) | Service type |
| `request_pickup_type` | Nullable(String) | |
| `customs_tax_id` | Nullable(String) | |
| `customs_duties_paid_by` | Nullable(String) | |
| `customs_invoice_number` | Nullable(String) | |
| `package_width` | Nullable(Decimal(38,18)) | cm |
| `package_height` | Nullable(Decimal(38,18)) | cm |
| `package_length` | Nullable(Decimal(38,18)) | cm |
| `package_weight` | Nullable(Decimal(38,18)) | kg |
| `package_value` | Nullable(Decimal(38,18)) | USD |
| `package_quantity` | Nullable(Int64) | |
| `package_hs_code` | Nullable(String) | |
| `package_description` | Nullable(String) | |
| `length_unit` | Nullable(String) | cm / in |
| `weight_unit` | Nullable(String) | kg / lb |
| `expectation_pickup_date` | Nullable(DateTime64(6,'UTC')) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `shp_label_purchase_address` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup. Địa chỉ sender/receiver cho label.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `request_id` | Nullable(String) | |
| `type` | Nullable(String) | sender / receiver |
| `line1` | Nullable(String) | |
| `line2` | Nullable(String) | |
| `locality` | Nullable(String) | City |
| `admin_area` | Nullable(String) | State |
| `region_code` | Nullable(String) | |
| `country_code` | Nullable(String) | |
| `country` | Nullable(String) | |
| `postal_code` | Nullable(String) | |
| `organization` | Nullable(String) | |
| `first_name` | Nullable(String) | |
| `last_name` | Nullable(String) | |
| `phone_no` | Nullable(String) | |
| `email` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## Internal Tables (excluded)

**MaterializedViews (`__mv_to_latest`):** `shp_label_purchase_request__mv_to_latest`, `shp_label_purchase_request_detail__mv_to_latest`, `shp_label_purchase_address__mv_to_latest`

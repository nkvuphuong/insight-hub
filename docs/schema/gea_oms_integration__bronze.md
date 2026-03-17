# Schema: gea_oms_integration__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 4 (excl. schema_migrations)

> OMS Integration service — đồng bộ dữ liệu từ OMS (Order Management System) cũ sang hệ thống mới. Migration data.

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `oms_migration_job` | ~121K | Migration jobs từ OMS cũ |
| `oms_order_sync_tracking` | ~77K | Tracking sync orders OMS |
| `oms_cancel_order_log` | Empty | Log cancel orders qua OMS |
| `oms_order_sync_log` | Empty | Log sync orders |
| `schema_migrations` | 9 | |

---

## `oms_migration_job` 🔵

> Engine: SharedMergeTree | Rows: ~121K
> Không phải ReplacingMergeTree. Jobs migrate data từ legacy OMS.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `request_id` | Int64 | |
| `cus_id` | Int32 | Legacy customer ID |
| `staff_id` | String | Staff xử lý |
| `data_type` | String | Loại data migrate |
| `status` | String | pending / running / done / failed |
| `range_from` | DateTime64(6,'UTC') | Khoảng thời gian migrate |
| `range_to` | DateTime64(6,'UTC') | |
| `order_id` | Int32 | Legacy order ID offset |
| `extract_job_count` | Int64 | |
| `load_job_count` | Int64 | |
| `completed_extract_job_count` | Int64 | |
| `total_extracted_count` | Int64 | |
| `completed_extracted_count` | Int64 | |
| `failed_extracted_count` | Int64 | |
| `converted_extracted_count` | Int64 | |
| `total_loaded_count` | Int64 | |
| `completed_loaded_count` | Int64 | |
| `failed_loaded_count` | Int64 | |
| `converted_loaded_count` | Int64 | |
| `metadata` | String | JSON |
| `error` | String | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |

---

## `oms_order_sync_tracking` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~77K
> Dùng `FINAL` khi query để dedup. Tracking mapping order_id (mới) ↔ oms_order_id (cũ).

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | String | ID đơn trong hệ thống mới |
| `oms_order_id` | String | ID đơn trong OMS cũ |
| `import_id` | Int64 | |
| `package_id` | String | |
| `child_order_ids` | Nullable(String) | JSON array |
| `last_order_sync` | Nullable(DateTime64(6,'UTC')) | |
| `status` | Nullable(String) | synced / failed |
| `is_migrated` | Nullable(Bool) | |
| `note` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `oms_cancel_order_log` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_ids` | Nullable(String) | JSON array |
| `payload` | Nullable(String) | Request payload |
| `response` | Nullable(String) | API response |
| `status_code` | Nullable(Int64) | HTTP status |
| `note` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `oms_order_sync_log` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | |
| `oms_order_id` | Nullable(String) | |
| `track_status` | Nullable(String) | |
| `status` | Nullable(String) | |
| `note` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## Internal Tables (excluded)

**MaterializedViews (`__mv_to_latest`):** `oms_cancel_order_log__mv_to_latest`, `oms_order_sync_log__mv_to_latest`, `oms_order_sync_tracking__mv_to_latest`

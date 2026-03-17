# Schema: gea_studio__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 8 (excl. schema_migrations)

> Studio service — quản lý media, gift messages, design exports.

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `stu_media` | ~2.7M | Media files (designs, images) |
| `stu_gift_message` | 540 | Gift message designs |
| `stu_gift_message_order` | 287 | Mapping gift message → order |
| `stu_gift_message_export` | Empty | Gift message exports |
| `stu_gift_message_template` | Empty | Gift message templates |
| `stu_barcode_export` | Empty | Barcode exports |
| `stu_design_printing_option_export` | Empty | Design exports |
| `stu_shipping_label_export` | Empty | Shipping label exports |
| `schema_migrations` | 24 | |

---

## `stu_media` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~2.7M
> Dùng `FINAL` khi query để dedup. Media library — tất cả files upload vào hệ thống.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `media_id` | String | UUID |
| `type` | Nullable(String) | image / video / pdf... |
| `path` | Nullable(String) | Storage path |
| `storage_id` | Nullable(String) | |
| `storage_path` | Nullable(String) | |
| `storage_source` | Nullable(String) | s3 / gcs... |
| `status` | Nullable(String) | |
| `size` | Nullable(Int64) | bytes |
| `alias` | Nullable(String) | |
| `original_name` | Nullable(String) | Tên file gốc |
| `name` | Nullable(String) | |
| `ext` | Nullable(String) | File extension |
| `content_type` | Nullable(String) | MIME type |
| `metadata` | Nullable(String) | JSON |
| `imported_from` | Nullable(String) | |
| `usage` | Nullable(String) | design / mockup / avatar... |
| `owned_by` | Nullable(String) | user_id |
| `owned_by_team` | Nullable(String) | team_id |
| `legacy_id` | Nullable(Int64) | |
| `deleted_at` | Nullable(DateTime64(6)) | |
| `deleted_by` | Nullable(String) | |
| `created_at` | Nullable(DateTime64(6,'UTC')) | |
| `updated_at` | Nullable(DateTime64(6,'UTC')) | |
| `ts_token` | Nullable(String) | Full-text search token |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `stu_gift_message` 🔵

> Engine: SharedReplacingMergeTree | Rows: 540
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `gift_message_id` | String | UUID |
| `team_id` | String | |
| `template_id` | Nullable(String) | |
| `name` | Nullable(String) | |
| `type` | Nullable(String) | |
| `background_color` | Nullable(String) | |
| `text_color` | Nullable(String) | |
| `text_font` | Nullable(String) | |
| `text_size` | Nullable(String) | |
| `content` | Nullable(String) | Message content |
| `status` | Nullable(String) | |
| `design_file_path` | Nullable(String) | |
| `design_file_id` | Nullable(String) | |
| `design_file_name` | Nullable(String) | |
| `storage_id` | Nullable(String) | |
| `legacy_id` | Nullable(Int64) | |
| `deleted_at` | Nullable(DateTime64(6)) | |
| `deleted_by` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `stu_gift_message_order` 🔵

> Engine: SharedReplacingMergeTree | Rows: 287
> Dùng `FINAL` khi query để dedup. Mapping gift message với order.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `gift_message_id` | Nullable(String) | |
| `gift_message_export_id` | Nullable(String) | |
| `order_id` | Nullable(String) | |
| `reference_id` | Nullable(Int64) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `stu_gift_message_export` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup. Exported gift message renders.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `gift_message_export_id` | String | UUID |
| `team_id` | String | |
| `gift_message_id` | String | |
| `template_id` | Nullable(String) | |
| `params_hash` | Nullable(String) | Hash để cache |
| `content` | Nullable(String) | |
| `media_id` | Nullable(String) | |
| `media_path` | Nullable(String) | |
| `design_file_id` | Nullable(String) | |
| `origin_storage_id` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `stu_gift_message_template` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `template_id` | String | UUID |
| `template_name` | Nullable(String) | |
| `dimension` | Nullable(String) | |
| `paper` | Nullable(String) | |
| `border` | Nullable(String) | |
| `character` | Nullable(String) | |
| `price` | Nullable(Int64) | cents |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `stu_barcode_export`, `stu_design_printing_option_export`, `stu_shipping_label_export` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty

**Columns chung:** `id`, `design_file_path`, `order_id`, `team_id`, `media_id`, `media_path`, `origin_storage_id`, `created_at`, `updated_at`, `_processed_at`, `_action`, `_timestamp`

- `stu_barcode_export`: thêm `line_item_id`
- `stu_design_printing_option_export`: thêm `line_item_id`

---

## Internal Tables (excluded)

**MaterializedViews (`__mv_to_latest`):** 8 views

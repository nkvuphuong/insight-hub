# Schema: gea_store__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 25 (excl. schema_migrations)

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `sc_store` | ~40.3K | Stores của sellers |
| `sc_order_pull_session` | ~450K | Sessions pull đơn từ platform |
| `sc_integrated_store` | ~4.3K | Kết nối store với marketplace |
| `sc_webhook_record` | ~5.5K | Webhook records |
| `sc_webhook_tiktok_shop` | ~3K | TikTok webhooks |
| `sc_webhook_shopify` | ~1.3K | Shopify webhooks |
| `sc_webhook_shopbase` | 615 | ShopBase webhooks |
| `sc_store_gift_message` | 755 | Gift message config theo store |
| `gm_marketplace` | 15 | Danh sách marketplaces |
| `gm_integrated_app` | 10 | Integrated apps |
| `sc_order_pull_batch_*` | Empty | Batch pull per platform |
| `sc_listed_product` | Empty | Listed products |
| `sc_listed_product_image` | Empty | Ảnh listed products |
| `sc_listed_product_publish_session` | Empty | Publish sessions |
| `sc_listed_product_variant` | Empty | Listed product variants |
| `sc_store_member` | Empty | Store members |
| `sc_tracking_sync_session` | Empty | Tracking sync sessions |
| `sc_webhook_woocommerce` | Empty | WooCommerce webhooks |
| `schema_migrations` | 75 | |

---

## `sc_store` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~40.3K
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `store_id` | String | UUID |
| `team_id` | String | FK -> iam_team |
| `platform` | Nullable(String) | shopify / etsy / amazon / manual... |
| `name` | Nullable(String) | Tên store |
| `status` | Nullable(Int16) | 1=active |
| `is_default` | Nullable(Bool) | |
| `is_deleted` | Nullable(Bool) | |
| `should_auto_sync_orders` | Nullable(Bool) | |
| `should_notify_shipment` | Nullable(Bool) | |
| `should_pull_only_paid_order` | Nullable(Bool) | |
| `return_address_id` | Nullable(String) | |
| `app_code` | Nullable(String) | |
| `legacy_id` | Nullable(Int64) | |
| `created_by` | Nullable(String) | |
| `created_at` | Nullable(DateTime64(6,'UTC')) | |
| `updated_at` | Nullable(DateTime64(6,'UTC')) | |
| `updated_by` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_integrated_store` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~4.3K
> Dùng `FINAL` khi query để dedup. Kết nối OAuth store với marketplace app.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `store_id` | String | FK -> sc_store.store_id |
| `platform` | Nullable(String) | |
| `app_id` | Nullable(String) | |
| `ref_id` | Nullable(String) | ID trên platform |
| `status` | Nullable(Int16) | |
| `integrated_data` | Nullable(String) | JSON (access tokens...) |
| `last_order_auto_pulled_at` | Nullable(DateTime64(6,'UTC')) | |
| `updated_at` | DateTime64(6,'UTC') | |
| `updated_by` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_pull_session` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~450K
> Dùng `FINAL` khi query để dedup. Lịch sử mỗi lần pull đơn từ marketplace.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `pull_id` | String | UUID |
| `store_id` | String | |
| `team_id` | String | |
| `platform` | Nullable(String) | |
| `app_id` | Nullable(String) | |
| `status` | Nullable(String) | pending / success / failed |
| `from` | Nullable(DateTime64(6,'UTC')) | Khoảng thời gian pull |
| `to` | Nullable(DateTime64(6,'UTC')) | |
| `batch_size` | Nullable(Int64) | |
| `is_auto` | Bool | |
| `existed_platform_ref_count` | Nullable(Int64) | Đơn đã tồn tại |
| `success_platform_ref_count` | Nullable(Int64) | |
| `failure_platform_ref_count` | Nullable(Int64) | |
| `failed_reason` | Nullable(String) | |
| `cause` | Nullable(String) | |
| `created_by` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `gm_marketplace` 🔵

> Engine: SharedReplacingMergeTree | Rows: 15
> Dùng `FINAL` khi query để dedup. Danh mục marketplaces được hỗ trợ.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `platform` | String | shopify / etsy / amazon / tiktok_shop... |
| `name` | Nullable(String) | |
| `status` | Nullable(Int16) | |
| `display_order` | Nullable(Int64) | |
| `is_store_connection_enabled` | Nullable(Bool) | |
| `is_order_pulling_enabled` | Nullable(Bool) | |
| `is_product_pushing_enabled` | Nullable(Bool) | |
| `is_order_importing_enabled` | Nullable(Bool) | |
| `is_order_api_enabled` | Nullable(Bool) | |
| `is_item_barcode_submitting_enabled` | Nullable(Bool) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_webhook_record` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~5.5K
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `store_id` | String | |
| `team_id` | String | |
| `app_id` | Nullable(String) | |
| `app_code` | Nullable(String) | |
| `request_id` | Nullable(String) | |
| `platform` | Nullable(String) | |
| `status` | Nullable(String) | |
| `failed_reason` | Nullable(String) | |
| `existed_platform_ref_count` | Nullable(Int32) | |
| `success_platform_ref_count` | Nullable(Int32) | |
| `failure_platform_ref_count` | Nullable(Int32) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_store_gift_message` 🔵

> Engine: SharedReplacingMergeTree | Rows: 755
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `store_id` | String | |
| `gift_message_id` | Nullable(String) | |
| `status` | Nullable(String) | |
| `is_active` | Nullable(Bool) | |
| `applied_from` | Nullable(DateTime64(6,'UTC')) | |
| `applied_to` | Nullable(DateTime64(6,'UTC')) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_pull_batch_*` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty (tất cả)
> Dùng `FINAL` khi query để dedup. Batch data per platform (amazon, ebay, etsy, shopify, shopbase, tiktok_shop, woocommerce, order_desk).

**Columns chung:** `id`, `pull_id`, `platform`, `team_id`, `store_id`, `app_id`, `orders`, `platform_orders`, `anchor`, `status`, `limit`, `count`, `created_at`, `updated_at`, `_processed_at`, `_action`, `_timestamp`

---

## `sc_listed_product` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `publish_id` | Nullable(String) | |
| `team_id` | String | |
| `store_id` | String | |
| `platform` | Nullable(String) | |
| `product_id` | Nullable(String) | |
| `product_ref` | Nullable(String) | ID trên platform |
| `seller_product_id` | Nullable(String) | |
| `gm_product_id` | Nullable(String) | |
| `name` | Nullable(String) | |
| `status` | Nullable(String) | |
| `type` | Nullable(String) | |
| `group_id` | Nullable(String) | |
| `published_at` | Nullable(DateTime64(6,'UTC')) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## Internal Tables (excluded)

**MaterializedViews (`__mv_to_latest`):** 25 views

# Schema: gea_notification__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 8 (excl. schema_migrations)

> Notification service — email, push notifications, inbox messages.

> **Lưu ý:** Tất cả tables đều Empty (0 rows). Data notifications hiện không được CDC vào ClickHouse.

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `noti_email` | Empty | Email sent log |
| `noti_email_subscription` | Empty | Email subscriptions |
| `noti_inbox` | Empty | In-app inbox messages |
| `noti_user_inbox` | Empty | User inbox read status |
| `noti_push` | Empty | Push notification campaigns |
| `noti_push_token` | Empty | Device push tokens |
| `noti_user_push` | Empty | User push delivery |
| `gm_email_template` | Empty | Email templates |
| `schema_migrations` | 24 | |

---

## `noti_email` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `sender` | Nullable(String) | |
| `recipients` | Nullable(String) | JSON array |
| `cc` | Nullable(String) | |
| `bcc` | Nullable(String) | |
| `subject` | Nullable(String) | |
| `body` | Nullable(String) | |
| `response_message_id` | Nullable(String) | |
| `ref_id` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `noti_inbox` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `inbox_id` | Nullable(Int64) | |
| `ref_id` | Nullable(String) | |
| `team_id` | String | |
| `user_id` | Nullable(String) | |
| `app_code` | Nullable(String) | |
| `title` | Nullable(String) | |
| `summary` | Nullable(String) | |
| `body` | Nullable(String) | |
| `image_url` | Nullable(String) | |
| `deep_link` | Nullable(String) | |
| `topic` | Nullable(String) | |
| `type` | Nullable(String) | |
| `scheme` | Nullable(String) | |
| `scheme_id` | Nullable(String) | |
| `strategy` | Nullable(String) | |
| `mode` | Nullable(String) | |
| `is_opened` | Nullable(Bool) | |
| `status` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `noti_push` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup. Push notification campaigns.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `app_code` | Nullable(String) | |
| `title` | Nullable(String) | |
| `body` | Nullable(String) | |
| `topic` | Nullable(String) | |
| `type` | Nullable(String) | |
| `os` | Nullable(String) | ios / android |
| `strategy` | Nullable(String) | |
| `mode` | Nullable(String) | |
| `status` | Nullable(String) | |
| `send_time` | Nullable(String) | |
| `created_by` | Nullable(String) | |
| `reviewed_by` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `noti_push_token` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Device push tokens.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `user_id` | Nullable(String) | |
| `app_code` | Nullable(String) | |
| `token` | Nullable(String) | FCM / APNS token |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `noti_email_subscription` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `email` | Nullable(String) | |
| `topic` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `gm_email_template` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `type` | Nullable(String) | |
| `content` | Nullable(String) | HTML template |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## Internal Tables (excluded)

**MaterializedViews (`__mv_to_latest`):** 8 views

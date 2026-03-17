# Schema: gea_integration__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 2 (excl. schema_migrations)

> API integration service — quản lý OAuth credentials và webhooks cho third-party integrations.

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `integr_webhook` | ~5.2K | Webhook registrations |
| `integr_credentials` | 579 | OAuth API credentials |
| `schema_migrations` | 6 | |

---

## `integr_credentials` 🔵

> Engine: SharedReplacingMergeTree | Rows: 579
> Dùng `FINAL` khi query để dedup. OAuth credentials của sellers.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `api_version` | Nullable(String) | |
| `client_key` | String | API key |
| `client_secret` | Nullable(String) | API secret (sensitive) |
| `scope` | Array(String) | Permissions granted |
| `scope_ts_token` | Nullable(String) | |
| `ts_token` | Nullable(String) | |
| `is_default` | Nullable(Bool) | |
| `created_at` | DateTime64(6,'UTC') | |
| `expired_at` | Nullable(DateTime64(6,'UTC')) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `integr_webhook` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~5.2K
> Dùng `FINAL` khi query để dedup. Webhook subscriptions.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `webhook_id` | String | UUID |
| `team_id` | String | |
| `store_id` | String | |
| `credential_client_key` | Nullable(String) | |
| `name` | Nullable(String) | |
| `topic` | Nullable(String) | Event topic subscribed |
| `status` | Nullable(String) | active / inactive |
| `delivery_url` | String | Webhook endpoint URL |
| `version` | Nullable(String) | API version |
| `level` | Nullable(String) | team / store |
| `legacy_id` | Nullable(Int64) | |
| `created_by` | String | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## Internal Tables (excluded)

**MaterializedViews (`__mv_to_latest`):** `integr_credentials__mv_to_latest`, `integr_webhook__mv_to_latest`

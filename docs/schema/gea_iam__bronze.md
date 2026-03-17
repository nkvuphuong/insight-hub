# Schema: gea_iam__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 21 (excl. schema_migrations)

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `iam_user_session` | ~164K | Sessions đăng nhập user |
| `iam_team_role` | ~68.7K | Roles theo team |
| `iam_team` | ~34.2K | Teams (sellers) |
| `iam_user` | ~17.9K | Users |
| `iam_team_store_member` | ~1.6K | Store members |
| `iam_team_role_permission` | ~1K | Phân quyền role |
| `iam_user_register` | ~1.3K | Đăng ký user |
| `iam_staff_session` | ~1.3K | Sessions staff |
| `iam_staff` | 40 | Staff accounts |
| `iam_team_member` | 374 | Members trong team |
| `iam_staff_role_assign` | 1 | Gán role cho staff |
| `iam_app_access` | Empty | App access |
| `iam_staff_policy` | Empty | Casbin policy staff |
| `iam_staff_role` | Empty | Roles staff |
| `iam_staff_role_permission` | Empty | Phân quyền staff role |
| `iam_team_member_invitation` | Empty | Lời mời tham gia team |
| `iam_user_policy` | Empty | Casbin policy user |
| `iam_user_recover` | Empty | Password recovery |
| `iam_user_verification` | Empty | Email verification |
| `gm_user_permission` | Empty | Permission definitions |
| `gm_user_permission_group` | Empty | Permission groups |
| `schema_migrations` | 63 | Migration history |

---

## `iam_user` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~17.9K
> Dùng `FINAL` khi query để dedup. User accounts của sellers.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `user_id` | String | UUID |
| `status` | Nullable(Int16) | |
| `gm_email` | Nullable(String) | Email đăng nhập Gearment |
| `fb_email` | Nullable(String) | |
| `fb_id` | Nullable(String) | |
| `gg_email` | Nullable(String) | |
| `gg_id` | Nullable(String) | |
| `user_name` | Nullable(String) | |
| `first_name` | Nullable(String) | |
| `last_name` | Nullable(String) | |
| `full_name` | Nullable(String) | |
| `avatar_url` | Nullable(String) | |
| `phone` | Nullable(String) | |
| `country` | Nullable(String) | |
| `default_team_id` | Nullable(String) | Team mặc định |
| `default_ffm_team_id` | Nullable(String) | |
| `legacy_id` | Nullable(Int64) | Legacy system ID |
| `legacy_code` | Nullable(String) | |
| `has_seen_migration_welcome` | Bool | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `iam_team` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~34.2K
> Dùng `FINAL` khi query để dedup. Teams = seller accounts.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | UUID — key chính trong toàn hệ thống |
| `app_code` | Nullable(String) | |
| `name` | Nullable(String) | Tên team/shop |
| `description` | Nullable(String) | |
| `owner_id` | Nullable(String) | FK -> iam_user.user_id |
| `status` | Nullable(Int16) | 1=active |
| `default_role_id` | Nullable(String) | |
| `avatar_url` | Nullable(String) | |
| `member_count` | Nullable(Int64) | |
| `tier_id` | Nullable(String) | Tier/level của team |
| `preferences` | Nullable(String) | JSON |
| `data` | Nullable(String) | JSON extra |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `iam_team_member` 🔵

> Engine: SharedReplacingMergeTree | Rows: 374
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `team_id` | String | |
| `user_id` | String | FK -> iam_user.user_id |
| `app_code` | Nullable(String) | |
| `role_id` | Nullable(String) | FK -> iam_team_role.role_id |
| `status` | Nullable(Int16) | |
| `created_by` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `iam_team_role` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~68.7K
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `role_id` | String | UUID |
| `app_code` | Nullable(String) | |
| `name` | Nullable(String) | |
| `description` | Nullable(String) | |
| `is_admin` | Nullable(Bool) | |
| `is_default` | Nullable(Bool) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `iam_team_role_permission` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~1K
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `team_id` | String | |
| `role_id` | String | |
| `permission_code` | String | |
| `created_by` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `iam_team_store_member` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~1.6K
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `user_id` | String | |
| `team_id` | String | |
| `store_id` | String | |
| `app_code` | Nullable(String) | |
| `created_by` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `iam_user_session` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~164K
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `session_id` | String | UUID |
| `user_id` | Nullable(String) | FK -> iam_user.user_id |
| `code` | Nullable(String) | |
| `access_id` | Nullable(String) | |
| `status` | Nullable(Int16) | |
| `type` | Nullable(String) | |
| `user_agent` | Nullable(String) | |
| `ip_address` | Nullable(String) | |
| `data` | Nullable(String) | JSON |
| `created_at` | DateTime64(6,'UTC') | |
| `expired_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `iam_staff` 🔵

> Engine: SharedReplacingMergeTree | Rows: 40
> Dùng `FINAL` khi query để dedup. Staff accounts Gearment.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `staff_id` | String | UUID |
| `email` | Nullable(String) | |
| `username` | String | |
| `full_name` | Nullable(String) | |
| `status` | Int16 | |
| `last_logged_in_at` | Nullable(DateTime64(6,'UTC')) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `iam_user_register` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~1.3K
> Dùng `FINAL` khi query để dedup. Pending registrations.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `email` | Nullable(String) | |
| `first_name` | Nullable(String) | |
| `last_name` | Nullable(String) | |
| `status` | Nullable(Int16) | |
| `verification_code` | Nullable(String) | |
| `expired_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `gm_user_permission` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Permission definitions toàn hệ thống.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `app_code` | Nullable(String) | |
| `group_code` | Nullable(String) | |
| `code` | String | Permission code |
| `name` | Nullable(String) | |
| `definitions` | Nullable(String) | JSON |
| `display_order` | Nullable(Int64) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## Internal Tables (excluded)

**MaterializedViews (`__mv_to_latest`):** 21 views — mỗi bảng chính có 1 MV tương ứng.

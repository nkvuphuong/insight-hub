# Schema: gea_finance__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 20 (excl. schema_migrations)

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `fin_team_transaction_detail` | ~737K | Chi tiết transaction |
| `fin_checkout_request_detail` | ~692K | Chi tiết checkout request |
| `fin_team_transaction` | ~289K | Transactions của team |
| `fin_wallet_transaction` | ~253K | Giao dịch wallet |
| `fin_checkout_request` | ~197K | Checkout requests |
| `fin_team_invoice` | ~70K | Hóa đơn team |
| `fin_team_invoice_detail` | ~92K | Chi tiết hóa đơn |
| `fin_wallet` | ~34K | Wallet của team |
| `fin_deposit_request` | ~21.7K | Yêu cầu nạp tiền |
| `fin_deposit_request_attachment` | ~11.2K | File đính kèm deposit |
| `fin_refund_request` | ~7.3K | Yêu cầu hoàn tiền |
| `fin_refund_request_detail` | ~7.3K | Chi tiết hoàn tiền |
| `fin_reject_reason` | 37 | Lý do từ chối |
| `fin_reject_reason_category` | 8 | Danh mục lý do từ chối |
| `fin_deposit_request_reject_reason` | 17 | Lý do từ chối deposit |
| `fin_payment_method` | 7 | Phương thức thanh toán |
| `fin_invoice_information` | Empty | Thông tin hóa đơn |
| `fin_linked_payment_method` | Empty | Phương thức thanh toán liên kết |
| `fin_payment_legal_info` | Empty | Thông tin pháp lý |
| `fin_staff_transaction_export_session` | Empty | Export session staff |
| `schema_migrations` | 60 | Migration history |

---

## `fin_team_transaction` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~289K
> Dùng `FINAL` khi query để dedup. Transactions tài chính của team.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `txn_id` | String | Transaction ID |
| `type` | Nullable(String) | deposit / checkout / refund... |
| `ext_txn_id` | Nullable(String) | External transaction ID |
| `ext_date` | Nullable(DateTime64(6,'UTC')) | |
| `ext_ref` | Nullable(String) | |
| `ext_type` | Nullable(String) | |
| `ext_platform` | Nullable(String) | paypal / payoneer / pingpong... |
| `method_code` | Nullable(String) | |
| `invoice_no` | Nullable(String) | |
| `refund_ref` | Nullable(String) | |
| `amount` | Nullable(Int64) | cents |
| `note` | Nullable(String) | |
| `statement_ref` | Nullable(String) | |
| `payment_type` | Nullable(String) | |
| `checkout_type` | Nullable(String) | |
| `txn_refs` | Array(String) | |
| `legacy_id` | Nullable(Int64) | |
| `is_migrated` | Bool | |
| `completed_at` | Nullable(DateTime64(6,'UTC')) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_team_transaction_detail` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~737K
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `txn_id` | String | FK -> fin_team_transaction.txn_id |
| `team_transaction_id` | Nullable(Int64) | |
| `txn_ref` | Nullable(String) | |
| `txn_date` | Nullable(DateTime64(6,'UTC')) | |
| `amount` | Nullable(Int64) | cents |
| `note` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_wallet` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~34K
> Dùng `FINAL` khi query để dedup. Số dư ví của team.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `balance` | Int64 | Số dư hiện tại (cents) |
| `status` | Int16 | |
| `version` | String | Optimistic locking |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_wallet_transaction` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~253K
> Dùng `FINAL` khi query để dedup. Lịch sử giao dịch ví.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `txn_id` | String | |
| `txn_ref` | Nullable(String) | |
| `txn_date` | Nullable(DateTime64(6,'UTC')) | |
| `ext_txn_id` | Nullable(String) | |
| `ext_platform` | Nullable(String) | |
| `method_code` | Nullable(String) | |
| `type` | String | credit / debit |
| `amount` | Int64 | cents |
| `before_balance` | Int64 | Số dư trước giao dịch |
| `after_balance` | Int64 | Số dư sau giao dịch |
| `note` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_checkout_request` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~197K
> Dùng `FINAL` khi query để dedup. Yêu cầu thanh toán đơn hàng.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `linked_payment_method_id` | String | |
| `method_code` | Nullable(String) | |
| `amount` | Nullable(Int64) | cents |
| `status` | String | |
| `type` | Nullable(String) | |
| `order_ids` | Array(String) | Các đơn hàng trong request |
| `txn_ids` | Array(String) | |
| `legacy_id` | Nullable(Int64) | |
| `expired_at` | DateTime64(6,'UTC') | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_checkout_request_detail` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~692K
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `checkout_request_id` | Nullable(Int64) | |
| `order_id` | Nullable(String) | |
| `order_date` | DateTime64(6,'UTC') | |
| `txn_ref` | Nullable(String) | |
| `txn_id` | Nullable(String) | |
| `ext_txn_id` | Nullable(String) | |
| `ext_platform` | Nullable(String) | |
| `amount` | Nullable(Int64) | cents |
| `status` | String | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_deposit_request` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~21.7K
> Dùng `FINAL` khi query để dedup. Yêu cầu nạp tiền vào ví.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `txn_id` | Nullable(String) | |
| `txn_ref` | Nullable(String) | |
| `method_code` | String | Phương thức thanh toán |
| `ext_txn_id` | Nullable(String) | |
| `ext_platform` | Nullable(String) | |
| `type` | String | |
| `amount` | Int64 | cents |
| `status` | String | pending / approved / rejected |
| `notes` | Nullable(String) | |
| `by_user` | String | User thực hiện |
| `by_staff` | Nullable(String) | Staff xử lý |
| `resolve_by` | Nullable(String) | |
| `is_auto_approve` | Bool | |
| `is_auto_verified` | Bool | |
| `verified_by` | Nullable(String) | |
| `verified_at` | Nullable(DateTime64(6,'UTC')) | |
| `requested_at` | DateTime64(6,'UTC') | |
| `resolved_at` | Nullable(DateTime64(6,'UTC')) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_refund_request` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~7.3K
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `refund_request_id` | String | UUID |
| `team_id` | String | |
| `order_id` | Nullable(String) | |
| `txn_id` | Nullable(String) | |
| `amount` | Nullable(Int64) | cents |
| `status` | String | |
| `method_code` | Nullable(String) | |
| `is_auto_refund` | Bool | |
| `order_refund_ref` | Nullable(String) | |
| `reference_id` | Nullable(String) | |
| `order_date` | Nullable(DateTime64(6,'UTC')) | |
| `notes` | Nullable(String) | |
| `created_by` | Nullable(String) | |
| `completed_at` | Nullable(DateTime64(6,'UTC')) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_refund_request_detail` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~7.3K
> Dùng `FINAL` khi query để dedup. Chi tiết breakdown refund.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `refund_request_id` | Nullable(String) | |
| `order_date` | DateTime64(6,'UTC') | |
| `amount` | Nullable(Int64) | cents total |
| `subtotal` | Nullable(Int64) | |
| `shipping_fee` | Nullable(Int64) | |
| `handle_fee` | Nullable(Int64) | |
| `gift_message_fee` | Nullable(Int64) | |
| `rush_fee` | Nullable(Int64) | |
| `tax_fee` | Nullable(Int64) | |
| `extra_fee` | Nullable(Int64) | |
| `surcharge_fee` | Nullable(Int64) | |
| `printing_fee` | Nullable(Int64) | |
| `type` | String | |
| `status` | String | |
| `method_code` | Nullable(String) | |
| `quantity` | Nullable(Int64) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_team_invoice` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~70K
> Dùng `FINAL` khi query để dedup.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `invoice_id` | String | UUID |
| `transaction_id` | String | |
| `transaction_code` | Nullable(String) | |
| `subtotal` | Nullable(Int64) | cents |
| `shipping_fee` | Nullable(Int64) | |
| `handle_fee` | Nullable(Int64) | |
| `gift_message_fee` | Nullable(Int64) | |
| `rush_fee` | Nullable(Int64) | |
| `surcharge_fee` | Nullable(Int64) | |
| `printing_fee` | Nullable(Int64) | |
| `tax` | Nullable(Int64) | |
| `total` | Nullable(Int64) | |
| `invoice_information` | Nullable(String) | JSON |
| `created_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_team_invoice_detail` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~92K
> Dùng `FINAL` khi query để dedup. Chi tiết từng đơn trong invoice.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `invoice_id` | String | FK -> fin_team_invoice.invoice_id |
| `order_id` | String | |
| `order_date` | Nullable(DateTime64(6,'UTC')) | |
| `variant_name` | Nullable(String) | |
| `quantity` | Nullable(Int64) | |
| `shipping_service` | Nullable(String) | |
| `tracking_number` | Nullable(String) | |
| `line_total` | Nullable(Int64) | cents |
| `subtotal` | Nullable(Int64) | |
| `shipping_fee` | Nullable(Int64) | |
| `handle_fee` | Nullable(Int64) | |
| `gift_message_fee` | Nullable(Int64) | |
| `rush_fee` | Nullable(Int64) | |
| `extra_fee` | Nullable(Int64) | |
| `surcharge_fee` | Nullable(Int64) | |
| `printing_fee` | Nullable(Int64) | |
| `tax` | Nullable(Int64) | |
| `reference_id` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `fin_payment_method` 🔵

> Engine: SharedReplacingMergeTree | Rows: 7
> Dùng `FINAL` khi query để dedup. Danh mục phương thức thanh toán.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | String | paypal / payoneer / pingpong... |
| `name` | String | |
| `status` | Int16 | |
| `is_deposit_allowed` | Bool | |
| `is_instant_deposit_allowed` | Bool | |
| `is_memo_deposit_allowed` | Bool | |
| `ext_type` | String | |
| `ext_platform` | String | |
| `display_order` | Int64 | |
| `is_auto_approve_deposit_allowed` | Nullable(Bool) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## Internal Tables (excluded)

**MaterializedViews (`__mv_to_latest`):** 20 views — mỗi bảng chính có 1 MV tương ứng.

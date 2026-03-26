# Schema: gea_seller__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 86 (87 total incl. schema_migrations)

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `sc_order` | ~949K | Đơn hàng seller |
| `sc_order_line_item` | ~997K | Line items của đơn hàng |
| `sc_fulfillment_package_line` | ~999K | Lines trong fulfillment package |
| `sc_fulfillment_package` | ~820K | Fulfillment packages |
| `sc_fulfillment_order` | ~817K | Fulfillment orders |
| `sc_order_fee` | ~710K | Các loại phí đơn hàng |
| `sc_fulfillment_order_line` | ~664K | Lines của fulfillment order |
| `sc_order_address` | ~605K | Địa chỉ đơn hàng |
| `sc_order_shipment` | ~529K | Thông tin vận chuyển |
| `sc_order_draft` | ~110K | Draft orders |
| `sc_order_draft_line_item` | ~135K | Line items của draft orders |
| `sc_order_payment` | ~337K | Thông tin thanh toán |
| `sc_order_draft_address` | ~58K | Địa chỉ draft orders |
| `sc_order_refund` | ~7K | Refund đơn hàng |
| `sc_order_cancel_detail` | ~1.3K | Chi tiết hủy đơn |
| `sc_order_cancel_reason` | 15 | Lý do hủy đơn |
| `sc_order_gift_message` | ~1.3K | Gift messages |
| `gm_team_price_tier` | ~34K | Price tiers theo team |
| `gm_product_shipping_fee` | ~15K | Phí vận chuyển sản phẩm |
| `gm_product_variant` | ~9.9K | Variants sản phẩm Gearment |
| `gm_product_attribute` | ~3.4K | Thuộc tính sản phẩm |
| `gm_product_option` | ~2.9K | Options sản phẩm |
| `gm_product_price` | ~4K | Giá sản phẩm |
| `gm_product_print_location` | ~2.5K | Vị trí in |
| `gm_product_legacy_option` | ~1.3K | Legacy options |
| `gm_product_category` | 87 | Danh mục sản phẩm |
| `gm_product_category_joint` | 115 | Joint danh mục |
| `gm_country_policy` | 249 | Chính sách theo quốc gia |
| `gm_product_type` | 42 | Loại sản phẩm |
| `gm_rush_product_group_variant` | 54 | Rush product variants |
| `gm_product_print_type` | 52 | Loại in |
| `gm_product_material` | 11 | Vật liệu |
| `gm_product_shipping_service` | 4 | Dịch vụ vận chuyển |
| `gm_attribute` | 4 | Attributes |
| `gm_product_price_tier` | 14 | Price tiers |
| `gm_product_collection` | 3 | Collections |
| `gm_service_fee` | 10 | Service fees |
| `gm_product_type` | 42 | Product types |
| `gm_rush_product_group` | 1 | Rush product groups |
| `sc_order_pull_session` (store) | - | xem gea_store__bronze |
| `sc_line_item_auto_mapping` | 227 | Auto mapping line items |
| `sc_order_rush_reservations` | Empty | Rush reservations |
| `sc_order_index` | Empty | Order index |
| `sc_order_log` | Empty | Order logs |
| `sc_order_export_session` | Empty | Export sessions |
| `sc_statistic_sales_order_unit` | Empty | Thống kê đơn vị sales |
| `sc_seller_config` | Empty | Cấu hình seller |
| `sc_seller_product` | Empty | Sản phẩm của seller |
| `sc_seller_product_variant` | Empty | Variants seller product |
| `sc_seller_product_group` | Empty | Groups seller product |
| `sc_seller_product_design_layer` | Empty | Design layers |
| `sc_seller_product_mockup` | Empty | Mockups |
| `sc_listed_product` | Empty | Listed products |
| `sc_listed_product_group` | Empty | Listed product groups |
| `sc_listed_product_variant` | Empty | Listed product variants |
| `sc_marketing_assets` | Empty | Marketing assets |
| `sc_seen_marketing_assets` | Empty | Seen marketing assets |
| `sc_export_template` | Empty | Export templates |
| `sc_black_list_address` | Empty | Blacklist addresses |
| `sc_black_list_user` | Empty | Blacklist users |
| `sc_onboarding_task` | Empty | Onboarding tasks |
| `sc_onboarding_subtask` | Empty | Onboarding subtasks |
| `sc_onboarding_team_status` | Empty | Onboarding team status |
| `sc_seller_config_printing_options` | Empty | Printing options config |
| `sc_seller_config_return_address` | Empty | Return address config |
| `sc_shipping_restrictions` | Empty | Shipping restrictions |
| `sc_staff_order_export_session` | Empty | Staff export sessions |
| `pg_heartbeat` | Empty | Postgres heartbeat CDC |
| `schema_migrations` | 258 | Migration history |

---

## `sc_order` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~949K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK nội bộ ClickHouse |
| `order_id` | String | ID đơn hàng (UUID) |
| `store_id` | String | ID store |
| `team_id` | String | ID team/seller |
| `created_method` | Nullable(String) | manual / import / pull / api |
| `import_id` | Nullable(String) | ID import session |
| `pull_id` | Nullable(String) | ID pull session |
| `request_id` | Nullable(String) | |
| `origin_order_id` | Nullable(String) | ID đơn gốc (nếu có) |
| `order_platform` | Nullable(String) | shopify / etsy / amazon... |
| `platform_ref` | Nullable(String) | ID đơn trên platform |
| `platform_ref_name` | Nullable(String) | Tên tham chiếu platform |
| `platform_store_ref` | Nullable(String) | Ref store platform |
| `fulfillment_vendor` | Nullable(String) | Vendor fulfillment |
| `vendor_ref` | Nullable(String) | |
| `priority` | Nullable(String) | |
| `order_date` | Nullable(DateTime64(6,'UTC')) | Ngày đặt hàng |
| `fulfillment_option` | Nullable(String) | |
| `billing_option` | Nullable(String) | |
| `shipping_option` | Nullable(String) | |
| `shipping_labels` | Nullable(String) | |
| `primary_package_id` | Nullable(String) | |
| `primary_shipment_id` | Nullable(String) | |
| `is_label_attached` | Nullable(Bool) | |
| `order_subtotal` | Nullable(Int64) | cents |
| `order_tax` | Nullable(Int64) | cents |
| `order_fee` | Nullable(Int64) | cents |
| `order_handle_fee` | Nullable(Int64) | cents |
| `order_gift_message_fee` | Nullable(Int64) | cents |
| `order_shipping_fee` | Nullable(Int64) | cents |
| `order_rush_fee` | Nullable(Int64) | cents |
| `order_thank_card_fee` | Nullable(Int64) | cents |
| `order_discount` | Nullable(Int64) | cents |
| `order_total` | Nullable(Int64) | cents |
| `order_redeem` | Nullable(Int64) | cents |
| `paid_total` | Nullable(Int64) | cents |
| `paid_needed` | Nullable(Int64) | cents |
| `order_surcharge` | Nullable(Int64) | cents |
| `tracking_no` | Nullable(String) | Tracking number |
| `processing_status` | Nullable(String) | |
| `status` | Nullable(String) | pending / approved / in_production / packed / shipped / cancelled |
| `approved_at` | Nullable(DateTime64(6,'UTC')) | |
| `paid_at` | Nullable(DateTime64(6,'UTC')) | |
| `cancelled_at` | Nullable(DateTime64(6,'UTC')) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `in_production_at` | Nullable(DateTime64(6,'UTC')) | |
| `packed_at` | Nullable(DateTime64(6,'UTC')) | |
| `shipped_at` | Nullable(DateTime64(6,'UTC')) | |
| `updated_by` | Nullable(String) | |
| `capture_status` | Nullable(String) | |
| `routing_status` | Nullable(String) | |
| `payment_status` | Nullable(String) | |
| `cancel_status` | Nullable(String) | |
| `refund_status` | Nullable(String) | |
| `refunded_total` | Nullable(Int64) | cents |
| `before_cancel_status` | Nullable(String) | |
| `user_id` | Nullable(String) | |
| `is_mark_fulfilled` | Nullable(Bool) | |
| `mark_fulfilled_by` | Nullable(String) | |
| `mark_fulfilled_at` | Nullable(DateTime64(6,'UTC')) | |
| `is_mark_fulfilled_internal` | Nullable(Bool) | |
| `printing_options` | Nullable(String) | |
| `amazon_tracking_reference_id` | Nullable(String) | |
| `amazon_order_tracking_status` | Nullable(String) | |
| `is_rush` | Nullable(Bool) | |
| `is_pii_redacted` | Bool | PII đã được xóa |
| `legacy_external_id` | Nullable(String) | |
| `fulfillment_location_code` | Nullable(String) | |
| `created_by` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | CDC metadata |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3,'UTC') | CDC timestamp |

---

## `sc_order_line_item` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~997K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | FK -> sc_order.order_id |
| `line_number` | Nullable(Int64) | |
| `product_id` | Nullable(String) | |
| `variant_id` | Nullable(String) | |
| `variant_sku` | Nullable(String) | |
| `variant_name` | Nullable(String) | |
| `seller_variant_id` | Nullable(String) | |
| `variant_attr` | Nullable(String) | JSON attributes |
| `item_id` | Nullable(String) | |
| `fulfillment_option` | Nullable(String) | |
| `printing_option` | Nullable(String) | |
| `item_price` | Nullable(Int64) | cents |
| `item_quantity` | Nullable(Int64) | |
| `line_subtotal` | Nullable(Int64) | cents |
| `line_tax` | Nullable(Int64) | cents |
| `line_fee` | Nullable(Int64) | cents |
| `line_discount` | Nullable(Int64) | cents |
| `line_shipping_fee` | Nullable(Int64) | cents |
| `line_extra_fee` | Nullable(Int64) | cents |
| `line_total` | Nullable(Int64) | cents |
| `origin_data` | Nullable(String) | JSON raw data |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_address` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~605K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | FK -> sc_order.order_id |
| `type` | Nullable(String) | shipping / billing |
| `first_name` | Nullable(String) | |
| `last_name` | Nullable(String) | |
| `full_name` | Nullable(String) | |
| `company` | Nullable(String) | |
| `contact_pronoun` | Nullable(String) | |
| `street1` | Nullable(String) | |
| `street2` | Nullable(String) | |
| `city` | Nullable(String) | |
| `zip_code` | Nullable(String) | |
| `state` | Nullable(String) | |
| `state_code` | Nullable(String) | |
| `country` | Nullable(String) | |
| `country_code` | Nullable(String) | |
| `phone_no` | Nullable(String) | |
| `email` | Nullable(String) | |
| `is_verification_bypassed` | Nullable(Bool) | |
| `is_pii_redacted` | Bool | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `updated_by` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_fee` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~710K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | FK -> sc_order.order_id |
| `line_item_id` | Nullable(String) | |
| `fee_code` | Nullable(String) | Mã loại phí |
| `fee_amount` | Nullable(Int64) | cents |
| `fee_quantity` | Nullable(Int64) | |
| `gift_message_id` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_payment` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~337K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | FK -> sc_order.order_id |
| `txn_id` | Nullable(String) | Transaction ID |
| `txn_ref` | Nullable(String) | |
| `ack_ref` | Nullable(String) | |
| `amount` | Nullable(Int64) | cents |
| `status` | Nullable(String) | |
| `expired_at` | Nullable(DateTime64(6,'UTC')) | |
| `checkout_method` | Nullable(String) | |
| `note` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_refund` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~7K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | FK -> sc_order.order_id |
| `txn_id` | Nullable(String) | |
| `txn_ref` | Nullable(String) | |
| `amount` | Nullable(Int64) | cents |
| `status` | Nullable(String) | |
| `expired_at` | Nullable(DateTime64(6,'UTC')) | |
| `refund_request_id` | Nullable(String) | |
| `refund_type` | Nullable(String) | |
| `order_refund_id` | Nullable(String) | |
| `created_by` | Nullable(String) | |
| `notes` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_shipment` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~529K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | FK -> sc_order.order_id |
| `team_id` | String | |
| `package_id` | Nullable(String) | |
| `vendor_ref` | Nullable(String) | |
| `vendor_ref_code` | Nullable(String) | |
| `label_url` | Nullable(String) | |
| `tracking_number` | Nullable(String) | |
| `tracking_company` | Nullable(String) | |
| `tracking_url` | Nullable(String) | |
| `tracking_carrier` | Nullable(String) | |
| `tracking_service` | Nullable(String) | |
| `tracking_type` | Nullable(String) | |
| `tracking_product_type` | Nullable(String) | |
| `ship_status` | Nullable(String) | |
| `carrier_service` | Nullable(String) | |
| `carrier_display` | Nullable(String) | |
| `service_display` | Nullable(String) | |
| `api_source` | Nullable(String) | |
| `shipping_data` | Nullable(String) | JSON |
| `type` | Nullable(String) | |
| `is_deleted` | Nullable(Bool) | |
| `fulfillment_order_id` | Nullable(Int64) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `updated_by` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_cancel_detail` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~1.3K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | String | FK -> sc_order.order_id |
| `reason_id` | Nullable(String) | FK -> sc_order_cancel_reason |
| `custom_reason` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_cancel_reason` 🔵

> Engine: SharedReplacingMergeTree | Rows: 15
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `reason_id` | String | |
| `display_name` | Nullable(String) | |
| `display_order` | Nullable(Int64) | |
| `active` | Nullable(Bool) | |
| `category_id` | Nullable(String) | |
| `is_custom` | Nullable(Bool) | |
| `created_at` | DateTime64(6) | |
| `updated_at` | DateTime64(6) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_gift_message` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~1.3K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | |
| `gift_message_id` | Nullable(String) | |
| `type` | Nullable(String) | |
| `content` | Nullable(String) | |
| `avatar_url` | Nullable(String) | |
| `gift_message_name` | Nullable(String) | |
| `file_path` | Nullable(String) | |
| `file_url` | Nullable(String) | |
| `file_id` | Nullable(String) | |
| `storage_id` | Nullable(String) | |
| `capture_status` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_fulfillment_order` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~817K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | FK -> sc_order.order_id |
| `team_id` | String | |
| `package_id` | Nullable(String) | |
| `fulfillment_vendor` | Nullable(String) | |
| `vendor_ref` | Nullable(String) | |
| `vendor_ref_code` | Nullable(String) | |
| `status` | Nullable(String) | |
| `vendor_status` | Nullable(String) | |
| `tracking_number` | Nullable(String) | |
| `type` | Nullable(String) | |
| `fulfillment_location_code` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_fulfillment_order_line` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~664K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | |
| `fulfillment_order_id` | Nullable(Int64) | FK -> sc_fulfillment_order.id |
| `package_id` | Nullable(String) | |
| `package_line_id` | Nullable(String) | |
| `ref_line_id` | Nullable(String) | |
| `ref_variant_id` | Nullable(String) | |
| `ref_variant_sku` | Nullable(String) | |
| `quantity` | Nullable(Int64) | |
| `printing_option` | Nullable(String) | |
| `item_barcode_url` | Nullable(String) | |
| `status` | Nullable(String) | |
| `vendor_status` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_fulfillment_package` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~820K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | |
| `package_id` | Nullable(String) | UUID package |
| `fulfillment_vendor` | Nullable(String) | |
| `fulfillment_priority` | Nullable(String) | |
| `vendor_ref` | Nullable(String) | |
| `vendor_ref_code` | Nullable(String) | |
| `status` | Nullable(String) | |
| `tracking_number` | Nullable(String) | |
| `option` | Nullable(String) | |
| `shipping_labels` | Nullable(String) | |
| `note` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_fulfillment_package_line` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~999K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `order_id` | Nullable(String) | |
| `order_item_id` | Nullable(String) | |
| `package_id` | Nullable(String) | FK -> sc_fulfillment_package.package_id |
| `package_item_id` | Nullable(String) | |
| `product_id` | Nullable(String) | |
| `variant_id` | Nullable(String) | |
| `variant_sku` | Nullable(String) | |
| `quantity` | Nullable(Int64) | |
| `printing_option` | Nullable(String) | |
| `item_barcode_path` | Nullable(String) | |
| `item_barcode_storage_id` | Nullable(String) | |
| `line_number` | Nullable(Int64) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_fulfillment_package_gift_message` 🔵

> Engine: SharedReplacingMergeTree | Rows: 284
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `package_id` | Nullable(String) | |
| `message_id` | Nullable(String) | |
| `message_path` | Nullable(String) | |
| `message_note` | Nullable(String) | |
| `message_storage_id` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_draft` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~110K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `draft_id` | String | UUID draft |
| `order_id` | Nullable(String) | Sau khi convert thành order |
| `store_id` | String | |
| `team_id` | String | |
| `user_id` | Nullable(String) | |
| `platform_ref` | Nullable(String) | |
| `order_platform` | Nullable(String) | |
| `import_id` | Nullable(String) | |
| `pull_id` | Nullable(String) | |
| `status` | Nullable(Int16) | 0=draft, 1=approved... |
| `created_method` | Nullable(String) | |
| `fulfillment_vendor` | Nullable(String) | |
| `priority` | Nullable(String) | |
| `fulfillment_option` | Nullable(String) | |
| `shipping_option` | Nullable(String) | |
| `printing_option` | Nullable(String) | |
| `billing_option` | Nullable(String) | |
| `order_total` | Nullable(Int64) | cents |
| `order_subtotal` | Nullable(Int64) | cents |
| `order_handle_fee` | Nullable(Int64) | cents |
| `order_discount` | Nullable(Int64) | cents |
| `order_gift_message_fee` | Nullable(Int64) | cents |
| `order_shipping_fee` | Nullable(Int64) | cents |
| `order_tax` | Nullable(Int64) | cents |
| `order_fee` | Nullable(Int64) | cents |
| `shipping_verification_status` | Nullable(String) | |
| `product_matching_status` | Nullable(String) | |
| `policy_verification_status` | Nullable(String) | |
| `is_approved` | Nullable(Bool) | |
| `is_pii_redacted` | Bool | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_draft_line_item` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~135K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `draft_id` | Nullable(String) | FK -> sc_order_draft.draft_id |
| `team_id` | String | |
| `line_number` | Nullable(Int64) | |
| `origin_sku` | Nullable(String) | SKU từ platform |
| `origin_name` | Nullable(String) | |
| `product_id` | Nullable(String) | Sau khi match |
| `variant_id` | Nullable(String) | |
| `variant_sku` | Nullable(String) | |
| `variant_name` | Nullable(String) | |
| `seller_variant_id` | Nullable(String) | |
| `is_skipped` | Nullable(Bool) | |
| `fulfillment_option` | Nullable(String) | |
| `printing_option` | Nullable(String) | |
| `item_price` | Nullable(Int64) | cents |
| `item_quantity` | Nullable(Int64) | |
| `line_total` | Nullable(Int64) | cents |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_order_draft_address` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~58K
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `draft_id` | Nullable(String) | FK -> sc_order_draft.draft_id |
| `team_id` | String | |
| `type` | Nullable(String) | shipping / billing |
| `first_name` | Nullable(String) | |
| `last_name` | Nullable(String) | |
| `street1` | Nullable(String) | |
| `city` | Nullable(String) | |
| `zip_code` | Nullable(String) | |
| `country` | Nullable(String) | |
| `country_code` | Nullable(String) (từ sc_order_address) | |
| `state` | Nullable(String) | |
| `phone_no` | Nullable(String) | |
| `email` | Nullable(String) | |
| `is_pii_redacted` | Bool | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_line_item_auto_mapping` 🔵

> Engine: SharedReplacingMergeTree | Rows: 227
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `origin_sku` | Nullable(String) | |
| `platform` | Nullable(String) | |
| `variant_id` | Nullable(String) | |
| `product_id` | Nullable(String) | |
| `seller_variant_id` | Nullable(String) | |
| `printing_option` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `updated_by` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_seller_config` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup. Cấu hình seller (payment, shipping, automation...)

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `volume_commitment` | Nullable(String) | |
| `is_auto_approve` | Nullable(Bool) | |
| `is_auto_payment` | Nullable(Bool) | |
| `is_rush_order` | Nullable(Bool) | |
| `is_auto_sync_tracking` | Nullable(Bool) | |
| `default_shipping_method` | Nullable(String) | |
| `is_invoice_enabled` | Nullable(Bool) | |
| `is_credit_card_payment_allowed` | Nullable(Bool) | |
| `is_payoneer_payment_allowed` | Nullable(Bool) | |
| ... (nhiều cột is_* boolean) | Nullable(Bool) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_seller_product` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `seller_product_id` | String | UUID |
| `product_id` | Nullable(String) | FK -> gm_product |
| `name` | Nullable(String) | |
| `status` | Nullable(String) | |
| `type` | Nullable(String) | |
| `price` | Nullable(Int64) | cents |
| `printing_option` | Nullable(String) | |
| `storage_id` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `sc_seller_product_variant` 🔵

> Engine: SharedReplacingMergeTree | Rows: Empty
> Dùng `FINAL` khi query để dedup

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `seller_product_id` | Nullable(String) | |
| `seller_variant_id` | Nullable(String) | UUID |
| `product_id` | Nullable(String) | |
| `variant_id` | Nullable(String) | FK -> gm_product_variant |
| `variant_sku` | Nullable(String) | |
| `variant_name` | Nullable(String) | |
| `variant_option_1/2/3` | Nullable(String) | Options |
| `price` | Nullable(Int64) | cents |
| `color` | Nullable(String) | |
| `printing_option` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `gm_product` 🔵

> Engine: SharedReplacingMergeTree | Rows: 175
> Dùng `FINAL` khi query để dedup. Catalog sản phẩm Gearment (base product, không phải variant).

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK nội bộ ClickHouse |
| `product_id` | String | UUID — key chính |
| `legacy_id` | Nullable(Int64) | |
| `sku` | Nullable(String) | |
| `name` | Nullable(String) | Tên sản phẩm |
| `code` | Nullable(String) | |
| `description` | Nullable(String) | |
| `product_type_id` | Nullable(Int64) | FK -> gm_product_type.id |
| `hs_code` | Nullable(String) | |
| `price` | Nullable(Int64) | cents |
| `min_price` | Nullable(Int64) | cents |
| `status` | Nullable(Int16) | |
| `display_status` | Nullable(Int16) | |
| `display_order` | Nullable(Int64) | |
| `short_url` | Nullable(String) | |
| `avatar_url` | Nullable(String) | |
| `print_template` | Nullable(String) | |
| `is_featured` | Nullable(Bool) | |
| `is_trending` | Nullable(Bool) | |
| `is_recommend` | Nullable(Bool) | |
| `is_new_arrival` | Nullable(Bool) | |
| `is_website_catalog_listing_enabled` | Nullable(Bool) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `gm_product_variant` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~9.9K
> Dùng `FINAL` khi query để dedup. Variants của Gearment catalog (color × size combinations).

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK nội bộ ClickHouse |
| `variant_id` | String | UUID — key chính, FK từ sc_order_line_item.variant_id |
| `product_id` | Nullable(String) | FK -> gm_product.product_id |
| `legacy_id` | Nullable(Int64) | |
| `variant_sku` | Nullable(String) | |
| `gtin` | Nullable(String) | |
| `hs_code` | Nullable(String) | |
| `status` | Nullable(Int16) | |
| `order_channel` | Nullable(Int16) | |
| `name` | Nullable(String) | Tên variant (color + size) |
| `description` | Nullable(String) | |
| `option1` | Nullable(String) | Color value |
| `option1_code` | Nullable(String) | Color code |
| `option1_name` | Nullable(String) | Color display name |
| `option2` | Nullable(String) | Size value |
| `option2_code` | Nullable(String) | Size code — JOIN với gm_product_option.code WHERE type=2 |
| `option2_name` | Nullable(String) | Size display name |
| `option3` | Nullable(String) | |
| `price` | Nullable(Int64) | cents |
| `recommended_price` | Nullable(Int64) | cents |
| `extra_price` | Nullable(Int64) | cents |
| `stock_quantity` | Nullable(Int64) | |
| `stock_label` | Nullable(String) | |
| `weight` | Nullable(Int64) | |
| `weight_unit` | Nullable(String) | |
| `created_at` | String | |
| `created_by` | Nullable(String) | |
| `updated_at` | String | |
| `updated_by` | Nullable(String) | |
| `ts_token` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `gm_product_option` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~2.9K
> Dùng `FINAL` khi query để dedup. Options của sản phẩm (size, color, v.v.).

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `product_id` | Nullable(String) | FK -> gm_product.product_id |
| `type` | Nullable(Int16) | 1=color, 2=size — dùng `type=2` để lấy size option |
| `name` | Nullable(String) | Tên option (vd: "S", "M", "L") |
| `value` | Nullable(String) | |
| `quantity` | Nullable(Int64) | Số đơn vị per option (vd: 1 shirt = 1 unit) |
| `code` | Nullable(String) | Option code — JOIN với gm_product_variant.option2_code |
| `is_default` | Nullable(Bool) | |
| `is_featured` | Nullable(Bool) | |
| `description` | Nullable(String) | |
| `display_order` | Nullable(Int64) | |
| `status` | Nullable(String) | |
| `ts_token` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `gm_product_type` 🔵

> Engine: SharedReplacingMergeTree | Rows: 42
> Dùng `FINAL` khi query để dedup. Loại sản phẩm (Apparel, Sticker, Poster, Mug, ...).

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK — FK từ gm_product.product_type_id |
| `name` | Nullable(String) | Tên loại (Apparel / Sticker / Poster / Mug / ...) |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `gm_product_price` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~4K
> Dùng `FINAL` khi query để dedup

---

## `gm_team_price_tier` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~34K
> Dùng `FINAL` khi query để dedup. Price tier assignment theo team. Mỗi team có 1 active tier.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | FK -> iam_team.team_id |
| `tier_id` | Nullable(String) | sale_price=Bronze, price_5000=Silver, price_15000=Gold, price_30000=Platinum, price_50000=Diamond |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `updated_by` | Nullable(String) | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `gm_country_policy` 🔵

> Engine: SharedReplacingMergeTree | Rows: 249
> Dùng `FINAL` khi query để dedup. Chính sách shipping theo quốc gia.

---

## `gm_product_shipping_fee` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~15K
> Dùng `FINAL` khi query để dedup. Phí shipping theo product.

---

## `schema_migrations` 🔵

> Engine: SharedMergeTree | Rows: 258
> Lịch sử migration database.

---

## Internal Tables (excluded)

Các bảng `__raw` (raw CDC buffer) và `__mv_to_latest` (MaterializedView để dedup) được exclude khỏi docs chính.

**MaterializedViews (`__mv_to_latest`):** 86 views — mỗi table chính đều có 1 MV tương ứng để maintain latest state.

Ví dụ: `sc_order__mv_to_latest`, `sc_order_line_item__mv_to_latest`, `gm_product__mv_to_latest`...

# Schema: gea_wms__bronze

**Layer:** Bronze (raw CDC từ WMS system)
**Last updated:** 2026-03-17
**Tables:** 59 (excl. schema_migrations)

> **Engine:** Tất cả tables dùng `SharedMergeTree` — không cần `FINAL`
>
> **CDC metadata columns** (có trên tất cả `wms_*` tables):
> - `_processed_at` `DateTime64(3,'UTC')` — thời điểm CDC ingest vào ClickHouse
> - `_action` `String` — CDC action: `insert` / `update` / `delete`
> - `_timestamp` `DateTime64(3,'UTC')` — timestamp từ CDC event

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| **Inventory** | | |
| `wms_inventory_bin_clusters` | ~93,356 | Inventory theo bin + cluster |
| `wms_inventory_clusters` | ~23,339 | Inventory theo cluster |
| `wms_inventories` | ~23,339 | Inventory tổng theo SKU + warehouse |
| `wms_warehouse_products` | ~23,339 | Product đăng ký tại warehouse |
| `wms_inventory_histories` | 0 | Lịch sử thay đổi inventory |
| **Outbound / Fulfillment** | | |
| `wms_outbound_request_items` | ~34,320 | Line items của outbound request |
| `wms_outbound_requests` | ~28,649 | Outbound requests |
| `wms_outbound_request_item_allocations` | ~9 | Allocation của từng line item OR |
| `wms_outbound_request_histories` | ~54 | Lịch sử status thay đổi OR |
| `wms_workorders` | ~2 | Work orders |
| `wms_workorder_items` | ~7 | Items trong work order |
| `wms_workorder_outbound_requests` | ~8 | OR gắn với work order |
| **Purchase Orders** | | |
| `wms_purchase_order_shipment_items` | ~452 | Items trong PO shipment |
| `wms_purchase_order_shipment_receipt_items` | ~412 | Receipt items khi nhận hàng |
| `wms_purchase_order_histories` | ~1,581 | Lịch sử status PO |
| `wms_purchase_order_items` | ~431 | Items trong PO |
| `wms_purchase_order_shipments` | ~230 | Shipments của PO |
| `wms_purchase_orders` | ~206 | Purchase orders |
| `wms_purchase_requisitions` | 0 | Purchase requisitions |
| `wms_purchase_requisition_items` | 0 | Items trong purchase requisition |
| `wms_purchase_requisition_histories` | 0 | Lịch sử purchase requisition |
| **Transfer Orders** | | |
| `wms_transfer_order_histories` | ~1,616 | Lịch sử status transfer order |
| `wms_transfer_order_items` | ~940 | Items trong transfer order |
| `wms_transfer_order_item_allocations` | ~877 | Allocation items transfer order |
| `wms_transfer_orders` | ~238 | Transfer orders |
| **Cross-Docking** | | |
| `wms_cross_docking_shipment_parcels` | ~14 | Parcels trong shipment plan |
| `wms_cross_docking_shipment_parcel_items` | ~14 | Items trong parcel |
| `wms_cross_docking_shipment_cartons` | ~12 | Cartons trong shipment plan |
| `wms_cross_docking_shipment_plans` | ~7 | Kế hoạch cross-docking |
| `wms_cross_docking_shipment_histories` | ~19 | Lịch sử shipment plan |
| **Handover / Logistics** | | |
| `wms_handover_session_logs` | ~7 | Event logs của handover session |
| `wms_handover_session_items` | ~5 | Items trong handover session |
| `wms_handover_session_manifests` | ~3 | Manifests của handover session |
| `wms_handover_sessions` | ~2 | Handover sessions |
| `wms_handover_session_attachments` | 0 | File đính kèm handover session |
| **Client & Products** | | |
| `wms_client_products` | ~12,786 | Sản phẩm của client |
| `wms_client_vendors` | ~22 | Nhà cung cấp của client |
| `wms_clients` | ~11 | Clients (merchants) |
| `wms_item_categories` | 0 | Danh mục sản phẩm |
| `wms_client_platforms` | 0 | Platforms của client |
| **Warehouse & Location** | | |
| `wms_warehouses` | ~17 | Warehouses |
| `wms_areas` | ~17 | Areas trong warehouse |
| `wms_shelves` | ~17 | Kệ hàng trong warehouse |
| `wms_bins` | ~68 | Bins (ô lưu trữ) |
| `wms_floors` | ~17 | Tầng trong warehouse |
| `wms_locations` | 0 | Locations |
| **Users & Access** | | |
| `wms_user_warehouse_roles` | ~178 | Roles của user tại warehouse |
| `wms_user_warehouses` | ~148 | Mapping user - warehouse |
| `wms_role_permissions` | ~114 | Quyền của từng role |
| `wms_users` | ~28 | Users WMS |
| `wms_user_teams` | ~2 | Mapping user - team |
| `wms_user_sessions` | 0 | Sessions đăng nhập |
| `wms_roles` | ~7 | Roles |
| `wms_teams` | ~1 | Teams |
| `wms_team_locations` | 0 | Locations của team |
| `wms_team_warehouses` | 0 | Warehouses của team |
| **Config / Infra** | | |
| `wms_configurations` | 0 | Cấu hình hệ thống |
| `wms_entry_counters` | 0 | Bộ đếm entry |
| `wms_printers` | 0 | Printers |

---

## `wms_areas`

> Engine: SharedMergeTree | Rows: ~17

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_bins`

> Engine: SharedMergeTree | Rows: ~68

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `area_code` | Nullable(String) | |
| `shelf_code` | Nullable(String) | |
| `floor_code` | Nullable(String) | |
| `condition_type` | Nullable(String) | good / damaged / expired / lost |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_client_platforms`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `name` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_client_products`

> Engine: SharedMergeTree | Rows: ~12,786

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `client_code` | Nullable(String) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `client_vendor_code` | Nullable(String) | |
| `name` | Nullable(String) | |
| `type` | Nullable(String) | |
| `description` | Nullable(String) | |
| `width` | Nullable(Float64) | |
| `height` | Nullable(Float64) | |
| `length` | Nullable(Float64) | |
| `weight` | Nullable(Float64) | |
| `status` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `uom` | Nullable(String) | Unit of measure |
| `thumbnail_url` | Nullable(String) | |
| `category_code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_client_vendors`

> Engine: SharedMergeTree | Rows: ~22

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `client_code` | Nullable(String) | |
| `client_vendor_code` | Nullable(String) | |
| `name` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `address_1` | Nullable(String) | |
| `address_2` | Nullable(String) | |
| `country` | Nullable(String) | |
| `division_level_1` | Nullable(String) | |
| `division_level_2` | Nullable(String) | |
| `division_level_3` | Nullable(String) | |
| `division_level_4` | Nullable(String) | |
| `division_level_5` | Nullable(String) | |
| `zip_code` | Nullable(String) | |
| `contact_name` | Nullable(String) | |
| `contact_email` | Nullable(String) | |
| `contact_phone` | Nullable(String) | |
| `is_active` | Nullable(Bool) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_clients`

> Engine: SharedMergeTree | Rows: ~11

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `first_name` | Nullable(String) | |
| `last_name` | Nullable(String) | |
| `address_1` | Nullable(String) | |
| `address_2` | Nullable(String) | |
| `country` | Nullable(String) | |
| `division_level_1` | Nullable(String) | |
| `division_level_2` | Nullable(String) | |
| `division_level_3` | Nullable(String) | |
| `division_level_4` | Nullable(String) | |
| `division_level_5` | Nullable(String) | |
| `zip_code` | Nullable(String) | |
| `full_address` | Nullable(String) | |
| `phone` | Nullable(String) | |
| `email` | Nullable(String) | |
| `is_active` | Nullable(Bool) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_configurations`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `key` | String | |
| `type` | String | |
| `text_value` | Nullable(String) | |
| `integer_value` | Nullable(Int64) | |
| `json_value` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_cross_docking_shipment_cartons`

> Engine: SharedMergeTree | Rows: ~12

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `shipment_plan_id` | Nullable(Int64) | |
| `sp_code` | Nullable(String) | shipment plan code |
| `client_code` | Nullable(String) | |
| `client_sp_code` | Nullable(String) | |
| `client_carton_code` | Nullable(String) | |
| `status` | Nullable(String) | draft; awaiting_receipt; received; closed; cancelled |
| `received_warehouse_code` | Nullable(String) | |
| `total_parcels` | Nullable(Int32) | |
| `received_parcels` | Nullable(Int32) | default: 0 |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `received_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_cross_docking_shipment_histories`

> Engine: SharedMergeTree | Rows: ~19

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `sp_code` | Nullable(String) | shipment plan code |
| `received_warehouse_code` | Nullable(String) | |
| `client_code` | Nullable(String) | |
| `client_sp_code` | Nullable(String) | |
| `client_carton_code` | Nullable(String) | |
| `client_parcel_code` | Nullable(String) | |
| `event_type` | String | |
| `updated_user_id` | Nullable(Int64) | |
| `updated_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_cross_docking_shipment_parcel_items`

> Engine: SharedMergeTree | Rows: ~14

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `shipment_parcel_id` | Nullable(Int64) | |
| `content` | Nullable(String) | |
| `quantity` | Nullable(Int32) | |
| `inserted_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_cross_docking_shipment_parcels`

> Engine: SharedMergeTree | Rows: ~14

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `shipment_plan_id` | Nullable(Int64) | |
| `shipment_carton_id` | Nullable(Int64) | |
| `sp_code` | Nullable(String) | shipment plan code |
| `received_warehouse_code` | Nullable(String) | |
| `client_code` | Nullable(String) | |
| `client_sp_code` | Nullable(String) | |
| `client_carton_code` | Nullable(String) | |
| `client_parcel_code` | Nullable(String) | |
| `or_code` | Nullable(String) | outbound request code (internal WMS code) |
| `tracking_code` | Nullable(String) | |
| `tracking_carrier` | Nullable(String) | |
| `tracking_service` | Nullable(String) | |
| `shipping_label_url` | Nullable(String) | |
| `tracking_url` | Nullable(String) | |
| `is_labeled_by_warehouse` | Nullable(Bool) | warehouse có tự in label không |
| `created_at` | Nullable(String) | |
| `inserted_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `client_parcel_ref_code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_cross_docking_shipment_plans`

> Engine: SharedMergeTree | Rows: ~7

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | Format: RP12345678 |
| `client_sp_code` | Nullable(String) | |
| `client_code` | Nullable(String) | |
| `status` | Nullable(String) | draft; awaiting_receipt; partially_received; closed; cancelled |
| `from_address_1` | Nullable(String) | |
| `from_address_2` | Nullable(String) | |
| `from_country` | Nullable(String) | |
| `from_division_level_1` | Nullable(String) | |
| `from_division_level_2` | Nullable(String) | |
| `from_zip_code` | Nullable(String) | |
| `to_address_1` | Nullable(String) | |
| `to_address_2` | Nullable(String) | |
| `to_country` | Nullable(String) | |
| `to_division_level_1` | Nullable(String) | |
| `to_division_level_2` | Nullable(String) | |
| `to_zip_code` | Nullable(String) | |
| `expected_arrival_time` | Nullable(String) | |
| `tracking_code` | Nullable(String) | |
| `tracking_carrier` | Nullable(String) | |
| `shipped_at` | Nullable(String) | |
| `received_warehouse_code` | Nullable(String) | |
| `is_labeled_by_warehouse` | Nullable(Bool) | warehouse có tự in label không; default: false |
| `total_cartons` | Nullable(Int32) | |
| `received_cartons` | Nullable(Int32) | |
| `created_at` | Nullable(String) | |
| `inserted_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `tracking_service` | Nullable(String) | |
| `tracking_url` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_entry_counters`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `entry_type` | Nullable(String) | |
| `count` | Nullable(Int32) | |
| `entry_time` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_floors`

> Engine: SharedMergeTree | Rows: ~17

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `area_code` | Nullable(String) | |
| `shelf_code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_handover_session_attachments`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `handover_session_id` | Nullable(Int64) | |
| `file_name` | Nullable(String) | |
| `content_type` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `file_url` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_handover_session_items`

> Engine: SharedMergeTree | Rows: ~5

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `handover_session_id` | Nullable(Int64) | |
| `handover_session_code` | Nullable(String) | |
| `or_code` | Nullable(String) | outbound request code (internal WMS code) |
| `client_or_code` | Nullable(String) | outbound request code từ phía client |
| `manifest_code` | Nullable(String) | |
| `tracking_code` | Nullable(String) | |
| `action` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `client_or_ref_code` | Nullable(String) | |
| `scan_evidence_url` | Nullable(String) | |
| `carrier_code` | Nullable(String) | |
| `service_code` | Nullable(String) | |
| `scanned_user_id` | Nullable(Int64) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_handover_session_logs`

> Engine: SharedMergeTree | Rows: ~7

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `handover_session_id` | Nullable(Int64) | |
| `handover_session_code` | Nullable(String) | |
| `handover_session_item_id` | Nullable(Int64) | |
| `handover_session_manifest_id` | Nullable(Int64) | |
| `or_code` | Nullable(String) | outbound request code (internal WMS code) |
| `client_or_code` | Nullable(String) | outbound request code từ phía client |
| `tracking_code` | Nullable(String) | |
| `event_object` | Nullable(String) | |
| `event_type` | Nullable(String) | |
| `event_status` | Nullable(String) | |
| `event_note` | Nullable(String) | |
| `user_id` | Nullable(Int64) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_handover_session_manifests`

> Engine: SharedMergeTree | Rows: ~3

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `handover_session_id` | Nullable(Int64) | |
| `handover_session_code` | Nullable(String) | |
| `manifest_code` | Nullable(String) | |
| `carrier_code` | Nullable(String) | |
| `service_code` | Nullable(String) | |
| `file_url` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_handover_sessions`

> Engine: SharedMergeTree | Rows: ~2

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `carrier_code` | Nullable(String) | |
| `service_code` | Nullable(String) | |
| `status` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `closed_at` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `total_scanned_in` | Nullable(Int32) | |
| `total_scanned_out` | Nullable(Int32) | |
| `created_by_user_id` | Nullable(Int64) | |
| `closed_by_user_id` | Nullable(Int64) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_inventories`

> Engine: SharedMergeTree | Rows: ~23,339

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `warehouse_code` | Nullable(String) | |
| `client_code` | Nullable(String) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `good_quantity` | Nullable(Int32) | total good condition |
| `good_available_quantity` | Nullable(Int32) | available good condition; = fulfillable_stock |
| `good_allocated_quantity` | Nullable(Int32) | allocated good condition |
| `damaged_quantity` | Nullable(Int32) | total damaged condition |
| `damaged_available_quantity` | Nullable(Int32) | available damaged condition |
| `damaged_allocated_quantity` | Nullable(Int32) | allocated damaged condition |
| `expired_quantity` | Nullable(Int32) | total expired condition |
| `expired_available_quantity` | Nullable(Int32) | available expired condition |
| `expired_allocated_quantity` | Nullable(Int32) | allocated expired condition |
| `lost_quantity` | Nullable(Int32) | lost stock |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `warehouse_barcode` | Nullable(String) | |
| `status` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_inventory_bin_clusters`

> Engine: SharedMergeTree | Rows: ~93,356

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `bin_code` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `client_code` | Nullable(String) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `cluster_code` | Nullable(String) | |
| `condition_type` | Nullable(String) | good; damaged; lost; expired |
| `quantity` | Nullable(Int32) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `cluster_system_code` | Nullable(String) | [system_sku]-[warehouse_code]-[cluster_code] |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_inventory_clusters`

> Engine: SharedMergeTree | Rows: ~23,339

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `warehouse_code` | Nullable(String) | |
| `code` | Nullable(String) | EXP[YYYY][MM][DD] (expiry); SRN[serial_number] (serial); UNKNOWN (unmanaged) |
| `inventory_id` | Int64 | |
| `client_code` | Nullable(String) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `good_quantity` | Nullable(Int32) | total good condition |
| `good_available_quantity` | Nullable(Int32) | available good condition |
| `good_allocated_quantity` | Nullable(Int32) | allocated good condition |
| `damaged_quantity` | Nullable(Int32) | total damaged condition |
| `damaged_available_quantity` | Nullable(Int32) | available damaged condition |
| `damaged_allocated_quantity` | Nullable(Int32) | allocated damaged condition |
| `expired_quantity` | Nullable(Int32) | total expired condition |
| `expired_available_quantity` | Nullable(Int32) | available expired condition |
| `expired_allocated_quantity` | Nullable(Int32) | allocated expired condition |
| `lost_quantity` | Nullable(Int32) | lost stock |
| `fulfillable_expired_at` | Nullable(String) | Outbound threshold — hạn tối thiểu để xuất kho |
| `expired_at` | Nullable(String) | |
| `serial_number` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `system_code` | Nullable(String) | [system_sku]-[warehouse_code]-[cluster_code] |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_inventory_histories`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `bin_code` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `client_code` | Nullable(String) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `cluster_code` | Nullable(String) | |
| `condition_type` | Nullable(String) | good / damaged / expired / lost |
| `update_reason` | Nullable(String) | |
| `updated_field` | Nullable(String) | |
| `quantity_after_update` | Nullable(Int32) | |
| `adjusted_quantity` | Nullable(Int32) | |
| `updated_at` | Nullable(String) | |
| `remark` | Nullable(String) | |
| `inventory_id` | Nullable(Int64) | |
| `inventory_cluster_id` | Nullable(Int64) | |
| `updated_user_id` | Nullable(Int64) | |
| `outbound_request_code` | Nullable(String) | |
| `po_code` | Nullable(String) | purchase order code |
| `po_shipment_code` | Nullable(String) | |
| `tf_code` | Nullable(String) | transfer order code |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_item_categories`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `name` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_locations`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `name` | Nullable(String) | |
| `is_active` | Nullable(Bool) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_outbound_request_histories`

> Engine: SharedMergeTree | Rows: ~54

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `outbound_request_id` | Int64 | |
| `client_code` | Nullable(String) | |
| `client_or_code` | Nullable(String) | outbound request code từ phía client |
| `old_status` | Nullable(String) | |
| `new_status` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `updated_user_id` | Nullable(Int64) | |
| `remark` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_outbound_request_item_allocations`

> Engine: SharedMergeTree | Rows: ~9

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `outbound_request_item_id` | Int64 | |
| `cluster_code` | Nullable(String) | |
| `cluster_expired_at` | Nullable(String) | |
| `cluster_serial_number` | Nullable(String) | |
| `quantity` | Nullable(Int32) | |
| `condition_type` | Nullable(String) | good; damaged; lost; expired |
| `outbound_request_code` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `bin_code` | Nullable(String) | |
| `cluster_system_code` | Nullable(String) | [system_sku]-[warehouse_code]-[cluster_code] |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_outbound_request_items`

> Engine: SharedMergeTree | Rows: ~34,320

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `outbound_request_id` | Int64 | |
| `client_or_code` | Nullable(String) | outbound request code từ phía client |
| `line_number` | Nullable(Int32) | |
| `client_code` | Nullable(String) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `client_product_name` | Nullable(String) | Denorm product name from client |
| `quantity` | Nullable(Int32) | |
| `unit_price` | Nullable(Int64) | cents (use subunit) |
| `allocation_status` | Nullable(String) | pending; allocated; unallocatable; deallocated |
| `packed_quantity` | Nullable(Int32) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_outbound_requests`

> Engine: SharedMergeTree | Rows: ~28,649

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `client_code` | Nullable(String) | |
| `client_platform_code` | Nullable(String) | Channel platform code |
| `warehouse_code` | Nullable(String) | |
| `code` | Nullable(String) | OR code, format: OR12345678 |
| `client_or_code` | Nullable(String) | POD order code |
| `or_type` | Nullable(String) | production=sản xuất; cross_docking; transfer |
| `created_at` | Nullable(String) | |
| `inserted_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `status` | Nullable(String) | production: allocating_stock; allocated_stock; picking; in_production; packing; packed; out_of_stock; cancelled; on_hold; handing_over; shipped; completed; reallocating_stock \| cross_docking: awaiting_confirmation; received; packed; shipped; handing_over; on_hold; cancelled |
| `note` | Nullable(String) | |
| `total_amount` | Nullable(Int64) | cents (use subunit) |
| `cancel_reason` | Nullable(String) | |
| `tracking_code` | Nullable(String) | |
| `shipping_label_url` | Nullable(String) | |
| `previous_status` | Nullable(String) | Lưu status trước đó, dùng cho hold/unhold |
| `workorder_code` | Nullable(String) | work order code |
| `total_item_quantity` | Nullable(Int32) | |
| `total_item_packed_quantity` | Nullable(Int32) | |
| `tracking_carrier` | Nullable(String) | |
| `tracking_service` | Nullable(String) | |
| `tracking_url` | Nullable(String) | |
| `client_ref_code` | Nullable(String) | |
| `shipped_at` | Nullable(String) | |
| `in_charge_processor_id` | Nullable(Int64) | ID người xử lý |
| `is_labeled_by_warehouse` | Bool | warehouse có tự in label không; default: false |
| `client_shipment_carton_code` | Nullable(String) | |
| `sp_code` | Nullable(String) | shipment plan code |
| `client_sp_code` | Nullable(String) | |
| `packing_evidence_url` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_printers`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int32 | PK |
| `code` | String | |
| `name` | String | |
| `host` | String | |
| `port` | Int32 | |
| `warehouse_code` | String | |
| `url` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_purchase_order_histories`

> Engine: SharedMergeTree | Rows: ~1,581

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int32 | PK |
| `purchase_order_id` | Int64 | |
| `purchase_order_shipment_id` | Nullable(Int64) | |
| `po_code` | Nullable(String) | purchase order code |
| `po_shipment_code` | Nullable(String) | |
| `entry_type` | Nullable(String) | |
| `old_po_status` | Nullable(String) | |
| `new_po_status` | Nullable(String) | |
| `old_shipment_status` | Nullable(String) | |
| `new_shipment_status` | Nullable(String) | |
| `updated_user_id` | Nullable(Int64) | |
| `updated_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_purchase_order_items`

> Engine: SharedMergeTree | Rows: ~431

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `purchase_order_id` | Nullable(Int64) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `client_product_name` | Nullable(String) | |
| `uom` | Nullable(String) | Unit of measure |
| `quantity` | Nullable(Int32) | |
| `received_good_quantity` | Nullable(Int32) | |
| `received_damaged_quantity` | Nullable(Int32) | |
| `received_expired_quantity` | Nullable(Int32) | |
| `unit_price` | Nullable(Int64) | cents (use subunit) |
| `amount` | Nullable(Int64) | cents (use subunit) |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `awaiting_receipt_quantity` | Nullable(Int32) | |
| `received_quantity` | Nullable(Int32) | Virtual: received_good_quantity + received_damaged_quantity + received_expired_quantity |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_purchase_order_shipment_items`

> Engine: SharedMergeTree | Rows: ~452

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `purchase_order_shipment_id` | Nullable(Int64) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `quantity` | Nullable(Int32) | |
| `received_quantity` | Nullable(Int32) | |
| `unit_price` | Nullable(Int64) | đơn vị không rõ (có thể cents hoặc dollars — cần xác nhận) |
| `amount` | Nullable(Int64) | đơn vị không rõ (có thể cents hoặc dollars — cần xác nhận) |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `purchase_order_item_id` | Nullable(Int64) | |
| `import_tax_rate` | Nullable(Float64) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_purchase_order_shipment_receipt_items`

> Engine: SharedMergeTree | Rows: ~412

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `purchase_order_shipment_id` | Nullable(Int64) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `quantity` | Nullable(Int32) | |
| `condition_type` | Nullable(String) | good; damaged; expired; residual |
| `import_tax_rate` | Nullable(Float64) | |
| `received_quantity` | Nullable(Int32) | |
| `unit_price` | Nullable(Int64) | cents (use subunit) |
| `amount` | Nullable(Int64) | Virtual field: ceil((unit_price * quantity) * (1 + import_tax_rate)); cents |
| `is_warehouse_receivable` | Nullable(Bool) | default: true |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `purchase_order_shipment_item_id` | Nullable(Int64) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_purchase_order_shipments`

> Engine: SharedMergeTree | Rows: ~230

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `purchase_order_id` | Nullable(Int64) | |
| `po_code` | Nullable(String) | purchase order code |
| `ref_code` | Nullable(String) | |
| `invoice_number` | Nullable(String) | |
| `tracking_code` | Nullable(String) | |
| `tracking_carrier` | Nullable(String) | e.g. USPS, UPS, DHL |
| `tracking_status` | Nullable(String) | |
| `shipping_method` | Nullable(String) | e.g. sea, train |
| `container_number` | Nullable(String) | |
| `estimated_received_at` | Nullable(String) | |
| `status` | Nullable(String) | open; awaiting_receipt; received; confirmed; cancelled |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `received_at` | Nullable(String) | |
| `note` | Nullable(String) | |
| `code` | Nullable(String) | Format: [PO code]-[number] |
| `warehouse_code` | Nullable(String) | |
| `client_vendor_id` | Nullable(Int64) | |
| `client_vendor_code` | Nullable(String) | |
| `shipping_fee` | Nullable(Int64) | |
| `discount_amount` | Nullable(Int64) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_purchase_orders`

> Engine: SharedMergeTree | Rows: ~206

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | PO code, format: PO12345678 |
| `client_po_code` | Nullable(String) | |
| `ir_code` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `inserted_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `status` | Nullable(String) | draft; awaiting_approval; approved; awaiting_receipt; partially_received; completed; rejected; cancelled |
| `client_code` | Nullable(String) | |
| `client_vendor_code` | Nullable(String) | |
| `team_code` | Nullable(String) | |
| `destination_location_code` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `destination_address_1` | Nullable(String) | |
| `destination_address_2` | Nullable(String) | |
| `destination_country` | Nullable(String) | |
| `destination_division_level_1` | Nullable(String) | |
| `destination_division_level_2` | Nullable(String) | |
| `destination_zip_code` | Nullable(String) | |
| `estimated_received_at` | Nullable(String) | |
| `subtotal_amount` | Nullable(Int64) | cents (use subunit) |
| `discount_amount` | Nullable(Int64) | cents (use subunit) |
| `total_amount` | Nullable(Int64) | cents (use subunit) |
| `total_quantity` | Nullable(Int32) | |
| `total_received_quantity` | Nullable(Int32) | |
| `note` | Nullable(String) | |
| `awaiting_receipt_quantity` | Nullable(Int32) | |
| `total_shipments` | Nullable(Int32) | |
| `client_vendor_id` | Nullable(Int64) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_purchase_requisition_histories`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `purchase_requisition_id` | Int64 | |
| `pr_code` | Nullable(String) | |
| `client_code` | Nullable(String) | |
| `old_status` | Nullable(String) | |
| `new_status` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `updated_user_id` | Nullable(Int64) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_purchase_requisition_items`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int32 | PK |
| `purchase_requisition_id` | Nullable(Int64) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `client_product_name` | Nullable(String) | |
| `quantity` | Nullable(Int32) | |
| `uom` | Nullable(String) | Unit of measure |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_purchase_requisitions`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `team_code` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `client_code` | Nullable(String) | |
| `status` | Nullable(String) | |
| `note` | Nullable(String) | |
| `created_user_id` | Nullable(Int64) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_role_permissions`

> Engine: SharedMergeTree | Rows: ~114

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `role_id` | Int64 | |
| `permission_code` | String | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_roles`

> Engine: SharedMergeTree | Rows: ~7

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_shelves`

> Engine: SharedMergeTree | Rows: ~17

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `area_code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_team_locations`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | Int64 | |
| `location_code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_team_warehouses`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | Int64 | |
| `warehouse_code` | String | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_teams`

> Engine: SharedMergeTree | Rows: ~1

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `name` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_transfer_order_histories`

> Engine: SharedMergeTree | Rows: ~1,616

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int32 | PK |
| `transfer_order_id` | Int64 | |
| `tf_code` | Nullable(String) | transfer order code |
| `old_tf_status` | Nullable(String) | |
| `new_tf_status` | Nullable(String) | |
| `updated_user_id` | Nullable(Int64) | |
| `updated_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_transfer_order_item_allocations`

> Engine: SharedMergeTree | Rows: ~877

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `transfer_order_item_id` | Nullable(Int64) | |
| `cluster_code` | Nullable(String) | |
| `cluster_expired_at` | Nullable(String) | |
| `cluster_serial_number` | Nullable(String) | |
| `cluster_system_code` | Nullable(String) | |
| `transfer_order_code` | Nullable(String) | |
| `warehouse_code` | Nullable(String) | |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `bin_code` | Nullable(String) | |
| `quantity` | Nullable(Int32) | |
| `condition_type` | Nullable(String) | good / damaged / expired / lost |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_transfer_order_items`

> Engine: SharedMergeTree | Rows: ~940

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `transfer_order_id` | Nullable(Int64) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `client_product_name` | Nullable(String) | |
| `quantity` | Nullable(Int32) | |
| `uom` | Nullable(String) | Unit of measure |
| `condition_type` | Nullable(String) | good / damaged / expired / lost |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_transfer_orders`

> Engine: SharedMergeTree | Rows: ~238

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | TF code, format: TF12345678 |
| `client_id` | Nullable(Int64) | |
| `client_code` | Nullable(String) | |
| `source_warehouse_id` | Nullable(Int64) | |
| `source_warehouse_code` | Nullable(String) | |
| `destination_warehouse_id` | Nullable(Int64) | |
| `destination_warehouse_code` | Nullable(String) | |
| `status` | Nullable(String) | draft; awaiting_approval; approved; awaiting_transfer; partially_transfered; transfered; cancelled |
| `note` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `created_user_id` | Nullable(Int64) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_user_sessions`

> Engine: SharedMergeTree | Rows: 0

| Column | Type | Ghi chú |
|---|---|---|
| `token` | String | |
| `expired_at` | Nullable(String) | |
| `user_id` | Int64 | |
| `current_warehouse_code` | String | |
| `current_printer_code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_user_teams`

> Engine: SharedMergeTree | Rows: ~2

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `user_id` | Int64 | |
| `team_id` | Int64 | |
| `created_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_user_warehouse_roles`

> Engine: SharedMergeTree | Rows: ~178

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `user_warehouse_id` | Int64 | |
| `role_id` | Int64 | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_user_warehouses`

> Engine: SharedMergeTree | Rows: ~148

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `user_id` | Int64 | |
| `warehouse_code` | String | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_users`

> Engine: SharedMergeTree | Rows: ~28

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `username` | Nullable(String) | |
| `full_name` | Nullable(String) | |
| `password` | Nullable(String) | |
| `is_active` | Nullable(Bool) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `email` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_warehouse_products`

> Engine: SharedMergeTree | Rows: ~23,339

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `warehouse_code` | Nullable(String) | |
| `client_code` | Nullable(String) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `warehouse_barcode` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `width` | Nullable(Float64) | |
| `height` | Nullable(Float64) | |
| `length` | Nullable(Float64) | |
| `weight` | Nullable(Float64) | |
| `reorder_level` | Nullable(Int32) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_warehouses`

> Engine: SharedMergeTree | Rows: ~17

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `name` | Nullable(String) | |
| `address_1` | Nullable(String) | |
| `address_2` | Nullable(String) | |
| `country` | Nullable(String) | |
| `division_level_1` | Nullable(String) | |
| `division_level_2` | Nullable(String) | |
| `division_level_3` | Nullable(String) | |
| `division_level_4` | Nullable(String) | |
| `division_level_5` | Nullable(String) | |
| `zip_code` | Nullable(String) | |
| `is_active` | Nullable(Bool) | |
| `location_code` | Nullable(String) | |
| `type` | String | |
| `is_zoho_synchronizable` | Nullable(Bool) | |
| `is_crm_synchronizable` | Nullable(Bool) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_workorder_items`

> Engine: SharedMergeTree | Rows: ~7

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `workorder_id` | Int64 | |
| `workorder_code` | Nullable(String) | work order code |
| `client_code` | Nullable(String) | |
| `client_sku` | Nullable(String) | SKU phía client |
| `system_sku` | Nullable(String) | SKU hệ thống WMS |
| `client_product_name` | Nullable(String) | |
| `bin_code` | Nullable(String) | |
| `cluster_system_code` | Nullable(String) | |
| `cluster_code` | Nullable(String) | |
| `cluster_expired_at` | Nullable(String) | |
| `cluster_serial_number` | Nullable(String) | |
| `quantity` | Nullable(Int32) | |
| `packed_quantity` | Nullable(Int32) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_workorder_outbound_requests`

> Engine: SharedMergeTree | Rows: ~8

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `workorder_id` | Int64 | |
| `workorder_code` | Nullable(String) | work order code |
| `outbound_request_code` | Nullable(String) | |
| `client_or_code` | Nullable(String) | outbound request code từ phía client |
| `client_code` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

## `wms_workorders`

> Engine: SharedMergeTree | Rows: ~2

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | WO code, format: WO12345678 |
| `warehouse_code` | Nullable(String) | |
| `total_item_quantity` | Nullable(Int32) | |
| `total_outbound_requests` | Nullable(Int32) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `status` | Nullable(String) | new; ready_for_processing; processed |
| `item_picking_list_url` | Nullable(String) | |
| `outbound_request_picking_list_url` | Nullable(String) | |
| `outbound_request_list_url` | Nullable(String) | |
| `created_user_id` | Nullable(Int64) | |
| `note` | Nullable(String) | |
| `total_item_packed_quantity` | Nullable(Int32) | |
| `processable_outbound_requests` | Nullable(Int32) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

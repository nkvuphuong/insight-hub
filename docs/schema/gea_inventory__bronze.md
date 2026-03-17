# Schema: gea_inventory__bronze

**Layer:** Bronze (raw CDC)
**Last updated:** 2026-03-13
**Tables:** 2 (excl. schema_migrations)

> Inventory management — theo dõi tồn kho sản phẩm tại kho.

---

## Quick Reference

| Table | Rows | Mô tả |
|---|---|---|
| `inv_product_variant_inventory` | ~7.1K | Tồn kho theo variant & kho |
| `inv_inventory_line_commitment` | 9 | Commitments tồn kho |
| `schema_migrations` | 6 | |

---

## `inv_product_variant_inventory` 🔵

> Engine: SharedReplacingMergeTree | Rows: ~7.1K
> Dùng `FINAL` khi query để dedup. Snapshot tồn kho hiện tại theo variant.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `warehouse_code` | Nullable(String) | Mã kho |
| `product_id` | Nullable(String) | |
| `variant_id` | Nullable(String) | |
| `variant_sku` | Nullable(String) | |
| `ref_variant_sku` | Nullable(String) | |
| `variant_name` | Nullable(String) | |
| `sellable_stock` | Nullable(Int64) | Có thể bán |
| `buffer_stock` | Nullable(Int64) | Buffer dự phòng |
| `reserved_stock` | Nullable(Int64) | Đã reserve |
| `allocating_stock` | Nullable(Int64) | Đang allocate |
| `warehouse_allocated_stock` | Nullable(Int64) | WMS allocated |
| `warehouse_onhand_stock` | Nullable(Int64) | WMS onhand |
| `fulfillable_stock` | Nullable(Int64) | |
| `good_quantity` | Nullable(Int64) | Hàng tốt |
| `good_available_quantity` | Nullable(Int64) | |
| `good_allocated_quantity` | Nullable(Int64) | |
| `damaged_quantity` | Nullable(Int64) | Hàng hỏng |
| `damaged_available_quantity` | Nullable(Int64) | |
| `damaged_allocated_quantity` | Nullable(Int64) | |
| `expired_quantity` | Nullable(Int64) | Hàng hết hạn |
| `expired_available_quantity` | Nullable(Int64) | |
| `expired_allocated_quantity` | Nullable(Int64) | |
| `lost_quantity` | Nullable(Int64) | Hàng thất lạc |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## `inv_inventory_line_commitment` 🔵

> Engine: SharedReplacingMergeTree | Rows: 9
> Dùng `FINAL` khi query để dedup. Commitments tồn kho cho đơn hàng.

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `team_id` | String | |
| `order_id` | Nullable(String) | |
| `package_id` | Nullable(String) | |
| `commitment_id` | Nullable(String) | UUID |
| `warehouse_code` | Nullable(String) | |
| `variant_sku` | Nullable(String) | |
| `quantity` | Nullable(Int64) | |
| `status` | Nullable(String) | |
| `outbound_code` | Nullable(String) | |
| `created_at` | DateTime64(6,'UTC') | |
| `updated_at` | DateTime64(6,'UTC') | |
| `_processed_at` | DateTime64(3,'UTC') | |
| `_action` | String | |
| `_timestamp` | DateTime64(3,'UTC') | |

---

## Internal Tables (excluded)

**MaterializedViews (`__mv_to_latest`):** `inv_product_variant_inventory__mv_to_latest`, `inv_inventory_line_commitment__mv_to_latest`

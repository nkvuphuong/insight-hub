# ClickHouse Schema Index

> **Vai trò:** Inventory — trả lời "database/table nào tồn tại, ở đâu, file schema ở đâu".
> Đây là **điểm vào đầu tiên** khi bắt đầu viết bất kỳ query nào.
>
> **Không lưu ở đây:** sub-system meaning, entity mapping, join paths, lineage.
> → Những thứ đó nằm trong [`docs/data-map.md`](data-map.md).

**Service:** gea-data (`bf199f64-2a10-4ae7-bd03-56984eaf0158`)
**Last updated:** 2026-03-14
**Auth:** OAuth (Gmail) qua MCP — không cần credentials

---

## Hướng dẫn sử dụng

- Đọc file này **trước tiên** để xác định database/table cần dùng
- Chi tiết columns → `docs/schema/<database>.md`
- Cross-DB context (sub-systems, entity map, join paths, lineage) → [`docs/data-map.md`](data-map.md)
- Chỉ gọi MCP explore khi database chưa có file schema hoặc cần refresh
- Bỏ qua: `INFORMATION_SCHEMA`, `information_schema`, `system`, `default`, `util`

---

## Business Systems

Gearment chia data thành 4 systems độc lập + 1 Integrated layer:

| System | DB prefixes | Mô tả |
|---|---|---|
| **OMS** | `geadb__*` | Order Management System — vòng đời đơn hàng, fulfillment, tracking |
| **WMS** | `gea_wms__*` | Warehouse Management System |
| **FFM** | `gea_ffm__*` | Fulfillment operations |
| **POD** | `gea_seller__*`, `gea_iam__*`, `gea_finance__*`, `gea_store__*`, `gea_studio__*`, `gea_shipping__*`, `gea_notification__*`, `gea_integration__*`, `gea_inventory__*`, `gea_oms_integration__*` | Print-on-Demand platform |
| **Integrated** | `gea__*` (double underscore), `gea_silver`, `gea_gold`, `gea_bi_dw` | Tổng hợp từ nhiều systems + data ngoài hệ thống |
| **GMprint** | *(coming soon)* | — |

> Context đầy đủ (entity map, join paths, lineage) → [`docs/data-map.md`](data-map.md)

---

## Data Layer Architecture

```
Sources → [Bronze] → [Silver] → [Gold] → Metabase
           raw CDC     enriched   metrics
```

| Layer | Databases | Mô tả |
|---|---|---|
| Bronze | `geadb__bronze`, `gea__bronze`, `gea_ffm__bronze`, `gea_finance__bronze`, `gea_iam__bronze`, `gea_integration__bronze`, `gea_inventory__bronze`, `gea_notification__bronze`, `gea_oms_integration__bronze`, `gea_seller__bronze`, `gea_shipping__bronze`, `gea_store__bronze`, `gea_studio__bronze`, `gea_wms__bronze` | Raw CDC từ production DB |
| Silver | `geadb__silver`, `gea__silver`, `geadb__silver_staging`, `gea__silver_staging`, `gea_silver`, `gea_seller__bronze_staging` | Cleaned, enriched, fact/dim tables |
| Gold | `gea_gold` | Pre-computed metrics, views cho BI |
| DW | `gea_bi_dw` | BI Data Warehouse (hiện rỗng) |

---

## Databases — Chi tiết

### Gold Layer

| Database | Tables | File | Status |
|---|---|---|---|
| `gea_gold` | 7 | [gea_gold.md](schema/gea_gold.md) | Done |

**Tables:** dim_order_method, nextapp_order_metrics, next_app_platform_distribution, next_app_processing_time, next_app_user_activity, order_shipping_zone, v_easypost_rate_usps

**gea_silver key tables:**
- Orders enriched: `v_nh_order_enriched`, `v_sc_order_enriched` — orders + address + tracking join sẵn
- Items: `v_nh_order_item_enriched`, `v_sc_order_item_line_enriched`
- Customer: `v_nh_customer_enriched`, `v_iam_user_enriched`
- Shipping rates: `easypost_rate_usps`, `shipx_rate_usps`, `dhl_ecs_rate` (SCD Type 2)
- Shipments: `easypost_shipments` (View = CA+TX union), `easypost_shipments_ca`, `easypost_shipments_tx`
- Rate comparison: `v_shipx_rate_comparison`, `v_single_order_item_shipping_fee`
- Finance: `v_fin_deposit_request_enriched`, `v_fin_team_transaction_enriched`

---

### Silver Layer

| Database | Tables | File | Status |
|---|---|---|---|
| `geadb__silver` | 3 | [geadb__silver.md](schema/geadb__silver.md) | Done |
| `gea__silver` | 31 | [gea__silver.md](schema/gea__silver.md) | Done |
| `gea_silver` | 41 | [gea_silver.md](schema/gea_silver.md) | Done |
| `geadb__silver_staging` | 0 | — | Empty — skip |
| `gea__silver_staging` | 7 | [gea__silver_staging.md](schema/gea__silver_staging.md) | Done |

---

### Bronze Layer

| Database | Tables | File | Status |
|---|---|---|---|
| `geadb__bronze` | 59 | [geadb__bronze.md](schema/geadb__bronze.md) | Done |
| `gea__bronze` | 8+6 views | [gea__bronze.md](schema/gea__bronze.md) | Done |
| `gea_seller__bronze` | 86 | [gea_seller__bronze.md](schema/gea_seller__bronze.md) | Done |
| `gea_finance__bronze` | 20 | [gea_finance__bronze.md](schema/gea_finance__bronze.md) | Done |
| `gea_iam__bronze` | 21 | [gea_iam__bronze.md](schema/gea_iam__bronze.md) | Done |
| `gea_store__bronze` | 25 | [gea_store__bronze.md](schema/gea_store__bronze.md) | Done |
| `gea_ffm__bronze` | 12 | [gea_ffm__bronze.md](schema/gea_ffm__bronze.md) | Done |
| `gea_oms_integration__bronze` | 4 | [gea_oms_integration__bronze.md](schema/gea_oms_integration__bronze.md) | Done |
| `gea_studio__bronze` | 8 | [gea_studio__bronze.md](schema/gea_studio__bronze.md) | Done |
| `gea_notification__bronze` | 8 | [gea_notification__bronze.md](schema/gea_notification__bronze.md) | Done (all empty) |
| `gea_integration__bronze` | 2 | [gea_integration__bronze.md](schema/gea_integration__bronze.md) | Done |
| `gea_inventory__bronze` | 2 | [gea_inventory__bronze.md](schema/gea_inventory__bronze.md) | Done |
| `gea_shipping__bronze` | 3 | [gea_shipping__bronze.md](schema/gea_shipping__bronze.md) | Done |
| `gea_wms__bronze` | 60 | [gea_wms__bronze.md](schema/gea_wms__bronze.md) | Done |
| `geadb__bronze__backup` | — | — | Backup — skip |

---

## Ghi chú quan trọng

### Convention đặt tên table trong Bronze

Mỗi table thường có 3 variants:
- `<table>` — bản latest (ReplacingMergeTree, có FINAL khi query)
- `<table>__raw` — bản raw từ CDC (internal, không query trực tiếp)
- `<table>__mv_to_latest` — MaterializedView populate vào bản latest (internal)

Khi query bronze: **luôn dùng bản không có suffix** + thêm `FINAL` nếu engine là ReplacingMergeTree.

### Lưu ý về dữ liệu tài chính

Các giá trị tiền tệ (amount, fee, price) trong `gea_finance__bronze` lưu dạng **cents** (Int64) — cần chia 100 khi hiển thị.

### Entity map & Key tables

> Xem [`docs/data-map.md` — Section 2](data-map.md#section-2--business-entity--canonical-table): Bronze canonical → Silver enriched → Gold metric cho từng business entity.

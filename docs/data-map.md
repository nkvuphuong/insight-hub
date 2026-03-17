# Data Map — Cross-Database Context

> **Vai trò:** Context — trả lời "DB này là gì, entity nằm ở đâu, join bằng cột nào, Silver/Gold build từ Bronze nào".
> Đọc file này **trước khi viết cross-DB query**, sau khi đã orient bằng `docs/schema.md`.
>
> **Không lưu ở đây:** column detail (→ `docs/schema/<db>.md`), table counts/file links (→ `docs/schema.md`).
>
> **Incremental:** `?` = suspected chưa verify, trống = chưa biết. Không bịa.
>
> **Cập nhật khi:** discover join path mới → update Section 3; tìm ra lineage mới → update Section 4.
> Ghi rõ "Verified by: `<report-name> <date>`" khi đã chạy query thực tế.

---

## Section 1 — Project / Domain Map

> Gearment chia làm 4 systems độc lập + 1 Integrated layer tổng hợp:
> **OMS** · **WMS** · **FFM** · **POD** · **Integrated**
>
> **Quy tắc đặt tên DB:**
>
> - System DB: `gea_<system>__<layer>` — ví dụ `gea_seller__bronze`, `gea_wms__bronze`
> - Integrated DB: `gea__<layer>` (double underscore, không có system name) hoặc `gea_<layer>` — ví dụ `gea__bronze`, `gea_silver`, `gea_gold`


| System     | DB prefix               | Sub-system             | Viết tắt | Layer           | Mô tả                                                                 |
| ---------- | ----------------------- | ---------------------- | -------- | --------------- | --------------------------------------------------------------------- |
| OMS        | `geadb__`               | Order Management       | NH       | Bronze + Silver | OMS chính: orders, customers, shipments, tracking, products           |
| WMS        | `gea_wms__`             | Warehouse Mgmt         | WMS      | Bronze          | Inventory, outbound, picking, WMS operations                          |
| FFM        | `gea_ffm__`             | Fulfillment            | FFM      | Bronze          | Fulfillment operations                                                |
| POD        | `gea_seller__`          | Seller Center          | SC       | Bronze          | Seller-facing: đơn hàng seller gửi vào hệ thống                       |
| POD        | `gea_iam__`             | Identity & Access      | IAM      | Bronze          | Users, teams, roles, permissions                                      |
| POD        | `gea_finance__`         | Finance/Wallet         | FIN      | Bronze          | Wallet transactions, deposits, team finance                           |
| POD        | `gea_store__`           | Store Mgmt             | STORE    | Bronze          | Store data, seller stores                                             |
| POD        | `gea_studio__`          | Studio / Media         | STUDIO   | Bronze          | Media files, design assets (`stu_media`)                              |
| POD        | `gea_shipping__`        | Shipping Rates         | SHIP     | Bronze          | Carrier rate tables                                                   |
| POD        | `gea_notification__`    | Notifications          | NOTIF    | Bronze          | Notification tables (tất cả hiện rỗng)                                |
| POD        | `gea_integration__`     | Integrations           | INT      | Bronze          | Integration records                                                   |
| POD        | `gea_inventory__`       | Inventory              | INV      | Bronze          | Inventory records (2 tables)                                          |
| POD        | `gea_oms_integration__` | OMS Integration        | OMSI     | Bronze          | OMS integration bridge (4 tables)                                     |
| Integrated | `gea__`                 | Aggregation + External | —        | Bronze + Silver | Tổng hợp từ OMS/WMS/FFM/POD + data ngoài hệ thống (USPS tracking...)  |
| Integrated | `gea_silver`            | Silver enriched        | —        | Silver          | Enriched views tổng hợp từ nhiều sources (orders, customers, finance) |
| Integrated | `gea_gold`              | Gold metrics           | —        | Gold            | Pre-computed metrics tổng hợp cho Metabase                            |
| Integrated | `gea_bi_dw`             | BI Data Warehouse      | DW       | DW              | BI DW (hiện rỗng)                                                     |
| GMprint    | *(coming soon)*         | —                      | —        | —               | —                                                                     |


---

## Section 2 — Business Entity → Canonical Table

> **Status:** `confirmed` = tên table xác nhận từ schema file | `partial` = có ít nhất 1 link chưa verify


| System     | Entity                 | Bronze canonical                                      | Silver enriched                                                 | Gold metric                           | Notes                                             | Status    |
| ---------- | ---------------------- | ----------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------- | ------------------------------------------------- | --------- |
| OMS        | Order (NH)             | `geadb__bronze.nh_order`                              | `gea__silver.fact_order_v1` (~14.5M rows)                       | —                                     | `ord_id` là PK xuyên suốt; dùng FINAL             | confirmed |
| OMS        | Order fulfillment SLA  | `geadb__bronze.nh_order` + `nh_order_extra`           | `gea__silver.fact_order_fulfillment_performance` (~1.7M rows) ⭐ | —                                     | Chỉ đơn hoàn tất toàn bộ chu trình                | confirmed |
| OMS        | Order line item        | `geadb__bronze.nh_order_item`                         | `gea__silver.v__fact_order_line` (view)                         | —                                     | `ordi_id` là PK item                              | confirmed |
| OMS        | Seller / Customer (NH) | `geadb__bronze.nh_customer`                           | —                                                               | —                                     | `cus_id` là seller ID dùng xuyên suốt NH          | confirmed |
| OMS        | Shipment               | `geadb__bronze.nh_shipment` + `nh_tracking_shipments` | —                                                               | —                                     |                                                   | confirmed |
| POD        | Order (SC / Seller)    | `gea_seller__bronze.sc_order` (~949K rows)            | —                                                               | —                                     | `order_id` là UUID; cách link sang NH chưa verify | partial   |
| POD        | Team (IAM)             | `gea_iam__bronze.iam_team`                            | —                                                               | —                                     | `team_id` (UUID) = key cross-system (SC, IAM)     | confirmed |
| POD        | User (IAM)             | `gea_iam__bronze.iam_user`                            | —                                                               | —                                     | `user_id` (UUID)                                  | confirmed |
| POD        | Wallet transaction     | `gea_finance__bronze.fin_wallet_transaction`          | —                                                               | —                                     | Amounts in cents                                  | confirmed |
| Integrated | USPS tracking event    | `gea__bronze.usps_tracking_event`                     | `gea__silver.v__usps_tracking_first_scan` (view)                | —                                     | First scan per order                              | confirmed |
| OMS        | Shipping zone          | `geadb__bronze.nh_order_shipping_zone`                | —                                                               | `gea_gold.order_shipping_zone` (view) | US only, HB1/TX1                                  | confirmed |


---

## Section 3 — Cross-Database Join Paths

> Chỉ ghi join đã dùng trong query thực tế. **Không ghi khi chưa verify** — fill dần theo báo cáo mới.
> Khi verify xong: ghi "Verified by: `<report-name> <date>`".


| From                     | Column   | → To                                             | Column     | Cardinality | Verified by                  |
| ------------------------ | -------- | ------------------------------------------------ | ---------- | ----------- | ---------------------------- |
| `geadb__bronze.nh_order` | `ord_id` | `gea__silver.fact_order_fulfillment_performance` | `order_id` | 1:1         | order-performance 2026-03-14 |


---

## Section 4 — Data Lineage (Bronze → Silver → Gold)

> **Status:** `confirmed` = MV name hoặc schema comment xác nhận nguồn | `partial` = suy luận từ FK / tên bảng, đủ để tin cậy
> Chỉ ghi khi biết ít nhất 1 Bronze source cụ thể. Không ghi khi source hoàn toàn `?`.


| Silver / Gold                                    | Built from                                                        | Status    | Notes                                                                                         |
| ------------------------------------------------ | ----------------------------------------------------------------- | --------- | --------------------------------------------------------------------------------------------- |
| `gea__silver.fact_order_fulfillment_performance` | `geadb__bronze.nh_order` + `nh_order_extra`                       | confirmed | MV name `mv__fact_order_fulfillment_performance` xác nhận trong schema                        |
| `gea__silver.v__fact_order_line`                 | `geadb__bronze.nh_order_item` + `nh_order`                        | confirmed | FK columns xác nhận trong schema: `item_id = nh_order_item.ordi_id`, `order_id FK → nh_order` |
| `gea_gold.order_shipping_zone`                   | `geadb__bronze.nh_order` + `nh_order_extra` + `nh_shipping_zones` | confirmed | Schema comment ghi rõ nguồn (US only, HB1/TX1)                                                |



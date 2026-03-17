# Schema: gea_silver

**Layer:** Silver (enriched views + shipping data)
**Last updated:** 2026-03-14
**Total tables:** 41 (12 MergeTree/Replacing + 22 Views + 7 MaterializedViews)

---

## Tổng quan domain

| Domain | Tables | Ghi chú |
|---|---|---|
| **Enriched Views (NH)** | v_nh_order_enriched, v_nh_order_item_enriched, v_nh_customer_enriched, v_nh_campaigns_enriched, v_nh_image_design_enriched, v_nh_store_integrations_enriched, v_nh_topup_payment_enriched, v_nh_transaction_enriched | Orders/customers đã join sẵn từ geadb__bronze |
| **Enriched Views (SC)** | v_sc_order_enriched, v_sc_order_item_line_enriched, v_sc_seller_product_enriched, v_sc_store_enriched | Seller channel orders |
| **Enriched Views (Finance/IAM)** | v_fin_deposit_request_enriched, v_fin_team_transaction_enriched, v_iam_user_enriched, v_stu_media_enriched | Finance + user identity |
| **Shipping Rates** | easypost_rate_usps, easypost_rate_usps_california, easypost_rate_usps_texas, shipx_rate_usps, dhl_ecs_rate | Rate cards theo service/zone/weight |
| **Shipments** | easypost_shipments, easypost_shipments_ca, easypost_shipments_tx, easypost_shipment_invoices, easypost_shipment_invoices_ca | Actual shipment records |
| **Shipping Allocation** | domestic_shipping_allocation_daily_mv, v_domestic_shipping_allocation, v_domestic_shipping_allocation_daily | Phân bổ shipping zone theo ngày |
| **Shipping Analysis** | v_shipx_rate_comparison, v_single_order_item_shipping_fee | So sánh rates, tính fee per order |
| **SLA** | fact_production_order_sla_tracker | Production SLA tracking |
| **Product Catalog** | swift_pod_catalogs | POD product catalog |
| **Internal (skip)** | mv_*, orders_migration_diff_v | MVs internal + migration diff |

---

## Convention

- **mv_*** : MaterializedViews internal, populate vào bảng chính — **không query trực tiếp**
- **v_*** : Views — query được, nhưng là live query (không có index)
- **_legacy_seller_id** : Foreign key chính để join với seller/user data
- **Amounts** trong enriched views (v_nh_*, v_sc_*, v_fin_*): đơn vị **cents** (Int32/Int64) — chia 100 khi hiển thị
- **easypost_shipments** (View) = UNION của _ca + _tx — dùng bản này để query tổng hợp

---

## Enriched Views — NH Channel

### v_nh_order_enriched
**Engine:** View | **Mô tả:** Orders NH đã enrich — join order + address + tracking sẵn

| Column | Type | Mô tả |
|---|---|---|
| _order_id | Nullable(Int32) | Order ID (FK) |
| _legacy_seller_id | Nullable(Int32) | Seller ID |
| _shipping_fee | Nullable(Int32) | Shipping fee (cents) |
| _tax | Nullable(Int32) | Tax (cents) |
| _handle_fee | Nullable(Int32) | Handle fee (cents) |
| _payment_status | Nullable(String) | Trạng thái thanh toán |
| _created_at | Nullable(DateTime64(6, LA)) | Thời điểm tạo (PST/LA timezone) |
| _created_date | Nullable(DateTime64(6, LA)) | Ngày tạo |
| _payment_date | Nullable(Date) | Ngày thanh toán |
| _status | Nullable(String) | Trạng thái đơn hàng |
| _total | Nullable(Int32) | Tổng tiền (cents) |
| _subtotal | Nullable(Int32) | Subtotal (cents) |
| _shipping_method | Nullable(String) | Phương thức vận chuyển |
| _platform_ref | Nullable(String) | Mã đơn hàng từ platform gốc |
| _created_method | Nullable(String) | Kênh tạo đơn |
| _approved_at | Nullable(DateTime64(6, LA)) | Thời điểm approve |
| _priority | Nullable(String) | Priority level |
| _oa_email | Nullable(String) | Email người nhận |
| _oa_name | Nullable(String) | Tên người nhận |
| _oa_company | Nullable(String) | Công ty người nhận |
| _oa_phone_number | Nullable(String) | SĐT người nhận |
| _oa_address1 | Nullable(String) | Địa chỉ 1 |
| _oa_address2 | Nullable(String) | Địa chỉ 2 |
| _oa_country_id | Nullable(String) | Mã quốc gia |
| _oa_city | Nullable(String) | Thành phố |
| _oa_state | Nullable(String) | Bang/tỉnh |
| _oa_zipcode | Nullable(String) | Zip code người nhận |
| _txn_id | Nullable(String) | Transaction ID |
| _tracking_no | Nullable(String) | Tracking number |

---

### v_nh_order_item_enriched
**Engine:** View | **Mô tả:** Order items NH đã enrich

| Column | Type | Mô tả |
|---|---|---|
| _legacy_item_id | Nullable(UInt32) | Item ID |
| _legacy_seller_id | Nullable(UInt32) | Seller ID |
| _order_id | Nullable(Int32) | Order ID (FK) |
| _variant_attr | Nullable(String) | Variant attributes (size, color...) |
| _item_price | Nullable(Int32) | Đơn giá (cents) |
| _quantity | Nullable(UInt32) | Số lượng |
| _subtotal | Nullable(Int32) | Subtotal (cents) |
| _total | Nullable(Int32) | Tổng (cents) |
| _created_at | Nullable(DateTime, LA) | Thời điểm tạo |
| _created_date | Nullable(Date) | Ngày tạo |
| _product_id | Nullable(UInt32) | Product ID |
| _variant_id | Nullable(UInt32) | Variant ID |
| _printing_option | Nullable(String) | Loại in (front, back, both...) |
| fulfillment_options | Nullable(String) | Fulfillment options |

---

### v_nh_customer_enriched
**Engine:** View | **Mô tả:** Customer/seller NH đã enrich — thông tin account + balance

| Column | Type | Mô tả |
|---|---|---|
| _legacy_seller_id | Nullable(UInt32) | Seller ID |
| _gm_email | Nullable(String) | Email GM |
| _gm_user_name | Nullable(String) | Username GM |
| _legacy_code | Nullable(String) | Code legacy |
| _legacy_primary_id | Nullable(UInt32) | Primary ID legacy |
| _data | Nullable(String) | Extra data (JSON) |
| _balance | Nullable(Int32) | Số dư ví (cents) |
| _tier_id | Nullable(String) | Tier/level khách hàng |
| _teams | Nullable(UInt64) | Số teams |

---

### v_nh_campaigns_enriched
**Engine:** View | **Mô tả:** Campaigns/products NH

| Column | Type | Mô tả |
|---|---|---|
| _legacy_cam_id | Nullable(UInt32) | Campaign ID |
| _legacy_seller_id | Nullable(UInt32) | Seller ID |
| _product_name | Nullable(String) | Tên sản phẩm |
| _legacy_sku | Nullable(String) | SKU |
| _printing_option | Nullable(String) | Loại in |
| _price | Nullable(Int32) | Giá (cents) |

---

### v_nh_store_integrations_enriched
**Engine:** View | **Mô tả:** Store integrations (Shopify, Etsy...) của seller

| Column | Type | Mô tả |
|---|---|---|
| _legacy_store_id | Nullable(UInt32) | Store ID |
| _legacy_seller_id | Nullable(UInt32) | Seller ID |
| _platform | Nullable(String) | Platform (shopify, etsy, woocommerce...) |
| _name | Nullable(String) | Tên store |
| _status | Nullable(UInt8) | Trạng thái |
| _should_auto_sync_orders | Nullable(Bool) | Auto sync orders |
| _should_notify_shipment | Nullable(Bool) | Notify shipment |
| _should_pull_only_paid_order | Nullable(Bool) | Chỉ pull paid orders |
| _number_config | Nullable(UInt64) | Số config |

---

### v_nh_topup_payment_enriched / v_nh_transaction_enriched
**Engine:** View | **Mô tả:** Topup và transactions NH

| Column | Type | Mô tả |
|---|---|---|
| _legacy_seller_id | Nullable(Int32) | Seller ID |
| _txn_id | Nullable(String) | Transaction ID |
| _amount | Nullable(Int64/Int32) | Số tiền (cents) |
| _status | Nullable(String) | Trạng thái |
| _method_code | Nullable(String) | Phương thức thanh toán |
| _type | Nullable(String) | Loại giao dịch |
| _created_at | Nullable(DateTime, UTC) | Thời điểm tạo |

---

### v_nh_image_design_enriched
**Engine:** View | **Mô tả:** Số lượng designs per seller

| Column | Type |
|---|---|
| _legacy_seller_id | Nullable(UInt32) |
| _cnt | Nullable(UInt64) |

---

## Enriched Views — SC Channel (Seller Channel)

### v_sc_order_enriched
**Engine:** View | **Mô tả:** Orders SC — cùng structure với v_nh_order_enriched nhưng cho seller channel. Amounts là Int64.

Columns giống `v_nh_order_enriched`, khác:
- `_legacy_seller_id`: Nullable(UInt64)
- `_shipping_fee`, `_tax`, `_handle_fee`, `_total`, `_subtotal`: Nullable(Int64) thay vì Int32

---

### v_sc_order_item_line_enriched
**Engine:** View | **Mô tả:** Order items SC

Columns giống `v_nh_order_item_enriched`, thêm `_fulfillment_options` (thay vì `fulfillment_options`).

---

### v_sc_seller_product_enriched
**Engine:** View | **Mô tả:** Products của seller SC

| Column | Type |
|---|---|
| _legacy_cam_id | Nullable(Int64) |
| _legacy_seller_id | Nullable(UInt64) |
| _product_name | Nullable(String) |
| _legacy_sku | Nullable(String) |
| _printing_option | Nullable(String) |
| _price | Nullable(Int64) |

---

### v_sc_store_enriched
**Engine:** View | **Mô tả:** Stores SC (cùng structure với v_nh_store_integrations_enriched, amounts là Int64)

---

## Enriched Views — Finance & IAM

### v_fin_deposit_request_enriched / v_fin_team_transaction_enriched
**Engine:** View | **Mô tả:** Finance transactions đã enrich. Xem gea_finance__bronze để biết nguồn.

Key columns: `_legacy_seller_id`, `_txn_id`, `_amount` (cents), `_status`, `_method_code`, `_created_at`

---

### v_iam_user_enriched
**Engine:** View | **Mô tả:** User/seller identity enriched (IAM layer)

| Column | Type |
|---|---|
| _legacy_seller_id | Nullable(Int32) |
| _gm_email | Nullable(String) |
| _gm_user_name | Nullable(String) |
| _balance | Nullable(Int64) |
| _tier_id | Nullable(String) |
| _teams | Nullable(UInt64) |

---

### v_stu_media_enriched
**Engine:** View | **Mô tả:** Số lượng media assets per seller

| Column | Type |
|---|---|
| _legacy_seller_id | Nullable(UInt64) |
| _cnt | Nullable(UInt64) |

---

## Shipping Rates

### easypost_rate_usps / easypost_rate_usps_california / easypost_rate_usps_texas
**Engine:** SharedMergeTree | **Sort:** service, zone, weight
**Rows:** ~14k (main), ~7k (CA), ~7k (TX)
**Mô tả:** Rate card USPS từ EasyPost theo warehouse location

| Column | Type | Mô tả |
|---|---|---|
| carrier | String | Carrier (USPS) |
| service | String | Service type (Priority, Ground...) |
| domestic_international | String | domestic/international |
| zone | Int64 | Shipping zone |
| country | String | Mã quốc gia |
| weight | Int64 | Cân nặng (oz) |
| rate | Float64 | Giá (USD) |
| currency | String | Đơn vị tiền tệ |
| delivery_days | Int64 | Số ngày giao |
| collected_at | DateTime64(9) | Thời điểm collect rate |
| zone_type | String | Loại zone |
| location | String | Warehouse location (CA/TX) |
| SurrogateKey, CurrentFlag, DeletedFlag | SCD fields | Slowly Changing Dimension fields |
| EffectiveFromDate, EffectiveToDate | DateTime | Khoảng thời gian hiệu lực |

> **Note:** Dùng `WHERE CurrentFlag = 'Y' AND DeletedFlag = 'N'` để lấy rate hiện tại.

---

### shipx_rate_usps
**Engine:** SharedMergeTree | **Sort:** service, zone, weight | **Rows:** 6,163
**Mô tả:** Rate card USPS từ ShipX (nhà vận chuyển thay thế). Cùng schema với easypost_rate_usps.

---

### dhl_ecs_rate
**Engine:** SharedMergeTree | **Sort:** service, zone, weight | **Rows:** 83,300
**Mô tả:** Rate card DHL ECS (cho international). Cùng schema, thêm `zone_type` để phân biệt loại zone.

---

## Shipments

### easypost_shipments
**Engine:** View (= UNION của _ca + _tx) | **Mô tả:** Tất cả shipments từ EasyPost

### easypost_shipments_ca / easypost_shipments_tx
**Engine:** SharedMergeTree | **Rows:** ~36k (CA), ~33k (TX)
**Mô tả:** Actual shipment records theo warehouse

| Column | Type | Mô tả |
|---|---|---|
| PK | DateTime | Primary key (timestamp) |
| id | String | EasyPost shipment ID |
| tracking_code | String | Tracking number |
| status | String | Trạng thái shipment |
| from_zip | String | Zip kho gửi |
| from_state | String | Bang kho gửi |
| to_zip | String | Zip người nhận |
| to_state | String | Bang người nhận |
| weight | Float64 | Cân nặng (oz) |
| length/width/height | Float64 | Kích thước (in) |
| service | String | USPS service type |
| carrier | String | Carrier |
| rate | Float64 | Rate đã dùng (USD) |
| postage_fee | Float64 | Phí thực tế (USD) |
| usps_zone | Float64 | Zone USPS |
| postage_label_created_at | DateTime | Thời điểm tạo label |
| refund_status | String | Trạng thái refund |
| location | String | Warehouse location |
| report_period_start/end | Date | Kỳ báo cáo |

---

### easypost_shipment_invoices / easypost_shipment_invoices_ca
**Engine:** SharedMergeTree | **Rows:** 822 (main), 12 (CA)
**Mô tả:** Invoice điều chỉnh từ EasyPost (khi cân thực tế khác cân khai báo)

Key columns: `shipment_id`, `tracking_code`, `status`, `quoted_amount`, `final_invoice_amount`, `adjustment_amount`, `adjustment_reason`, `captured_weight` vs `claimed_weight`

---

## Shipping Allocation

### domestic_shipping_allocation_daily_mv
**Engine:** SharedReplacingMergeTree | **Rows:** 993,760 | **Sort:** paid_date, product_type, from_state, to_state, shipping_zone
**Mô tả:** Phân bổ đơn hàng theo ngày/zone/state (bảng aggregate)

| Column | Type | Mô tả |
|---|---|---|
| paid_date | Date | Ngày thanh toán |
| product_type | String | Loại sản phẩm |
| from_state | String | Bang kho gửi |
| to_state | String | Bang nhận |
| shipping_zone | UInt32 | Zone vận chuyển |
| orders | UInt64 | Số đơn |

---

### v_domestic_shipping_allocation
**Engine:** View | **Mô tả:** View tổng hợp phân bổ shipping có thêm period/title grouping

| Column | Type | Mô tả |
|---|---|---|
| _date | Date | Ngày |
| _period | String | Period (daily/weekly/monthly) |
| _title | String | Label hiển thị |
| _facility | Nullable(String) | Warehouse facility |
| _product_type | Nullable(String) | Loại sản phẩm |
| _zone | Int8 | Shipping zone |
| _orders | UInt64 | Số đơn |
| _ratio | Float64 | Tỷ lệ % |

---

## Shipping Analysis

### v_shipx_rate_comparison
**Engine:** View | **Mô tả:** So sánh rates giữa ShipX, EasyPost CA/TX, DHL ECS

| Column | Type | Mô tả |
|---|---|---|
| _carrier | String | Carrier |
| _service | String | Service |
| _zone | Int64 | Zone |
| _weight | Int64 | Cân nặng (oz) |
| _shipx_rate | Decimal(9,2) | Rate ShipX |
| _shipx_rate_with_deal | Decimal(9,2) | Rate ShipX sau deal |
| _easypost_ca_rate | Decimal(9,2) | Rate EasyPost CA |
| _easypost_tx_rate | Decimal(9,2) | Rate EasyPost TX |
| _dhlecs_rate | Decimal(9,2) | Rate DHL ECS |
| _easypost_ca_diff | Decimal(9,2) | Chênh lệch vs EasyPost CA |
| _easypost_tx_diff | Decimal(9,2) | Chênh lệch vs EasyPost TX |
| _dhlecs_diff | Decimal(9,2) | Chênh lệch vs DHL ECS |

---

### v_single_order_item_shipping_fee
**Engine:** View | **Mô tả:** Tính shipping fee cho từng order (1 item)

| Column | Type | Mô tả |
|---|---|---|
| _order_id | Int32 | Order ID |
| _created_at | DateTime | Thời điểm tạo |
| _product_group | Nullable(String) | Nhóm sản phẩm |
| _product_sku | Nullable(String) | SKU |
| _size | String | Size |
| _shipping_zone | Int64 | Zone vận chuyển |
| _qty | Int32 | Số lượng |
| _weight | Int64 | Cân nặng (oz) |
| _shipping_scope | String | domestic/international |
| _shipping_class | String | Class |
| _usps_shipping_service | String | USPS service type |
| _shipping_fee | Float32 | Phí vận chuyển (USD) |

---

## SLA Tracking

### fact_production_order_sla_tracker
**Engine:** SharedMergeTree | **Rows:** 0 (hiện rỗng) | **Sort:** fulfill_location, priority_level
**Mô tả:** Tracking SLA production orders

Key columns: `order_id`, `fulfill_location`, `order_type`, `payment_date_local`, `production_start_at`, `SLA`, `WP` (work in progress?), `priority_score`, `priority_level`, `today_date_pst`, timestamps UTC/PST/CST

---

## Product Catalog

### swift_pod_catalogs
**Engine:** SharedMergeTree | **Rows:** 5,621 | **Sort:** name, color, style, size
**Mô tả:** Catalog sản phẩm POD từ Swift

Key columns: `id`, `name`, `sku`, `color`, `style`, `size`, `brand`, `blank_price`, `stock`, `status`, `catalog_id`, print area placements (front/back/sleeve/neck dimensions + print prices)

---

## Ghi Chú Quan Trọng

### Enriched Views Pattern
Các view `v_nh_*` và `v_sc_*` là **live views** — join từ bronze tables. Không cache, query nặng với bảng lớn sẽ chậm. Prefer query trực tiếp bronze nếu cần performance.

### SCD (Slowly Changing Dimension) cho Rate Tables
Rate tables (`easypost_rate_usps`, `shipx_rate_usps`, `dhl_ecs_rate`) dùng SCD Type 2:
```sql
WHERE CurrentFlag = 'Y' AND DeletedFlag = 'N'
-- Hoặc lấy rate theo thời điểm cụ thể:
WHERE EffectiveFromDate <= toDateTime('2025-01-01') AND EffectiveToDate > toDateTime('2025-01-01')
```

### NH vs SC Channel
- **NH** (NightHawk): Platform chính — v_nh_*
- **SC** (Seller Channel): Shopify/Etsy integration — v_sc_*
- Cả hai dùng `_legacy_seller_id` để join, nhưng type khác: NH là Int32/UInt32, SC là UInt64/Int64

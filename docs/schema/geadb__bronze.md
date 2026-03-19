# Schema: geadb__bronze

**Layer:** Bronze (raw CDC từ production OMS database)
**Last updated:** 2026-03-19
**Tables:** 64 (bao gồm internal variants)
**Main tables:** 61 (trừ `schema_migrations`)

> **Convention:** mỗi table có 3 variants: `<table>` (query trực tiếp + FINAL), `<table>__raw` (CDC raw, không query), `<table>__mv_to_latest` (MaterializedView populate vào latest, không query). Chỉ document main tables ở đây.
>
> **Lưu ý khi query:** Tất cả main tables dùng `SharedReplacingMergeTree` → **luôn thêm `FINAL`** để dedup.
>
> **CDC metadata columns** (có trên hầu hết tables):
> - `_processed_at` `DateTime64(3,'UTC')` — thời điểm CDC ingest vào ClickHouse
> - `_action` `String` — CDC action: `insert` / `update` / `delete`
> - `_timestamp` `DateTime64(3,'UTC')` — timestamp từ CDC event

---

## Quick Reference — Tables theo nhóm

### Nhóm Dictionaries (không có FINAL, không có CDC metadata)
- `dict_attribute` — Dictionary lookup: attribute ID → quantity
- `dict_exproduct` — Dictionary lookup: external product ID → name, SKU

### Nhóm Orders (core)
- `nh_order` — Main orders (~14.6M rows) ⭐
- `nh_order_activities` — Order activity log (~110.6M rows)
- `nh_order_barcode_file` — Barcode files per order (~1.95M rows)
- `nh_order_extend` — Order gift message extension (~4.4M rows)
- `nh_order_extra` — Order extra info: tracking, fulfill location (~14.7M rows) ⭐
- `nh_order_extra_fee` — Extra fees per order (~8.1M rows)
- `nh_order_item` — Order line items (~17M rows) ⭐
- `nh_order_note` — Order notes (~383K rows)
- `nh_order_print_type` — Print type per order (~2.2M rows)
- `nh_order_refund` — Refunds (~150K rows)
- `nh_order_shipping_zone` — Shipping zone per order (~11.7M rows)
- `nh_order_source` — Order source: platform, method (~14.7M rows)
- `nh_order_weight` — Order weight (~11.1M rows)
- `nh_rush_order_data` — Rush order tracking (~352K rows)

### Nhóm Shipment & Tracking
- `nh_shipment` — Shipments (~8.7M rows)
- `nh_shipment_management` — Shipment management / carrier links (~7.6M rows)
- `nh_scanning_label_orders` — Scanning labels (~1.96M rows)
- `nh_tracking_shipments` — Tracking records (~10.2M rows)
- `nh_tracking_shipment_events` — Tracking events (0 rows — empty)
- `v_nh_tracking_shipments` — View: latest tracking (no FINAL needed, ~10.1M rows)
- `nh_reality_tracking` — Carrier billing reality check: actual vs billed weight, charges (~8.1M rows)

### Nhóm Products & Campaigns
- `nh_campaigns` — Campaigns (~3.5M rows)
- `nh_exproduct` — External products (~205 rows)
- `nh_exproduct_library` — Product library entries (~127 rows)
- `nh_product_campaigns` — Product variants per campaign (~387K rows)
- `nh_product_configurations` — Product print configurations (~379 rows)
- `nh_product_group` — Product groups/categories (~56 rows)
- `nh_product_print_location` — Print locations (~10 rows)
- `nh_product_type` — Product types (~22 rows)
- `nh_item_print_location` — Print location per order item (~1.6M rows)
- `nh_image_design` — Design images (~5.9M rows)
- `nh_variants` — Product variants (~16.1K rows)
- `nh_attribute` — Attributes (~637 rows)

### Nhóm Customers & Sellers
- `nh_customer` — Customers/sellers (~18K rows)
- `nh_customer_api` — Customer API keys (~1.3K rows)
- `nh_customer_mockup` — Customer mockups (~3.2K rows)
- `nh_customer_profile` — Customer profiles (~446 rows)
- `nh_customer_shipping_carrier` — Carrier preferences (~233 rows)
- `nh_payment_account` — Payment accounts (~29.9K rows)
- `nh_topup_payment` — Top-up payments (~85.9K rows)
- `nh_transaction` — Financial transactions (~2M rows)
- `nh_user` — Internal users/staff (~351 rows)
- `nh_user_label` — User label configs (~6.6K rows)

### Nhóm Stores & Integrations
- `nh_store_integrations` — Store integrations: Shopify, Etsy, etc. (~16.8K rows)
- `nh_store_integrations_config` — Store integration tokens (~2.5K rows)
- `nh_webhooks` — Webhooks (~1.2K rows)

### Nhóm Reference / Lookup
- `nh_blacklist_address` — Blacklisted addresses (~28 rows)
- `nh_city` — Cities (~4.2K rows)
- `nh_commit_logs` — Commit logs (~262 rows)
- `nh_conf_settings` — Configuration settings (~467 rows)
- `nh_creation_methods` — Lookup: cách tạo order (Manual, Import, Sync, API) (4 rows)
- `nh_platforms` — Lookup: platform name (Gearment, Amazon, Etsy, Shopify...) (15 rows)
- `nh_conf_settings_titles` — Config setting titles (~7 rows)
- `nh_country` — Countries (~249 rows)
- `nh_gift_message_config` — Gift message configs (~1.8K rows)
- `nh_material` — Materials (~12 rows)
- `nh_print_type` — Print types (~24 rows)
- `nh_shipping_profiles` — Shipping profiles (~17 rows)
- `nh_shipping_zones` — Lookup: zipcode range → zone by country (~2.8K rows)
- `nh_size_guide` — Size guides (~15 rows)
- `nh_state` — States/provinces (~84 rows)

---

## Tables (chi tiết)

> ⭐ = Tables thường dùng trong báo cáo
> 🔄 = SharedReplacingMergeTree (cần FINAL)
> 🔵 = SharedMergeTree / Dictionary (không cần FINAL)

---

### `dict_attribute` 🔵
> Engine: Dictionary | Rows: -
> Lookup table: attribute ID → quantity

| Column | Type | Ghi chú |
|---|---|---|
| attr_id | UInt64 | PK |
| attr_quantity | Float64 | |

---

### `dict_exproduct` 🔵
> Engine: Dictionary | Rows: -
> Lookup table: external product info

| Column | Type | Ghi chú |
|---|---|---|
| exp_id | UInt64 | PK |
| exp_name | String | tên sản phẩm |
| exp_sku | String | SKU |

---

### `nh_attribute` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~637
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| attr_id | Int64 | PK |
| attr_name | String | |
| group_id | Int64 | |
| group_type | Int64 | |
| attr_value | String | |
| attr_quantity | Int16 | Số lượng Unit |
| attr_value_special | Nullable(String) | Color special for exproduct |
| attr_mockup_special | Nullable(String) | Mockup special |
| attr_price | String | Giá này chỉ áp dụng cho size |
| attr_description | String | |
| attr_image | Nullable(String) | |
| attr_time | Int64 | |
| attr_time_update | Int64 | |
| attr_status | Int16 | |
| attr_deleted | Int16 | |
| attr_order | Int64 | |
| attr_code | Nullable(String) | Dùng cho color |
| attr_updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_blacklist_address` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~28
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| ba_id | Int64 | PK |
| ba_shipping_name | Nullable(String) | |
| ba_email | Nullable(String) | |
| ba_phone | Nullable(String) | |
| ba_address | Nullable(String) | |
| ba_address2 | Nullable(String) | |
| ba_city | String | |
| ba_state | String | |
| ba_zip | String | |
| ba_country | Int64 | FK → nh_country |
| ba_time | Int64 | |
| ba_deleted | Int16 | |
| ba_type | Int16 | 0=scan trademark; 1=verify address |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_campaigns` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~3.5M
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| cam_id | Int64 | PK |
| cam_name | String | |
| cam_description | String | |
| cam_number_date | Int64 | Số ngày chiến dịch |
| cam_is_restart | Int16 | Tự động restart chiến dịch |
| cam_is_private | Int16 | Chọn làm private (Không search được) |
| cam_is_default | Int16 | Dùng cấu hình mặc định |
| cam_display_countdown | Int16 | |
| cam_display_homepage | Int16 | |
| member_id | Int64 | FK → nh_customer (id KH) |
| sales_goal | Int64 | Số mục tiêu bán hàng — chỉ để hiển thị |
| append_producttype | Int16 | 1=Append product type to product title |
| cam_spin | Nullable(String) | |
| upsell_discount | Decimal(20,0) | Giá discount dùng cho upsell. Đơn vị $ |
| cam_time_end | Int64 | Thời gian kết thúc chiến dịch |
| cam_time | DateTime | Thời gian tạo |
| cam_datetime | Int64 | Time create date 00:00 |
| cam_time_update | Int64 | Thời gian update thông tin |
| cam_show_info | Int16 | Hiển thị mục tiêu và số lượng bán trên trang chiến dịch |
| cam_status | Int16 | 0=ended; 1=active; 2=declined; 3=processing |
| pcam_id_default | Int64 | ID sản phẩm dùng làm hiển thị mặc định |
| attr_id_default | Int64 | ID thuộc tính màu mặc định |
| is_front_default | Int16 | 1=trước; 0=sau |
| facebook_pixel | Nullable(String) | |
| custom_audience | Nullable(String) | |
| perfect_audience | Nullable(String) | |
| google_analytics_id | Nullable(String) | |
| cam_url | String | URL campaigns |
| cam_deleted | Int16 | |
| cam_archived | Int16 | |
| cam_profit | Float32 | Lợi nhuận |
| cam_sold | Int64 | Số lượng đã bán |
| cam_stats_show | Int16 | Hiển thị trang stats |
| store_list | String | Danh sách store mà campaign thuộc |
| cam_view | Int64 | |
| is_sync | Int16 | 0=chưa sync; 1=đã sync |
| collection_id | String | |
| list_pcam_id | String | |
| tags_list | String | List ID tags |
| cam_type | Int16 | 0=campaign up hình design; 1=campaign up hình render |
| zone_id | String | Mã vùng vận chuyển |
| token | String | Token image |
| img_default_front | Int64 | ID hình mặc định mặt trước |
| img_default_back | Int64 | Hình mặc định mặt sau |
| token_key | Nullable(String) | |
| cam_type_group | Int16 | 1=Combine product; 2=Split product |
| store_id | Int64 | FK → nh_store_integrations (id store mặc định dùng cho sync product) |
| cam_sync | Int16 | 0=không sync; 1=pending sync; 2=processing sync; 3=done |
| platform_id | Int16 | 1=shopify; 2=woo |
| is_customize_text | Int16 | |
| customize_text_id_front | Int64 | |
| customize_text_id_back | Int64 | |
| variant_number | Int64 | Tổng số variant của campaign |
| sync_tmp | Int16 | 0=Pending; 1=Processing; 2=Complete |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_city` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~4.2K
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| city_id | Int64 | PK |
| city_name | String | |
| country_id | Int64 | FK → nh_country |
| city_type | String | |
| city_updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_commit_logs` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~262
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| cml_id | Int64 | PK |
| cml_module | String | |
| cml_module_id | Int64 | |
| cml_title | Nullable(String) | |
| cml_note | Nullable(String) | |
| cml_status | UInt16 | 0=Pending; 1=Approved; 2=Cancelled |
| cml_content | String | |
| user_id | UInt64 | FK → nh_user |
| cml_deleted | Int16 | |
| cml_created_at | DateTime64(0,'UTC') | |
| cml_updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_creation_methods` 🔄
> Engine: SharedReplacingMergeTree | Rows: 4
> **Cần FINAL khi query**
> Lookup table: cách tạo order — Manual (1), Import (2), Sync (3), API (4)

| Column | Type | Ghi chú |
|---|---|---|
| cme_id | UInt16 | PK |
| cme_name | String | Manual / Import / Sync / API |
| created_at | DateTime64(0, 'UTC') | |
| updated_at | DateTime64(0, 'UTC') | |
| _processed_at | DateTime64(3, 'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3, 'UTC') | |

---

### `nh_conf_settings` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~467
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| conf_id | Int64 | PK |
| conf_title | String | |
| conf_key | String | |
| conf_data | Nullable(String) | |
| conf_value | Nullable(String) | |
| conf_group | Int64 | |
| conf_type | String | |
| conf_order | Int64 | |
| conf_protected | Int16 | |
| conf_description | Nullable(String) | |
| conf_lisence | Nullable(String) | |
| conf_expried | Int64 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_conf_settings_titles` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~7
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| conf_id | Int64 | PK |
| conf_title | Nullable(String) | |
| conf_key | Nullable(String) | |
| conf_protected | Int16 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_country` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~249
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| country_id | Int64 | PK |
| country_iso_code | String | e.g. 'US', 'CA' |
| country_name | String | |
| country_sort | Int64 | |
| country_area_code | Nullable(String) | Khu vực (us, eu v.v..) |
| ctry_shipping_suspended | Int16 | Đánh dấu các quốc gia bị suspend vận chuyển |
| country_ioss_required | Int16 | EU IOSS |
| country_tax | Float32 | |
| country_updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_customer` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~18K
> **Cần FINAL khi query**
> Bảng sellers/customers chính — `cus_id` là seller ID dùng xuyên suốt hệ thống

| Column | Type | Ghi chú |
|---|---|---|
| cus_id | Int64 | PK ⭐ seller ID |
| cus_code | Nullable(String) | |
| cus_time | DateTime | created at |
| cus_deleted | Int16 | |
| cus_full_name | String | |
| cus_first_name | String | |
| cus_last_name | String | |
| cus_email | String | ⭐ |
| cus_email_google | Nullable(String) | |
| cus_email_facebook | Nullable(String) | |
| cus_phone | String | |
| cus_company | String | |
| cus_type | String | |
| cus_primary_id | Int64 | |
| cus_address | String | |
| cus_address2 | String | |
| cus_city | String | |
| cus_state | Nullable(String) | State |
| cus_country | String | |
| cus_zip | String | |
| cus_postalcode | String | |
| cus_tax_code | String | |
| cus_group | String | |
| cus_sex | String | |
| cus_birthday | Nullable(Int64) | |
| cus_total_spend | Decimal(20,2) | Tổng chi tiêu |
| cus_total_order | Int64 | Tổng đơn hàng |
| cus_balance | Decimal(20,2) | Balance Wallet |
| cus_balance_rewards | Decimal(20,2) | Balance rewards |
| cus_profit | Decimal(20,2) | Total profit |
| cus_level | Int16 | Reseller Level |
| cus_tier_level | Int16 | 0=Sale price; 1=Sale price old; 2=Silver; 3=Gold; 4=30k; 5=50k |
| cus_status | Int16 | 0=chưa kích hoạt; 1=đã kích hoạt; 2=đã khoá |
| is_whitelist | Int16 | 0=Not in whitelist; 1=in whitelist for scan trademark |
| cus_enable_paypal_fee | Int16 | |
| cus_mass_payment | Int16 | |
| cus_instant_paypal | Int16 | Cho phép customer dùng phương thức thanh toán paypal instant |
| cus_prevent_payment | Int16 | |
| active_wallet | Int16 | 1=Actived Wallet |
| active_platform | Int16 | 0=chưa active; 1=đã active |
| allow_label_order | Int16 | 0=not allow; 1=allow |
| cus_sell_on | Nullable(String) | 1=marketplace; 2=platform; 3=others |
| cus_email_verification | Int16 | 0=unverified; 1=verified |
| cus_connected_facebook | Int16 | 0=not connected; 1=connected |
| cus_facebook_id | Nullable(String) | |
| cus_connected_google | Int16 | 0=not connected; 1=connected |
| cus_last_login_at | Nullable(DateTime64(0,'UTC')) | |
| cus_updated_at | DateTime64(0,'UTC') | |
| cus_internal | Int16 | 0=normal seller; 1=GM staff |
| cus_login_method | Int16 | 0=Login check session; 1=Login check token |
| cus_app_version | String | Determine the application version seller registered (account/portal_app/next_app) |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_customer_api` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~1.3K
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| cusapi_id | Int64 | PK |
| cus_id | Int64 | FK → nh_customer |
| cusapi_key | Nullable(String) | API key |
| cusapi_signature | Nullable(String) | |
| cusapi_deleted | Int16 | |
| cusapi_time | Int64 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_customer_mockup` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~3.2K
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| mockup_id | Int64 | PK |
| exp_id | Int64 | FK → nh_exproduct (ID exp Product) |
| cus_id | Int64 | FK → nh_customer |
| mockup_name | Nullable(String) | |
| mockup_img_frontpath | Nullable(String) | Path mockup front |
| mockup_img_frontname | Nullable(String) | File mockup front |
| mockup_img_backpath | Nullable(String) | Path mockup back |
| mockup_img_backname | Nullable(String) | File mockup back |
| box_front_top | Int64 | |
| box_front_left | Int64 | |
| box_back_top | Int64 | |
| box_back_left | Int64 | |
| mockup_time | Nullable(Int64) | |
| mockup_status | Int16 | |
| mockup_deleted | Int16 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_customer_profile` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~446
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| cus_profile_id | Int64 | PK |
| cus_id | Int64 | FK → nh_customer |
| workshop_address | String | |
| print_type | Int16 | 0=All; 1=DTG; 2=DTF |
| created_at | Int64 | |
| updated_at | Int64 | |
| is_deleted | Int64 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_customer_shipping_carrier` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~233
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| cus_id | Int64 | PK, FK → nh_customer |
| sc_standard | Nullable(String) | standard carrier |
| sc_ground | Nullable(String) | ground carrier |
| sc_fastship | Nullable(String) | express carrier |
| domestic_under_16oz | Nullable(String) | |
| domestic_over_16oz | Nullable(String) | |
| intl_under_16oz | Nullable(String) | |
| intl_over_16oz | Nullable(String) | |
| sc_time | Int64 | |
| sc_time_update | Int64 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_exproduct` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~205
> **Cần FINAL khi query**
> External product catalog

| Column | Type | Ghi chú |
|---|---|---|
| exp_time_update | Int64 | unix timestamp update |
| exp_status | Int16 | |
| exp_display | Int16 | 0=hidden; 1=show account |
| exp_display_on_report | Int16 | 0=Disabled; 1=Enabled — display on metadata report |
| exp_deleted | Int16 | soft delete |
| exp_shorturl | String | |
| exp_order | Int64 | |
| is_sameproduct | Int16 | |
| exp_list_color | Nullable(String) | Đây là exp_option1 |
| exp_list_size | Nullable(String) | Đây là exp_option2 |
| exp_color_default | Nullable(String) | |
| exp_size_default | Nullable(String) | |
| box_front_top | Int64 | Tọa độ top khung trước (%) |
| box_front_left | Int64 | Tọa độ left khung trước (%) |
| box_front_width | Int64 | Chiều rộng khung trước (%) |
| box_front_height | Int64 | Chiều cao khung trước (%) |
| box_back_top | Int64 | Tọa độ top khung sau (%) |
| box_back_left | Int64 | Tọa độ left khung sau (%) |
| box_back_width | Int64 | Chiều rộng khung sau (%) |
| box_back_height | Int64 | Chiều cao khung sau (%) |
| exp_sku | Nullable(String) | |
| exp_model | Nullable(String) | |
| exp_buy_price | Float32 | |
| print_type | Int64 | FK → nh_print_type |
| material_type | Int64 | FK → nh_material |
| exp_number_stock | Int64 | |
| exp_weight | Float32 | |
| exp_weight_unit | Int64 | |
| exp_brand | Nullable(String) | |
| exp_short_brand | Nullable(String) | |
| exp_typename | Nullable(String) | |
| exp_code | Nullable(String) | |
| print_location | Nullable(String) | In mặt trước, mặt sau |
| exp_mokup_front | Nullable(String) | Mockup mặt trước |
| exp_mokup_back | Nullable(String) | Mockup mặt sau |
| user_id | Int64 | FK → nh_user |
| exp_option1 | Nullable(String) | |
| exp_option2 | Nullable(String) | |
| exp_option3 | Nullable(String) | |
| exp_inventory_tracking | Int16 | 0=Normal; 1=Lot; 2=Serial Number |
| template_print | Nullable(String) | Key template print |
| exp_avatar | Nullable(String) | Avatar product |
| exp_avatar_hover | Nullable(String) | Hình avatar khi hover |
| sup_id | Int64 | supplier ID (1=SSA; 2=other) |
| id_scalable | Nullable(String) | Product ID scalablepress |
| exp_data_size | Nullable(String) | Json size của hình mockup |
| cc_product_id | Int64 | Custom Cat Product ID |
| shipping_class | Nullable(String) | Json lưu thông tin shipping class |
| is_primary | Int16 | 0=unknown; 1=primary product; 2=secondary product |
| exp_id_mapping | Int64 | |
| exp_recommend | Nullable(String) | Recommend product when this product out stock |
| exp_featured | Int16 | 0=sản phẩm bình thường; 1=sản phẩm nổi bật |
| exp_trending | Nullable(Int16) | 0=not trending; 1=is trending |
| exp_leading_profit | Int16 | Sản phẩm bán đứng đầu lợi nhuận |
| exp_rate_by_merchant | Int16 | |
| exp_category | Nullable(String) | Danh sách các category mà sản phẩm thuộc về |
| exp_hscode | Nullable(String) | HS code (customs) |
| exp_fulfillment_type | Nullable(Int16) | -1=chưa set; 0=POD |
| exp_updated_at | DateTime64(0,'UTC') | |
| exp_feature_description | Nullable(String) | |
| exp_care_instruction | Nullable(String) | |
| exp_file_guidelines | Nullable(String) | |
| exp_print_guidelines | Nullable(String) | |
| exp_website_catalog_listing | Nullable(Int16) | |
| exp_size_guidelines | Nullable(String) | |
| _processed_at | DateTime64(3,'UTC') | CDC ingest time |
| _action | String | CDC action |
| _timestamp | DateTime64(3,'UTC') | CDC event time |

> **Note:** Các columns đầu (exp_id, exp_name, v.v.) nằm trong phần source data chưa parse được. Xem MCP để lấy full schema.

---

### `nh_exproduct_library` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~127
> **Cần FINAL khi query**
> Product library per product group

| Column | Type | Ghi chú |
|---|---|---|
| eli_id | Int64 | PK |
| exp_id | Int64 | FK → nh_exproduct; Id của product |
| pg_id | Int64 | FK → nh_product_group; ID của category. Dùng để load theo category cụ thể nếu cần |
| eli_avatar | Nullable(String) | Tên của image (mặc định phần path nằm trong exproduct) |
| eli_avatar_hover | Nullable(String) | Tên của image khi hover (nếu cần) (mặc định phần path nằm trong exproduct) |
| eli_default | Int16 | Mark default image when it show in the category |
| eli_time | DateTime64(0,'UTC') | |
| eli_deleted | Int16 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_gift_message_config` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~1.8K
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| gm_id | Int64 | PK |
| store_id | Int64 | FK → nh_store_integrations |
| gm_bg_hex | Nullable(String) | Màu background của gift card |
| gm_color_hex | Nullable(String) | Màu text của gift message |
| gm_img_logo | Nullable(String) | Link image logo |
| gm_message | Nullable(String) | Text của gift card. Dùng cho trường hợp KH làm discount tặng buyer |
| gm_approve | Int16 | 0=Chưa approve; 1=đã approve; 2=disable |
| gm_time_start | Int64 | Thời gian bắt đầu áp dụng (Dùng cho create gift card discount) |
| gm_time_end | Int64 | Thời gian kết thúc áp dụng (Dùng cho create gift card discount) |
| gm_time | Int64 | unix created |
| gm_time_update | Int64 | unix updated |
| gm_deleted | Int16 | |
| gm_type | Int16 | 0=Gift message bình thường; 1=gift card discount |
| cus_id | Int64 | FK → nh_customer |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_image_design` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~5.9M
> **Cần FINAL khi query**
> Design image assets uploaded by sellers

| Column | Type | Ghi chú |
|---|---|---|
| img_id | Int64 | PK |
| img_name | Nullable(String) | |
| img_original | Nullable(String) | Tên gốc dùng để search |
| img_path | Nullable(String) | CDN path |
| img_time | DateTime | created time |
| img_time_date | Int64 | |
| img_time_update | Int64 | |
| img_status | Int16 | 0=ẩn; 1=hiện |
| img_archived | Int16 | |
| img_deleted | Int16 | |
| cus_id | Int64 | FK → nh_customer |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_item_print_location` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~1.6M
> **Cần FINAL khi query**
> Print location detail per order item

| Column | Type | Ghi chú |
|---|---|---|
| ipl_id | UInt64 | PK |
| ord_id | UInt64 | FK → nh_order |
| ordi_id | UInt64 | FK → nh_order_item |
| print_location | Nullable(String) | side print |
| design_path | Nullable(String) | |
| design_name | Nullable(String) | |
| exp_id | UInt64 | FK → nh_exproduct |
| var_id | UInt64 | FK → nh_variants |
| color_id | UInt16 | |
| size_id | UInt16 | |
| is_matched | UInt16 | |
| price | Decimal(20,2) | Giá theo mặt print |
| is_main_location | UInt16 | |
| created_time | DateTime | |
| updated_time | DateTime64(0,'UTC') | |
| ipl_deleted | UInt16 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_material` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~12
> **Cần FINAL khi query**
> Material lookup table

| Column | Type | Ghi chú |
|---|---|---|
| material_id | Int64 | PK |
| material_name | Nullable(String) | |
| material_description | Nullable(String) | |
| material_status | Int16 | 0=hide; 1=show |
| material_deleted | Int16 | |
| material_order | Int64 | |
| material_time | Int64 | |
| material_time_update | Int64 | |
| user_id | Int64 | FK → nh_user |
| material_token_key | Nullable(String) | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order` 🔄 ⭐
> Engine: SharedReplacingMergeTree | Rows: ~14.7M
> **Cần FINAL khi query để dedup**
> Bảng orders chính — source of truth cho mọi báo cáo orders

| Column | Type | Ghi chú |
|---|---|---|
| ord_id | Int64 | PK |
| ord_name | Nullable(String) | order name |
| cus_id | Int64 | FK → nh_customer (seller ID) |
| ord_key | Nullable(String) | |
| ord_promotion | Decimal(20,2) | Giá tiến promotion |
| ord_discount | Float32 | |
| ord_fee_shipping | Float32 | Phí vận chuyển |
| ord_type_discount | Int16 | -1=không dùng discount; 0=discount; 1=free shipping |
| ord_is_vat | Nullable(Int16) | 0=No; 1=Yes |
| ord_coupon | Nullable(String) | |
| ord_vat | Nullable(Float32) | Thuế (%) |
| ord_vat_total | Float32 | Tổng tiền thuế |
| ord_handle_fee | Decimal(20,2) | |
| ord_payment_status | Nullable(Int16) | 0=pending; 3=refund (enum bị truncate trong DDL) |
| ord_payment_method | Int16 | 1=Stripe; 2=Paypal; 3=Wallet |
| ord_time | DateTime | order created time |
| ord_datetime | Int64 | Unix timestamp tại 00:00:00 của ngày tạo đơn |
| ord_payment_datetime | Int64 | unix payment time ⭐ |
| ord_update_time | Int64 | |
| ord_status | Int16 | 0=pending; 1=processing; 2=done; 3=cancelled |
| ord_deleted | Int16 | soft delete flag |
| ord_archived | Int16 | |
| ord_note | Nullable(String) | |
| ord_total | Float32 | order total ⭐ |
| ord_subtotal | Float32 | Tổng tiền = sl × đơn giá |
| ord_profit | Decimal(20,2) | profit ⭐ |
| ord_total_discount | Decimal(20,2) | Value off discount (final calculated) |
| ord_discount_info | Nullable(String) | Thông tin giá discount |
| ord_discount_item_id | Int64 | |
| ord_shipping_location | Nullable(Int16) | 0=USA; 1=international |
| ord_shipping_method | Int16 | 0=Standard; 1=Express |
| ord_cus_email | String | Email end customer |
| ord_cus_name | Nullable(String) | Tên end customer |
| ord_cus_company | Nullable(String) | |
| ord_cus_phonenumber | Nullable(String) | |
| ord_cus_address1 | String | Địa chỉ 1 |
| ord_cus_address2 | String | Địa chỉ 2 |
| ord_cus_country | Int64 | FK → nh_country (id quốc gia) |
| ord_cus_city | String | Tên thành phố |
| ord_cus_province | String | Tên tỉnh thành |
| ord_cus_state | Int64 | FK → nh_state (State ID) |
| ord_cus_postal_code | String | Mã bưu điện |
| ord_zipcode_billing | String | Mã zipcode của order |
| cam_id | Int64 | FK → nh_campaigns |
| transaction_id | Nullable(Int64) | FK → nh_transaction (mã giao dịch) |
| transaction_refund | Int64 | ID transaction refund |
| transaction_profit | Int64 | Transaction profit |
| ord_ip | String | |
| ord_tracking_status | Int16 | 1=Xác nhận; 2=Đang in; 3=Đã vận chuyển; 4=Giao hàng |
| promotion_id | Int64 | |
| store_id | Int64 | FK → nh_store_integrations |
| marketplace_id | Nullable(String) | Amazon marketplace_id |
| is_approve | Int16 | 0=not approved; 1=approved (hiện trên ACP order) |
| ord_type_print | Int16 | 1=screen print; 2=DTG |
| ord_status_custom | Nullable(Int16) | Custom status ⭐: 0=Pending; 10=Back-order; 13=In Production; 14=Picked; 15=Printed; 21=Completed; 22=Shipped; 23=Fulfilled; 31=Cancelled; 33=Failed |
| ord_list | Nullable(String) | |
| asin_list | Nullable(String) | |
| ord_tag | Int16 | 0=no tag; 1=back-order; 2=CS; 3=on-hold; 4=3rd_printing; 5=production-hold; 6=Picking |
| parent_id | Int64 | FK → nh_order (order id cha khi split) |
| ord_time_unlock | Int64 | Check time unlock để lock lại |
| ord_workorder_items | Nullable(Int64) | Số lượng items khả dụng để tạo workorder |
| is_import | Int16 | 0=no; 1=imported order |
| online_id | Nullable(String) | ord_id của order import từ platform |
| online_name | Nullable(String) | platform order name |
| online_reference | Nullable(String) | Order ID 3rd party (Shopify...) |
| purchasedate_online | Int64 | Date created order online (unix) |
| res_content | Nullable(String) | Response content từ third party |
| platform_id | Int16 | 1=Shopify; 2=API; 3=Amazon; 4=clone; 5=Shopbase; 6=TheTeeworld; 7=Manual; 8=OrderDesk; 9=FBA; 16=Platform Gearment |
| method_insert | Int16 | 0=sync; 1=import |
| method_insert_subtype | Int16 | 0=file default; 2=wordpress; 3=Etsy; 4=Presta shop; 5=eBay |
| email_upsell | Int64 | ID email upsell |
| ord_locked | Int16 | 0=chưa lock; 1=đã lock |
| verify_address | Int16 | 0=chưa verify; 1=đã verify |
| ord_time_approve | Int64 | Thời gian duyệt đơn hàng (unix) |
| check_profit | Int16 | Đánh dấu đã tính profit |
| ord_id_3rd | Nullable(String) | Mã order bên printing thứ 3 |
| is_check_stock | Int16 | 0=chưa check; 1=đã check có hàng; 2=có hàng nhưng chưa insert variant stock |
| ord_priority | Int16 | 0=normal; 1=priority; 2=Highest (rush) |
| ord_type_error | Int16 | 0=no error; 1=Wrong t-shirt; 2=Wrong size; 3=Wrong print; 4=Bad print; 7=Lost package; 8=Tracking not work; 9=Partial refund; 10=Full refund; 11=re-buy label; 12=Damaged |
| ord_is_single | Int16 | 0=chưa xác định; 1=single item; 2=multiple items |
| work_id | Int64 | Workorder ID |
| ord_print_provider | Int16 | 1=dreamjunction; 2=scalable |
| multiple_type | Int16 | 0=chỉ có t-shirt; 1=có loại sản phẩm khác |
| ord_is_split | Nullable(Int16) | Đánh dấu đơn hàng đã tách |
| is_issue | Int16 | Đánh dấu đơn hàng có issue |
| ord_issue_status | Int16 | |
| ord_issue_id | Int64 | |
| ord_temp_error | Int16 | Loại lỗi tạm thời — dùng thông báo cho seller tại listing order |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_activities` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~110.6M
> **Cần FINAL khi query**
> Activity log — mọi thay đổi trên orders

| Column | Type | Ghi chú |
|---|---|---|
| oact_id | Int64 | PK |
| ord_id | Int64 | FK → nh_order |
| ref_id | Int64 | Khóa ngoại đến các bảng liên quan |
| ref_src | Nullable(String) | Bảng liên quan (logs, trackings, v.v...) |
| oact_activity | Nullable(String) | Thao tác |
| user_id | Int64 | FK → nh_user |
| cus_id | Int64 | FK → nh_customer |
| oact_time | DateTime | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_barcode_file` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~1.95M
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| ord_barcode_id | Int64 | PK |
| order_id | Int64 | FK → nh_order |
| barcode_path | Nullable(String) | barcode file path |
| ord_barcode_time | DateTime | |
| ord_barcode_datetime | Int64 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_extend` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~4.4M
> **Cần FINAL khi query**
> Order gift message extension

| Column | Type | Ghi chú |
|---|---|---|
| ord_id | Int64 | FK → nh_order (PK) |
| price_gift_message | Float32 | gift message price |
| ext_content | Nullable(String) | Chứa thông tin in gift card |
| image_gift_message | Nullable(String) | Image render gift message |
| ext_time | Int64 | |
| ext_time_update | DateTime64(0,'UTC') | |
| ext_multiple_gift | Nullable(Int16) | 0=single gm; 1=multiple gm (nhiều gift message lưu ở nh_gift_image) |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_extra` 🔄 ⭐
> Engine: SharedReplacingMergeTree | Rows: ~14.7M
> **Cần FINAL khi query**
> Order extra info — tracking number, fulfill location, etc.

| Column | Type | Ghi chú |
|---|---|---|
| ord_id | Int64 | FK → nh_order (PK) |
| ordx_tracking_number | Nullable(String) | tracking number ⭐ |
| ordx_content | Nullable(String) | |
| ordx_create_label | Int16 | 0=chưa tạo; 1=đã tạo; 2=cho tạo label bằng tay |
| ordx_fulfill_locate | String | fulfill location ⭐ (e.g. 'TX1', 'HB1', 'EU1') |
| ordx_items_quantity | Int64 | total items |
| ordx_print_3rd_status | Nullable(String) | Trạng thái order của bên in thứ 3 |
| ordx_print_3rd_sync | Int16 | Check sync thông tin bên printing 3rd |
| ordx_is_check_stock | Int16 | 0=chưa check; 1=đã check có hàng; 2=có hàng nhưng chưa insert variant stock |
| ordx_type_error | Int16 | 0=no error; 1=Wrong t-shirt; 2=Wrong size; 3=Wrong print; 4=Bad print; 5=Missing item(s); 6=Orders are late; 7=Lost package; 8=Tracking code does not work; 9=Partial refund; 10=Full refund; 11=re-buy label; 12=Damaged t-shirt |
| ordx_archived | Int16 | |
| ordx_print_label | Int16 | 0=chưa print label; 1=đã print label |
| ordx_workshop_push | Int16 | 0=not add cronjob; 1=added cronjob |
| ordx_ioss_number | Nullable(String) | IOSS number (EU VAT) |
| ordx_ioss_number_total | Float32 | |
| buyer_tax_number | Nullable(String) | Tax code của buyer |
| buyer_tax_amount | Float32 | |
| ordx_ignore_healthcheck | Nullable(Int16) | Đánh dấu để bỏ qua healthcheck |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_extra_fee` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~8.1M
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| id | Int64 | PK |
| order_id | Int64 | FK → nh_order |
| amount | Decimal(20,2) | fee amount |
| time_create | DateTime | |
| cus_id | Int64 | FK → nh_customer |
| extra_type | Int16 | 0=surcharge label; 2=Thanks card; 3=Season Fee; 4=Rush fee |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_item` 🔄 ⭐
> Engine: SharedReplacingMergeTree | Rows: ~17M
> **Cần FINAL khi query**
> Order line items — mỗi row là một item trong order

| Column | Type | Ghi chú |
|---|---|---|
| ordi_id | Int64 | PK |
| ord_id | Int64 | FK → nh_order ⭐ |
| ordi_name | Nullable(String) | item name |
| transaction_id | Int64 | FK → nh_transaction (mã giao dịch) |
| pcam_id | Int64 | FK → nh_product_campaigns |
| ordi_size | Int64 | size ID |
| ordi_color | Int64 | color ID |
| material_id | Int64 | FK → nh_material (Material ID) |
| print_type | Int64 | FK → nh_print_type |
| ordi_price | Float32 | item price ⭐ |
| ordi_price_original | Float32 | Giá gốc — chưa tính discount |
| price_extra | Float32 | Giá cộng thêm (ví dụ: in 2 mặt) |
| ordi_quantity | Int64 | Số lượng ⭐ |
| ordi_fee_shipping | Float32 | item shipping fee |
| ordi_base_cost | Nullable(Float32) | = nh_variants.var_cost_price |
| ordi_base_cost_synced_at | Nullable(Int64) | Thời điểm sync giá từ bảng variants (unix) |
| ordi_printing_cost | Nullable(Float32) | Dùng cho business account |
| ordi_vat_total | Float32 | |
| ordi_handle_fee | Decimal(20,2) | |
| ordi_subtotal | Float32 | Tổng tiền = ordi_quantity × ordi_price |
| ordi_total | Float32 | item total |
| ordi_profit | Float32 | Lợi nhuận ⭐ |
| ordi_deleted | Int16 | soft delete |
| bin_id | Int64 | BIN Order ID |
| work_id | Int64 | Work Order ID |
| po_id | Int64 | Purchase Order ID |
| ordi_content | Nullable(String) | |
| ordi_content_temp | Nullable(String) | |
| ordi_content_res | Nullable(String) | |
| ordi_discount_info | Nullable(String) | |
| discount_item_id | Int64 | |
| cam_id | Int64 | FK → nh_campaigns |
| cus_id | Int64 | FK → nh_customer (id reseller) |
| ordi_time | DateTime | item created time |
| ordi_time_update | Int64 | |
| ordi_datetime | Int64 | |
| ordi_payment_datetime | Int64 | unix payment time |
| ordi_quantity_printed | Int16 | qty already printed |
| exp_id | Int64 | FK → nh_exproduct — id sản phẩm mẫu ⭐ |
| varian_id | Int64 | FK → nh_variants |
| ordi_status | Int16 | Item status ⭐: 0=pending; 1=in production; 2=pickup; 3=printed; 4=completed; 5=failed; 6=picking |
| store_id | Int64 | FK → nh_store_integrations |
| print_id | Int64 | |
| shipping_id | Int64 | |
| send_print | Int16 | Lệnh ink: 0=chưa gửi; 1=đã gửi |
| ordi_quantity_error | Int16 | Số lượng áo in lỗi |
| ordi_quantity_adjust | Int64 | Dùng để check số lượng trừ stock |
| side_print | Nullable(String) | Mặt in — dùng cho order import từ ngoài vào |
| is_import | Int16 | Order import: 0=no; 1=yes |
| design_path | Nullable(String) | Link design được lưu (mặt trước) |
| design_path_back | Nullable(String) | Link design mặt sau |
| design_front_name | Nullable(String) | Import: Tên hình design mặt trước |
| design_back_name | Nullable(String) | Import: Tên hình design mặt sau |
| ordi_base_price | Decimal(20,2) | Giá base price tại thời điểm mua hàng |
| ordi_online_id | Nullable(String) | Item online ID (platform) |
| asin_online_id | Nullable(String) | Amazon ASIN |
| sellersku_online_id | Nullable(String) | Seller SKU trên platform |
| title_online_id | Nullable(String) | |
| ordi_package | Nullable(String) | Thông tin package lúc buy label |
| is_print_barcode | Int16 | 0=chưa in; 1=đã in; 2=in lại |
| printer_path_front | Nullable(String) | ARX4 front path |
| printer_path_back | Nullable(String) | ARX4 back path |
| ordi_quality_number | Int64 | Số lượng cần quality check |
| create_arx4 | Int16 | 0=không tạo; 1=tạo file in; 2=đã tạo; 3=đã xóa; 4=xóa fail |
| location_item | Nullable(String) | Nơi mua áo |
| ordi_backup | Nullable(String) | Backup khi variant thay đổi |
| ordi_user_printer | Int64 | ID user printer |
| ordi_assets | Nullable(String) | JSON assets |
| ordi_type | Int16 | Item type ⭐: 0=Garment; 1=Mug; 2=Poster; 3=Case |
| ord_id_related | Int64 | ID order liên quan với item này |
| ordi_tracking | Nullable(String) | Tracking code related |
| ordi_json_tracking | Nullable(String) | JSON tracking |
| path_fba | Nullable(String) | FBA path |
| ordi_old_id | Nullable(Int64) | Đồng bộ data giữa 2 item do split order |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_note` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~383K
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| ord_note_id | Int64 | PK |
| ord_id | Int64 | FK → nh_order |
| ord_note_content | Nullable(String) | internal note |
| ord_gift_message | Nullable(String) | Nội dung in thiệp |
| image_gift_message | Nullable(String) | Hình gift card được tạo từ cron |
| ord_note_time | DateTime | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_print_type` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~2.2M
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| ord_id | Int64 | FK → nh_order (PK) |
| print_type | Nullable(String) | print type string |
| created_at | DateTime64(0,'UTC') | |
| updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_refund` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~150K
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| order_refund_id | Int64 | PK |
| order_id | Int64 | FK → nh_order |
| ordi_id | Int64 | FK → nh_order_item |
| cus_id | Int64 | FK → nh_customer |
| order_amount | Decimal(20,2) | refund amount |
| transaction_id | Int64 | FK → nh_transaction |
| created_time | Int64 | unix created |
| created_datetime | Int64 | |
| refund_fastship | Int16 | |
| type_refund | Int16 | 0=normal; 1=fastship refund; 2=partially refund; 3=shipping cost refund; 4=handle fee; 5=basecost |
| unit_refund | Int64 | units refunded; dùng cho refund 1 phần |
| reason_id | Int64 | Lý do refund nằm trong bảng nh_issue_category |
| updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |
| user_id | Nullable(UInt32) | FK → nh_user |

---

### `nh_order_shipping_zone` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~11.7M
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| ord_id | UInt64 | FK → nh_order (PK) |
| shipping_zone | Int16 | zone code ⭐ |
| updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_source` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~14.7M
> **Cần FINAL khi query**
> Order source: platform, channel, label info

| Column | Type | Ghi chú |
|---|---|---|
| ord_id | UInt64 | FK → nh_order (PK) |
| pla_id | UInt16 | FK → nh_platforms.pla_id |
| cme_id | UInt16 | FK → nh_creation_methods.cme_id |
| is_label | UInt16 | The order is label order or not |
| created_at | DateTime64(0,'UTC') | |
| updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_order_weight` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~11.1M
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| order_id | Int64 | FK → nh_order (PK) |
| order_weight | Float32 | weight (oz) |
| order_weight_in_lbs | Nullable(String) | weight label string |
| updated_at | DateTime64(0,'UTC') | |
| order_at_risk | Int16 | at-risk flag |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_payment_account` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~29.9K
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| pay_id | Int64 | PK |
| cus_id | Int64 | FK → nh_customer |
| pay_email | Nullable(String) | only use for paypal account |
| pay_default | Int16 | default flag |
| pay_type | Int16 | 0=paypal; 1=payooner; 2=creditcard; 3=g-wallet |
| pay_time | Int64 | |
| pay_content | Nullable(String) | Payment billing. Paypal => transaction_id |
| pay_ref_id | Nullable(String) | cus id reference in 3rd |
| pay_deleted | Int16 | |
| balance_id | Nullable(String) | ID balance of PO |
| access_token | Nullable(String) | |
| refresh_token | Nullable(String) | |
| time_token_expired | Int64 | |
| pay_default_billing | Int16 | Set default billing for deposit |
| payoneer_agreement | Int16 | |
| payoneer_payee_status | Nullable(String) | |
| lasted_payment_time | Int64 | Thời gian payment của lần gần nhất |
| lasted_payment_status | Nullable(String) | Status lần cuối payment |
| braintree_customer_info | Nullable(String) | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_platforms` 🔄
> Engine: SharedReplacingMergeTree | Rows: 15
> **Cần FINAL khi query**
> Lookup table: platform name — Gearment, Amazon, Etsy, Ebay, Poshmark, Shopify, Shopbase, Wordpress, BigCommerce, Prestashop, Inkgo, Wish, Customily, Tiktok, OrderDesk

| Column | Type | Ghi chú |
|---|---|---|
| pla_id | UInt16 | PK |
| pla_name | String | tên platform |
| created_at | DateTime64(0, 'UTC') | |
| updated_at | DateTime64(0, 'UTC') | |
| _processed_at | DateTime64(3, 'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3, 'UTC') | |

---

### `nh_print_type` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~24
> **Cần FINAL khi query**
> Print type lookup

| Column | Type | Ghi chú |
|---|---|---|
| print_type_id | Int64 | PK |
| print_type_name | Nullable(String) | |
| print_type_code | Int16 | -1=chưa có mã code |
| print_type_description | Nullable(String) | |
| print_type_status | Int16 | |
| print_type_deleted | Int16 | |
| print_type_order | Int64 | |
| print_type_time | Int64 | |
| print_type_time_update | Int64 | |
| user_id | Int64 | FK → nh_user |
| print_type_token_key | Nullable(String) | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_product_campaigns` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~387K
> **Cần FINAL khi query**
> Product variants (color/size combinations) per campaign

| Column | Type | Ghi chú |
|---|---|---|
| pcam_id | Int64 | PK |
| exp_id | Int64 | FK → nh_exproduct |
| pcam_color | String | Chuỗi id thuộc tính color |
| pcam_size | Nullable(String) | Chuỗi id thuộc tính size |
| pcam_price | Float32 | selling price |
| pcam_compare_price | Float32 | Giá cũ |
| pcam_content | Nullable(String) | Lưu json các thông tin cần thiết |
| pcam_short_product_type | Nullable(String) | short type name |
| pcam_quantity | Int64 | |
| pcam_img_front | String | front mockup image |
| pcam_img_back | String | back mockup image |
| pcam_img_upfront | String | |
| pcam_img_upback | String | |
| cam_id | Int64 | FK → nh_campaigns |
| pcam_time | DateTime | |
| member_id | Int64 | id khách hàng |
| mockup_id | Int64 | Mockup id profile |
| pcam_path_front | String | Đường dẫn hình mặt trước |
| pcam_path_back | String | Đường dẫn hình mặt sau |
| tmp_path_front | String | Link hình trong tmp |
| tmp_path_back | String | Link hình trong tmp |
| pcam_width_front | Int64 | print box dimensions |
| pcam_height_front | Int64 | |
| pcam_width_back | Int64 | |
| pcam_height_back | Int64 | |
| pcam_left_front | Int64 | |
| pcam_top_front | Int64 | |
| pcam_left_back | Int64 | |
| pcam_top_back | Int64 | |
| typeprint | Int16 | uni |
| color_print_front | Int64 | |
| color_print_back | Int64 | |
| pcam_deleted | Int16 | |
| token_key | Nullable(String) | |
| pcam_img_token | Nullable(String) | |
| pcam_sync | Int16 | 0=No sync; 1=sync; 2=processing; 3=complete |
| variant_number | Int64 | Tổng số variant của product |
| pcam_color_default | Int64 | |
| pcam_size_default | Int64 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_product_configurations` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~379
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| pp_id | UInt64 | PK |
| exp_id | Int64 | FK → nh_exproduct |
| ppl_id | UInt64 | FK → nh_product_print_location; ID from nh_product_print_location |
| pp_price | Nullable(Float32) | |
| pp_time | Int64 | |
| pp_time_update | DateTime64(0,'UTC') | |
| image | Nullable(String) | URL mockup |
| seasonal_image | Nullable(String) | Hình ảnh mockup theo mùa:Halloween, Noel |
| box_top | Decimal(20,2) | |
| box_left | Decimal(20,2) | |
| box_width | Decimal(20,2) | |
| box_height | Decimal(20,2) | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_product_group` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~56
> **Cần FINAL khi query**
> Product group / category hierarchy

| Column | Type | Ghi chú |
|---|---|---|
| product_group_id | Int64 | PK |
| product_group_time | Int64 | |
| product_group_time_update | Int64 | |
| product_group_deleted | Int16 | |
| user_id | Int64 | FK → nh_user |
| product_group_parent | Nullable(Int64) | parent group (hierarchy) |
| product_group_name | String | group name ⭐ |
| product_group_code | String | group code ⭐ |
| product_group_status | Int16 | 0=ẩn; 1=hiện |
| product_group_description | Nullable(String) | |
| product_group_avatar | Nullable(String) | |
| product_group_type | Int16 | 0=hàng hóa; 1=dịch vụ GTGT |
| pg_shorturl | String | |
| product_group_order | Int64 | Sắp xếp danh mục |
| cat_gallery_id | Int64 | Danh mục gallery |
| attr_group | Int64 | attribute group_id |
| product_group_banner | Nullable(String) | |
| product_group_is_collection | Nullable(Int16) | |
| product_group_is_new | Nullable(Int16) | |
| product_group_is_popular | Nullable(Int16) | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_product_print_location` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~10
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| ppl_id | UInt64 | PK |
| ppl_name | Nullable(String) | location name |
| ppl_status | Int16 | 0=Deactive; 1=Active |
| ppl_created_time | DateTime64(0,'UTC') | |
| ppl_updated_time | DateTime64(0,'UTC') | |
| ppl_deleted | Int16 | |
| ppl_is_main | Nullable(Int16) | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_product_type` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~22
> **Cần FINAL khi query**
> Product type mapping: exp_id + ordi_type → type_name

| Column | Type | Ghi chú |
|---|---|---|
| type_id | Int64 | PK |
| exp_type | Int64 | FK → nh_exproduct |
| ordi_type | UInt16 | type code (FK từ nh_order_item.ordi_type) ⭐ |
| type_name | Nullable(String) | type name ⭐ |
| is_deleted | Int16 | |
| created_at | DateTime64(0,'UTC') | |
| updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_reality_tracking` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~8.1M
> **Cần FINAL khi query**
> Dữ liệu billing thực tế từ carrier: actual weight vs billed weight, charges, zone per shipment

| Column | Type | Ghi chú |
|---|---|---|
| rt_id | Int64 | PK |
| tracking_id | String | Tracking number |
| ord_id | Nullable(Int64) | FK → nh_order |
| customer_reference_1 | Nullable(String) | Reference từ customer |
| overlabelled_tracking_number | Nullable(String) | Tracking số đè nhãn |
| actual_weight | Float32 | Cân nặng thực tế (lb) |
| billed_weight | Float32 | Cân nặng tính phí (lb) |
| billed_weight_in_lb | Nullable(String) | Cân nặng tính phí dạng text |
| weight_type | Nullable(String) | Loại cân: actual / dimensional |
| zone | Int16 | Shipping zone |
| provider | String | Carrier provider (USPS, UPS...) |
| type | String | Loại dịch vụ |
| service | Nullable(String) | Service level |
| processed_at | Nullable(DateTime64(0,'UTC')) | Thời điểm carrier xử lý |
| manifest_date | Nullable(Date) | Ngày manifest |
| package_charge | Decimal(20,2) | Phí gói hàng |
| fuel_charge | Decimal(20,2) | Phí nhiên liệu |
| total_charge | Nullable(Decimal(11,2)) | Tổng phí thực tế từ carrier |
| destination_zip | Nullable(String) | Zip đích |
| destination_city | Nullable(String) | City đích |
| destination_state | Nullable(String) | State đích |
| destination_country | Nullable(String) | Country đích |
| rtq_id | UInt64 | FK → queue record |
| ship_carrier | Nullable(String) | Carrier name |
| ship_service | Nullable(String) | Service name |
| created_at | DateTime64(0,'UTC') | |
| updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | CDC metadata |
| _action | String | CDC metadata |
| _timestamp | DateTime64(3,'UTC') | CDC metadata |

---

### `nh_rush_order_data` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~352K
> **Cần FINAL khi query**
> Rush order / express order tracking

| Column | Type | Ghi chú |
|---|---|---|
| rush_id | Int64 | PK |
| cro_id | Int64 | |
| rush_order_id | Int64 | FK → nh_order |
| rush_status | Int16 | 0=unuse; 1=used |
| rush_over | Int16 | 0=rush thường; 1=rush over slot |
| rush_datetime | Int64 | |
| created_time | Int64 | |
| used_time | Int64 | |
| updated_time | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_scanning_label_orders` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~1.96M
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| ord_id | Int64 | FK → nh_order (PK) |
| label_url | Nullable(String) | |
| label_cdn_link | Nullable(String) | |
| platform | Nullable(String) | nh_platforms.pla_name |
| status | Int16 | 0=pending; 1=processing; 2=success; 3=failed |
| debug_message | Nullable(String) | Nội dung file label trường hợp scan bị fail |
| created_at | DateTime64(0,'UTC') | |
| updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_shipment` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~8.7M
> **Cần FINAL khi query**
> Shipments — shipping labels per order item

| Column | Type | Ghi chú |
|---|---|---|
| ship_id | Int64 | PK |
| ship_name | Nullable(String) | |
| ship_code | Nullable(String) | |
| ship_status | Nullable(String) | Trạng thái bên shipment |
| ship_price | Decimal(20,2) | Label fee |
| ship_time | DateTime | |
| ship_time_update | Int64 | |
| ord_id | Int64 | FK → nh_order |
| ordi_id | Int64 | FK → nh_order_item |
| reference_id | Nullable(String) | ID bên partner mua label qua gearment |
| ship_scanform | Nullable(String) | scanform easypost |
| ship_batch_id | Nullable(String) | |
| ship_webhook_id | Nullable(String) | |
| ship_tracker_id | Nullable(String) | |
| ship_deleted | Int16 | |
| ship_carrier | Nullable(String) | Tên carrier ⭐ |
| ship_service | Nullable(String) | Tên service |
| ship_rate | Nullable(String) | rate response JSON |
| ship_trackingcode | Nullable(String) | tracking number ⭐ |
| ship_tracking_link | Nullable(String) | |
| time_update_scanform | Int64 | |
| ship_archive | Int16 | 0=không archive; 1=đã archive |
| ship_carrier_id | Int16 | carrier ID code |
| ord_status_custom | Int16 | Status bên order |
| ship_created_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_shipment_management` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~7.6M
> **Cần FINAL khi query**
> Shipment management — final tracking numbers & carrier links

| Column | Type | Ghi chú |
|---|---|---|
| sm_id | Int64 | PK |
| ord_id | Int64 | FK → nh_order |
| parent_id | Int64 | parent shipment |
| reference_id | Nullable(String) | Id Bên thứ 3 |
| sm_link_label | Nullable(String) | label link |
| sm_tracking_number | Nullable(String) | tracking number ⭐ |
| sm_tracking_company | Nullable(String) | carrier ⭐ |
| sm_tracking_link | Nullable(String) | |
| sm_tracking_convert_link | Nullable(String) | |
| sm_tracking_carrier | Nullable(String) | |
| sm_tracking_service | Nullable(String) | |
| api_source | Nullable(String) | |
| dhl_package_id | Nullable(String) | |
| sm_carrier_service | Nullable(String) | |
| sm_carrier_linked | Nullable(String) | Dùng cho trường hợp Carrier hiện tại sẽ dùng carrier khác để hiển thị |
| sm_service_linked | Nullable(String) | |
| sm_carrier_service_linked | Nullable(String) | |
| sm_time | DateTime | |
| sm_time_update | Int64 | |
| sm_deleted | Int16 | |
| sm_tracking_sync_status | UInt16 | 0=pending; 1=processing; 2=Success; 3=Failed |
| created_at | Nullable(String) | |
| updated_at | Nullable(String) | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_shipping_profiles` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~17
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| sp_id | Int64 | PK |
| sp_name | Nullable(String) | |
| sp_key | Nullable(String) | |
| sp_location | Int16 | 0=domestic; 1=inter |
| sp_type | Int16 | 0=stantad; 1=2day; 2=ground |
| sp_status | Int16 | |
| sp_config | String | JSON config |
| sp_time | Int64 | |
| user_id | Int64 | FK → nh_user |
| sp_deleted | Int16 | |
| sp_list_customer | Nullable(String) | |
| is_protected | Int16 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_shipping_zones` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~2.8K
> **Cần FINAL khi query**
> Lookup: zipcode range → shipping zone, theo country

| Column | Type | Ghi chú |
|---|---|---|
| shz_id | Int64 | PK |
| shz_zipcode_from | String | Zip đầu khoảng |
| shz_zipcode_to | String | Zip cuối khoảng |
| shz_zone | Int16 | Zone number |
| country_code | String | Country code (US...) |
| shz_created_at | DateTime64(0) | |
| shz_updated_at | DateTime64(0) | |
| _processed_at | DateTime64(3,'UTC') | CDC metadata |
| _action | String | CDC metadata |
| _timestamp | DateTime64(3,'UTC') | CDC metadata |

---

### `nh_size_guide` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~15
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| size_guide_id | Int64 | PK |
| size_guide_name | Nullable(String) | |
| size_guide_content | Nullable(String) | HTML/JSON content |
| products_list | Nullable(String) | |
| size_guide_deleted | Nullable(Int16) | |
| size_guide_time | Int64 | |
| user_id | Int64 | FK → nh_user |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_state` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~84
> **Cần FINAL khi query**
> US states / provinces

| Column | Type | Ghi chú |
|---|---|---|
| state_id | Int64 | PK |
| state_name | String | |
| state_code | String | 2-letter code |
| country_code | String | |
| state_tax | Decimal(10,3) | tax rate |
| state_updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_store_integrations` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~16.8K
> **Cần FINAL khi query**
> Store integrations: Shopify, Etsy, Amazon, ShopBase, etc.

| Column | Type | Ghi chú |
|---|---|---|
| store_id | Int64 | PK |
| store_backend_type | Nullable(String) | vd: wcom, shopify |
| store_backend_sync | Int16 | |
| store_show_name | Nullable(String) | display name |
| store_url | Nullable(String) | store URL |
| store_name | Nullable(String) | store name ⭐ |
| store_status | Int16 | |
| cus_id | Int64 | FK → nh_customer ⭐ |
| staff_id | Nullable(String) | |
| store_api_key | Nullable(String) | |
| store_secret_key | Nullable(String) | |
| store_password | Nullable(String) | |
| store_access_token | Nullable(String) | |
| store_refresh_token | Nullable(String) | Amazon Merchant Refresh Token |
| store_expired | Int16 | 1=expired token |
| store_res_logs | Nullable(String) | |
| store_res_time | Int64 | |
| store_id_foreign | Nullable(String) | ID của bên thứ 3 |
| store_time | DateTime | |
| store_time_update | Int64 | |
| store_deleted | Int16 | |
| store_token | Nullable(String) | |
| store_is_default | Int16 | |
| store_read_only | Int16 | 1=read only |
| folder_id | Nullable(String) | |
| store_autosync | Int16 | 1=auto sync |
| store_send_shipment_type | Int16 | 0=Default; 1=Plugin Woo |
| sync_order_manual_payment | Int16 | |
| amazon_marketplace_id | Nullable(String) | Amazon marketplace id |
| cam_sync | Int64 | |
| cron_thread | Int16 | |
| cam_sync_shopbase | Int64 | |
| cron_thread_shopbase | Int16 | |
| store_update_scope | Int16 | |
| order_sync_tracking | Int64 | |
| cam_sync_etsy | Int64 | |
| cron_thread_etsy | Int16 | |
| etsy_shipping_template_id | Int64 | |
| etsy_limit_rate | Int64 | |
| store_authorized_time | Int64 | |
| created_at | DateTime64(0,'UTC') | |
| updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_store_integrations_config` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~2.5K
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| store_inconfig | Int64 | PK |
| store_id | Int64 | FK → nh_store_integrations |
| store_refresh_token | Nullable(String) | Amazon Merchant Refresh Token |
| raw_data_token | Nullable(String) | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_topup_payment` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~85.9K
> **Cần FINAL khi query**
> Seller top-up / deposit payments

| Column | Type | Ghi chú |
|---|---|---|
| topup_id | Int64 | PK |
| cus_id | Int64 | FK → nh_customer |
| transaction_id | Nullable(String) | transaction id của gearment |
| payment_id | String | ID thanh toán của khách |
| topup_amount | Decimal(20,2) | amount deposited |
| topup_type | Int16 | 1=Payoneer; 2=Pingpong; 3=Paypal; 4=PayPalInstant; 5=LianLian; 6=MassPaypal |
| payment_type | Int16 | 0=Request; 1=Instant |
| topup_image | Nullable(String) | |
| topup_status | Int16 | 0=pending; 1=Completed; 2=Canceled |
| topup_verified | Int16 | 0=Unverified; 1=Verified; 2=Verified wrong info |
| topup_reject_reason | Int16 | 1=Wrong transaction ID; 2=Wrong Amount; 3=Wrong Payment method; 4=Other |
| user_id_approved | Int64 | FK → nh_user (approver) |
| created_time | Int64 | unix created |
| updated_time | Int64 | |
| approved_time | Int64 | |
| topup_log | Nullable(String) | |
| topup_level | Int16 | 0=Khách top-up new; 1=Khách top-up nhiều lần |
| topup_deleted | Int16 | |
| deleted_time | Int64 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_tracking_shipment_events` 🔄
> Engine: SharedReplacingMergeTree | Rows: 0 (empty)
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| trke_id | Int64 | PK |
| trk_tracking_number | String | |
| trke_status | Nullable(String) | |
| trke_status_detail | Nullable(String) | |
| trke_date | Nullable(String) | |
| trke_is_lastest | UInt16 | latest event flag |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_tracking_shipments` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~10.2M
> **Cần FINAL khi query**
> Tracking record per tracking number

| Column | Type | Ghi chú |
|---|---|---|
| trk_id | Int64 | PK |
| trk_tracking_number | String | tracking number ⭐ |
| trk_api_type | Nullable(String) | osm; easypost; 3rd |
| trk_external_id | Nullable(String) | ID của API |
| trk_status | Nullable(String) | tracking status ⭐ |
| trk_status_detail | Nullable(String) | detailed status |
| trk_est_delivery_date | Nullable(String) | estimated delivery |
| trk_weight | Nullable(Float32) | |
| trk_carrier | Nullable(String) | carrier name ⭐ |
| trk_service | Nullable(String) | |
| trk_error_content | Nullable(String) | Nội dung lỗi từ API nếu có |
| trk_created_at | Nullable(String) | |
| trk_updated_at | Nullable(Int64) | |
| trk_url | Nullable(String) | tracking URL |
| trk_checked_at | Nullable(Int64) | Thòi điểm check từ API |
| trk_checked_times | Nullable(Int16) | Số lần gửi request |
| trk_checked_times_error | Nullable(Int16) | Số lần check lỗi |
| trk_checking_status | Nullable(UInt16) | Trạng thái khi gọi API: 0=pending; 1=processing; 2=ok; 3=failed |
| ord_id | Int64 | FK → nh_order |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_transaction` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~2M
> **Cần FINAL khi query**
> Financial transactions / billing records

| Column | Type | Ghi chú |
|---|---|---|
| transaction_id | Int64 | PK |
| user_id | Int64 | FK → nh_user |
| cus_id | Int64 | FK → nh_customer |
| cus_email | Nullable(String) | |
| bank_id | Int64 | |
| transaction_name | Nullable(String) | |
| transaction_key | Nullable(String) | |
| transaction_content | Nullable(String) | |
| transaction_datetime | Nullable(Int64) | Thời gian tại tời điểm 00:00:00 của ngày |
| transaction_payment_date | Nullable(Int64) | |
| transaction_time | Int64 | unix created |
| transaction_time_update | Int64 | |
| transaction_total | Decimal(20,2) | amount ⭐ |
| transaction_type | Int16 | 1=Sales; 2=Expenses |
| transaction_subtype | Nullable(Int16) | 1=invoices; 2=receive; 3=sales; 4=estimate; 5=bill; 6=expense; 7=bill payment; 8=credit memo; 9=add wallet; 10=Commission; 11=Refund |
| transaction_parent_id | Nullable(Int64) | |
| transaction_invoice_no | Nullable(Int64) | |
| transaction_contract_code | Nullable(String) | |
| transaction_billing_address | Nullable(String) | |
| transaction_terms | Int64 | |
| transaction_term_name | Nullable(String) | |
| transaction_estimate_status | Nullable(Int16) | 0=pending; 1=accepted; 2=closed; 3=rejected |
| transaction_estimate_date | Int64 | |
| transaction_accepted_by | Nullable(String) | |
| transaction_accepted_date | Int64 | |
| transaction_bill_no | Nullable(Int64) | |
| transaction_payment_method | Int16 | 0=Cash; 1=credit card; 2=paypal; 3=bank transfer; 4=Internet banking; 5=ATM; 6=Wallet; 7=PO |
| transaction_ip_address | Nullable(String) | |
| transaction_status | Int16 | 0=pending; 1=paid; 2=overdue; 3=closed; 4=rejected |
| transaction_deleted | Int16 | |
| transaction_confirm_by | Int64 | |
| transaction_confirm_time | Int64 | |
| transaction_after_trading | Nullable(Int64) | Số dư tài khoản sau khi giao dịch |
| transaction_parent | Nullable(Int64) | Dùng cho trường hợp huỷ order, hoàn tiền |
| transaction_type_cash | Int16 | 1=Cộng tiền; 2=trừ tiền |
| transaction_account | Nullable(Int64) | |
| transaction_reference_no | Nullable(String) | |
| transaction_online_id | Nullable(String) | TRX ID 3rd |
| transaction_balance_from | Decimal(20,2) | Balance before |
| transaction_balance | Decimal(20,2) | Balance after |
| transaction_deposit_from | Int16 | 1=Deposit from VND |
| at_id | Int64 | Tài khoản kế toán |
| cus_type | Int64 | 1=cus_id; 2=supplier_id; 3=Nhân viên |
| supplier_id | Int64 | |
| sublog_id | Int64 | |
| total_order | Int64 | |
| cam_id | Int64 | FK → nh_campaigns |
| platform_id | Int16 | |
| transaction_updated_at | DateTime64(0,'UTC') | |
| is_receipted | UInt16 | |
| transaction_kind | Nullable(String) | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_user` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~351
> **Cần FINAL khi query**
> Internal staff / system users

| Column | Type | Ghi chú |
|---|---|---|
| user_id | Int64 | PK |
| user_name | String | username |
| user_display_name | String | display name |
| userg_id | Int16 | user group ID |
| user_is_leader | Int16 | |
| user_email | String | |
| user_joined | Int64 | unix join date |
| user_ip_address | Nullable(String) | |
| user_last_visit | Nullable(Int64) | |
| user_last_activity | Nullable(Int64) | |
| user_login_key | Nullable(String) | |
| user_security_password | String | hashed password |
| user_signature | Nullable(String) | |
| user_permission | Nullable(String) | JSON permissions |
| user_note | Nullable(String) | |
| user_note_time | Int64 | |
| user_location | Nullable(String) | |
| user_jobtitle | Nullable(String) | |
| user_bdday | Int16 | birthday day |
| user_bdmonth | Int16 | birthday month |
| user_bdyear | Int64 | birthday year |
| user_sex | Int16 | |
| user_address | Nullable(String) | |
| user_startjob | Int64 | |
| user_endjob | Int64 | |
| user_avatar | Nullable(String) | |
| user_deleted | Int16 | |
| user_status | Int16 | |
| user_basicsalary | Int64 | |
| user_benefit | Int64 | |
| user_dayspecify | Int16 | |
| user_insure | Int64 | |
| user_insure2 | Int64 | |
| user_contractperiod | Nullable(String) | |
| user_bankaccount | Nullable(String) | |
| user_nightsalary | Int64 | |
| user_message | Nullable(String) | |
| user_phone | Nullable(String) | |
| user_probationary | Int64 | |
| user_dayprobationary | Int64 | |
| user_notify_msg | Int64 | |
| user_avatarcard | Nullable(String) | |
| user_card_id | Nullable(String) | |
| user_card_reason | Nullable(String) | |
| user_card_code | Nullable(String) | |
| user_card_time | Int64 | |
| user_hash | Nullable(String) | |
| user_salt | Nullable(String) | |
| user_isprobrationary | Int16 | |
| user_beginjob | Int64 | |
| user_draft_product | Nullable(String) | |
| user_license_package | Nullable(String) | |
| user_license_cycle | Int64 | |
| user_license_expired | Int64 | |
| user_commission_data | Nullable(String) | |
| user_time | Int16 | |
| user_time_update | Int64 | |
| user_is_staff | Int16 | Là nhân viên |
| user_range | Int64 | |
| user_fulfill_locate | Nullable(String) | fulfill location assignment (HB1, EU1) |
| user_employee_id | Nullable(String) | Employe ID = String, login with Employee ID without username password (IP Whitelist in CRM) |
| user_slack_id | Nullable(String) | |
| user_number_qry | Int16 | so lan duoc thuc hien query |
| user_slack_code | Nullable(String) | |
| user_updated_at | DateTime64(0,'UTC') | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_user_label` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~6.6K
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| ul_id | Int64 | PK |
| cus_id | Int64 | FK → nh_customer |
| store_id | Int64 | FK → nh_store_integrations |
| ul_address | Nullable(String) | |
| ul_scan_trademark | Int16 | 0=not scan trademark; 1=scan trademark |
| ul_time | Int64 | |
| ul_time_update | Int64 | |
| ul_deleted | Int16 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_variants` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~16.1K
> **Cần FINAL khi query**
> Product variant inventory data

| Column | Type | Ghi chú |
|---|---|---|
| var_id | Int64 | PK |
| product_id | Int64 | FK → nh_exproduct; Đây là exp_id |
| var_title | Nullable(String) | Shopify: title, var name |
| var_price | Float32 | Tương đương var_basecost |
| var_sku | String | SKU |
| var_position | Int64 | |
| var_inventory_policy | Nullable(String) | |
| var_compare_at_price | Nullable(Float32) | |
| var_fulfillment_service | Nullable(String) | |
| var_inventory_management | Int64 | |
| var_option1 | Nullable(String) | Tương đương var_color |
| var_option2 | Nullable(String) | Tương đương var_size |
| var_option3 | Nullable(String) | option 3 |
| var_created_at | Nullable(DateTime64(0)) | |
| var_updated_at | DateTime64(0,'UTC') | |
| var_taxable | Int16 | |
| var_barcode | Nullable(String) | |
| var_grams | Int64 | weight in grams |
| var_image_id | Nullable(String) | |
| var_inventory_quantity | Int64 | update 24/09/2020, save ssaw total qty |
| var_weight | Float32 | weight |
| var_weight_unit | Nullable(Int16) | 1=oz; 2=lb; 3=gram |
| var_inventory_item_id | String | |
| var_old_inventory_quantity | Int64 | |
| var_requires_shipping | Int16 | |
| var_admin_graphql_api_id | Nullable(String) | |
| var_stock | Int64 | stock level 1 |
| var_stock2 | Int64 | stock level 2 |
| var_available | Int64 | Số lượng khả dụng |
| on_order | Int64 | Số lượng cần sử dụng |
| var_extra_charge | Float32 | |
| var_price_buy | Float32 | buy price |
| var_re_price | Float32 | Giá recommend |
| var_cost_price | Float32 | Giá gốc mua từ vendor |
| var_cost_sale | Float32 | Giá sale off của vendor |
| var_hex | Nullable(String) | Mã màu hex |
| var_gtin | Nullable(String) | GTIN barcode |
| var_time | Int16 | |
| var_time_update | Int64 | |
| user_id | Int64 | FK → nh_user |
| var_deleted | Int16 | |
| var_status | Int16 | |
| var_stock_status | Int16 | 0=còn hàng; 1=hết hàng; 2=hết hàng quá 5 ngày |
| available_for_fulfillment | Int16 | Value 1: Variant cho fulfillment |
| var_harmonized_system_code | String | HS code |
| var_sync_ref | Int16 | 0=Chưa sync crossref; 1=đã sync crossref |
| sup_id | Int64 | vendor |
| wh_id | Int64 | warehouses id |
| data_json | Nullable(String) | Data json lấy từ bên SSA |
| is_sync | Int16 | 0=Chưa sync lại thông tin của SSA; 1=đã sync; 2=Không sync dùng cho mug, case, poster |
| time_sync | Int64 | Time sync |
| recheck_stock | Int16 | 0=không check stock; 1=cần check stock (dùng cho update stock status) |
| var_queue | Nullable(String) | Hàng đợi bên Dreamjunction. A,B,C |
| out_of_stock | Int16 | 0=Còn hàng; 1=hết hàng |
| reorder | Int64 | |
| temp_stock | Int64 | số lượng còn lại tạm tính dựa trên order |
| temp_stock2 | Int64 | |
| var_buying | Int64 | Số lượng đang mua |
| max_daily_sale | Int64 | |
| sell_7_day | Int64 | Variant dùng trong 7 ngày gần nhất |
| sell_14_day | Int64 | Variant dùng trong 14 ngày gần nhất |
| sell_this_month | Int64 | Số variant bán trong vòng 30 ngày |
| sell_last_month | Int64 | số variant bán trong tháng trước |
| last_modified | Int64 | Lưu thời gian cron update |
| is_adjust | Int16 | 0=Chưa cần điều chỉnh; 1=điều chỉnh từ mark out of stock; 2=điều chỉnh từ replenishment |
| var_last_order_time | Int64 | Last order time, used for update variants stock replenishment |
| var_default_casenumber | Int16 | Default case number for replenishment |
| location_id | Nullable(Int64) | Location trong warehouse |
| cc_catalog_sku | Int64 | Custom Cat Catalog sku |
| var_id_mapping | Int64 | var_id mapping dành cho sản phẩm phụ |
| var_case_qty | Int64 | create 24/09/2020: save qty in a case ssaw |
| var_report_basecost | Decimal(9,2) | Giá nhập hàng (report) |
| ssa_sync_failed | Int16 | Số lần sync no data từ ssa, 3 lần liên tục sẽ auto deactive |
| var_ats | Int64 | Avaiable to sell: barcode-onorder+buying+ss |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `nh_webhooks` 🔄
> Engine: SharedReplacingMergeTree | Rows: ~1.2K
> **Cần FINAL khi query**

| Column | Type | Ghi chú |
|---|---|---|
| webhook_id | Int64 | PK |
| webhook_name | Nullable(String) | |
| webhook_topic | Int16 | 1=order_completed; 2=order_canceled |
| webhook_delivery_url | Nullable(String) | webhook URL |
| cus_id | Int64 | FK → nh_customer |
| store_id | UInt64 | FK → nh_store_integrations |
| webhook_type | Int16 | |
| webhook_status | Int16 | |
| webhook_deleted | Int16 | |
| webhook_time | Int64 | |
| _processed_at | DateTime64(3,'UTC') | |
| _action | String | |
| _timestamp | DateTime64(3,'UTC') | |

---

### `v_nh_tracking_shipments` 🔵
> Engine: SharedMergeTree | Rows: ~10.1M
> **Không cần FINAL** — là view trên tracking_shipments, đã dedup
> Dùng thay vì `nh_tracking_shipments` khi cần tránh FINAL overhead

| Column | Type | Ghi chú |
|---|---|---|
| trk_id | Int64 | PK |
| trk_tracking_number | String | tracking number ⭐ |
| trk_api_type | Nullable(String) | |
| trk_external_id | Nullable(String) | |
| trk_status | Nullable(String) | tracking status ⭐ |
| trk_status_detail | Nullable(String) | |
| trk_est_delivery_date | Nullable(String) | |
| trk_weight | Float32 | (non-nullable version) |
| trk_carrier | Nullable(String) | carrier ⭐ |
| trk_service | Nullable(String) | |
| trk_error_content | Nullable(String) | |
| trk_created_at | DateTime | (non-nullable) |
| trk_updated_at | Int64 | (non-nullable) |
| trk_url | Nullable(String) | |
| trk_checked_at | Int64 | (non-nullable) |
| trk_checked_times | Int16 | (non-nullable) |
| trk_checked_times_error | Int16 | (non-nullable) |
| trk_checking_status | UInt16 | (non-nullable) |
| ord_id | Int64 | FK → nh_order |

---


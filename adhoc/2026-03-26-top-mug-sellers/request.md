# Top 10 Sellers theo Mug Volume 2024–2025

## Thông tin yêu cầu

| Field         | Value                                                  |
| ------------- | ------------------------------------------------------ |
| ClickUp Task  | `BI-786` · [link](https://app.clickup.com/t/86ex1f18e) |
| Người yêu cầu | CS & BD                                                |
| Team          | CS / BD                                                |
| Ngày yêu cầu  | 2026-03-26                                             |
| Deadline      | 2026-03-26 (ASAP)                                      |
| Output format | CSV                                                    |


## Mô tả

> Anh ơi, nhờ anh xuất giúp em list 5-10 khách hàng top fulfill sản phẩm mug bên mình trong năm 2024 và năm 2025 để team CS và BD review làm cơ sở offer giá enterprise ạ. Em expect có thể có list trong ngày 26/3 ạ.


## Thông tin khách hàng / đối tượng

| Field             | Value                           |
| ----------------- | ------------------------------- |
| Tên               | Tất cả sellers (top 5–10 by mug vol) |
| Email             | —                               |
| ID trong hệ thống | —                               |


## Data cần xuất

- Top 10 sellers theo mug volume — năm **2024** (2024-01-01 → 2024-12-31)
- Top 10 sellers theo mug volume — năm **2025** (2025-01-01 → 2025-12-31)
- Columns: seller email, team_id, mug_units, total_units, mug_pct

## Ghi chú

- Product type filter: `gm_product_type.name = 'Mug'` (join qua gm_product → gm_product_type)
- Source: `sc_order` + join chain variant → product → product_type (V3 platform)
- Cần bổ sung V1/V2 nếu sellers lớn bán trước khi migrate sang V3
- Units = `gm_product_option.quantity × sc_order_line_item.item_quantity` (consistent với BI-789)
- Filter: `payment_status = 'success'`
- Liên quan: BI-789 (Private Deal - Mug — BD outreach cho top 3–5 mug sellers)

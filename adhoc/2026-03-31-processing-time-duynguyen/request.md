# BI-792 — Processing Time Report (Duynguyen seller)

## Thông tin yêu cầu

| Field | Value |
|---|---|
| **ClickUp** | [BI-792](https://app.clickup.com/t/86ex3ay3q) |
| **Requester** | Phương Thảo (PD) |
| **Seller email** | duynguyen02169@gmail.com |
| **Priority** | Normal |
| **Due** | 2026-03-31 |
| **Status** | Done |

## Mô tả yêu cầu gốc

> Nhờ check processing time các sản phẩm này của team duynguyen02169@gmail.com. Đơn cũng hơi nhiều.

**Products:** Apparel, Blanket, Doormat, Garden Flag, Mug, Ornament, Tumbler

## Phạm vi

- **Seller:** duynguyen02169@gmail.com (team ID TBD via lookup)
- **Thời gian:** 2026-01-01 → 2026-03-31 (Q1 2026, dựa trên paid_date)
- **Products:** 7 sản phẩm trong list
- **Output:**
  - **Summary:** avg processing days per product type × paid month (matrix)
  - **Detail:** raw list từng đơn để đối soát

## Data source & join path

### Tables chính
1. `gea__silver.fact_order_fulfillment_performance_by_product` 🔄 — có cột processing time sẵn (~1.5M rows, cần FINAL)
2. `gea__silver.fact_order_line_v1` + `gea__silver.fact_order_line_v3` 🔵 — V1 (OMS) + V3 (POD), cần UNION DISTINCT để tránh overlap, có `seller_email`, không cần FINAL

> ✅ Fact tables thực tế: `fact_order_line_v1` và `fact_order_line_v3` (không phải `v__fact_order_line`). Join bằng `toUInt64(order_id)` vì type mismatch Int64 ↔ UInt64.

### Join logic
- `v__fact_order_line` → filter `seller_email = 'duynguyen02169@gmail.com'` + `payment_date_utc` trong Q1 2026
- JOIN `fact_order_fulfillment_performance_by_product FINAL` ON `order_id`
- **Lưu ý type mismatch:** `v__fact_order_line.order_id` là Int64, fact table là UInt64 → cast `toUInt64()`

### Processing time column
- Source: `fact_order_fulfillment_performance_by_product.processing_day` (Nullable Float32, đơn vị: ngày)
- Definition: từ order paid → fulfilled/shipped

## Output columns

### Summary (aggregate)
| Column | Mô tả |
|---|---|
| product_type | Tên sản phẩm |
| paid_month | Tháng thanh toán (YYYY-MM) |
| order_count | Số đơn |
| avg_processing_days | Trung bình ngày xử lý |
| p50_processing_days | Median |
| p90_processing_days | P90 |

### Detail (raw list)
| Column | Mô tả |
|---|---|
| order_id | Order ID |
| product_type | Tên sản phẩm |
| source_system | 'v1' (OMS) hay 'v3' (POD) |
| paid_date | Ngày thanh toán (từ `payment_date_utc`) |
| processing_day | Ngày xử lý thực tế (Nullable Float32) |
| seller_email | Email seller |

## Notes
- Seller có thể có orders từ cả OMS (V1) và POD (V3), cần UNION kết quả
- "Đơn hơi nhiều" → có thể chạy lâu, kiểm tra timeout MCP

## Audience

**Ops team** — investigate và fix khi được escalate từ BOD. Workflow:
- BOD thấy SLA pass rate xấu → escalate
- Ops cần biết: sản phẩm nào bị, ở đâu, và bottleneck là production hay carrier handoff

Dashboard phải trả lời được trong ≤2 phút: "Tháng này cần fix gì trước?"

## Why

`order-sla` (BOD dashboard) đã cho thấy *kết quả* (pass rate tháng, trend) nhưng không trả lời được:
- "Tại sao pass rate thấp?" — cần contribution split (production vs tracking lag)
- "Cần cải thiện ở đâu trước?" — cần breakdown theo product_type và fulfillment location

Dữ liệu thực (6 tháng) xác nhận gap này rõ ràng:
- Platform Poster: 65.3% pass rate, avg_scan_day = 1.96 (gần gấp 3 Apparel)
- Platform Tumbler: 71.4% pass rate, avg_prod_day = 2.12 (cao nhất)
- Standard Tumbler: 84.6% pass rate, cùng production bottleneck

Ops không thể prioritize mà không có breakdown này.

## What Changes

- **Mới:** Contribution split — `processing_day` vs `first_scan_day` theo product_type cho cả Platform và Standard
- **Mới:** SLA pass rate breakdown theo `product_type` — Platform và Standard tách riêng
- **Mới:** SLA pass rate breakdown theo `ordx_fulfill_locate` — xác định facility nào là bottleneck
- **Không thay đổi:** `order-sla` (BOD dashboard) — report này là bổ sung, không thay thế

## Capabilities

### New Capabilities

- `ops-sla-contribution`: Stacked bar — production_day vs first_scan_day trung bình theo product_type, tách Platform/Standard
- `ops-sla-product-breakdown`: Bar chart SLA pass rate theo product_type — Platform vs Standard (2 panels)
- `ops-sla-location-breakdown`: Bar chart SLA pass rate theo `ordx_fulfill_locate` — Platform vs Standard

### Modified Capabilities

*(Không có)*

## Impact

- **Data sources:**
  - `gea__silver.fact_order_fulfillment_performance FINAL` — SLA metrics + `is_platform` flag
  - `gea__silver.fact_order_fulfillment_performance_by_product FINAL` — Standard: product_type sẵn có
  - `geadb__bronze.nh_order_item` — Platform: join để lấy `ordi_type`
  - `gea__silver.dict_product_type` — lookup `ordi_type → type_name`
- **SLA thresholds:** Platform ≤ 3 biz days, Standard ≤ 4 biz days (kế thừa từ order-sla)
- **Output:** POC notebook (Plotly) + export PNG — phục vụ ops review
- **Không ảnh hưởng:** Production pipeline, `order-sla` BOD report, schema hiện có

## Biz Validation Questions

- Ops team: breakdown này có đủ để identify next action không, hay cần thêm dimension (e.g., seller, shipping_class)?
- Product Poster Platform (65.3%): ops có biết lý do scan chậm không — packaging size, carrier route khác?
- Internal target per product_type: có muốn set riêng không, hay dùng chung threshold của group?
- Action owner: khi Tumbler production chậm → ai nhận? Khi Poster scan chậm → ai nhận?

## Audience

**BOD (Board of Directors)** — high-level, big-picture. Dashboard phải đánh giá được tình hình trong ≤30s:
- Số liệu súc tích, trọng tâm
- Rõ ràng tốt/xấu (dùng trend + MoM delta thay cho màu xanh/đỏ — chưa có internal benchmark)
- Khi xấu → escalate xuống ops (BOD không cần drill-down chi tiết)

**Escalation workflow:** BOD thấy pass rate xấu → escalate xuống ops team để investigate và fix. BOD không tự phân tích segment hay bottleneck.

## Why

Gearment cam kết SLA với khách hàng dựa trên **Tracking Active Lead (TAL = paid → first scan)**. Hiện chưa có báo cáo nào đánh giá mức độ tuân thủ SLA thực tế. Team cần biết đang đứng ở đâu so với cam kết — và nhóm đơn nào đang vi phạm — để ưu tiên cải thiện.

## What Changes

- **Mới:** Báo cáo SLA compliance tập trung vào TAL (paid → first scan), chia 2 nhóm: Platform và Standard
- **Mới:** SLA pass rate (% đơn đạt TAL ≤ threshold) theo từng nhóm với threshold khác nhau
- **Mới:** Trend SLA pass rate theo tháng — phát hiện degradation sớm
- **Deferred:** Breakdown theo segment: fulfillment location, country — ops-level, không thuộc BOD view; bổ sung sau nếu cần ops dashboard
- **Không thay đổi:** Báo cáo `order-performance` hiện tại (executive metrics) — report này là bổ sung, không thay thế

## Capabilities

### New Capabilities

- `sla-compliance-overview`: Scorecard SLA pass rate tháng hiện tại + MoM delta — Platform vs Standard
- `sla-trend`: Trend TAL pass rate 12 tháng — Platform vs Standard (line chart, TAL only)
- ~~`sla-breakdown`~~: Deferred — ops-level, không trong BOD view

### Modified Capabilities

*(Không có — đây là report mới, không sửa spec hiện có)*

## Impact

- **Data source:**
  - `gea__silver.fact_order_fulfillment_performance` — production time + tracking lag + `is_platform` flag (cả 2 nhóm)
- **SLA thresholds (confirmed):** Platform ≤ 3 biz days, Standard ≤ 4 biz days, Rush ≤ 2 biz days (future)
- **Output:** POC notebook (Plotly) + export PNG — phục vụ BU review và sau đó migrate lên Metabase
- **Không ảnh hưởng:** Production pipeline, `order-performance` report, schema hiện có

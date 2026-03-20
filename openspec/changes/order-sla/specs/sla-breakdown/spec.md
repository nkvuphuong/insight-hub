## STATUS: DEFERRED — Ops-level, không nằm trong BOD view

Spec này mô tả breakdown TAL pass rate theo segment (location × country). Audience BOD chỉ cần scorecard + trend và escalate xuống ops khi có vấn đề — ops team tự query để drill down. Spec này giữ lại để tham khảo khi cần bổ sung ops dashboard sau này.

---

## ADDED Requirements

### Requirement: TAL pass rate theo segment
Hệ thống báo cáo SHALL tính TAL pass rate phân tách theo các dimension: `ordx_fulfill_locate` (fulfillment location) và `country_code`, riêng biệt cho từng nhóm (Platform / Standard), nhằm identify segment nào đang kéo hiệu suất xuống.

Output per row:
- `group`: Platform / Standard
- `ordx_fulfill_locate`: HB1 / TX1 / HB2 / etc.
- `country_code`: US / CA / etc.
- `total_orders`: số đơn trong segment (denominator)
- `tal_pass_rate`: % đơn đạt TAL ≤ threshold (**metric chính**)
- `production_pass_rate`: % đơn đạt production time
- `tracking_pass_rate`: % đơn đạt tracking lag
- `avg_tal_days`, `avg_processing_day`, `avg_tracking_lag_day`: trung bình thực tế để context

#### Scenario: Segment cross-tab đầy đủ
- **WHEN** query chạy cho toàn bộ 12 tháng gần nhất
- **THEN** mỗi combination (group × location × country) có ≥ 1 row nếu có đơn

#### Scenario: Segment ít đơn không bị hide
- **WHEN** một combination chỉ có 10-50 đơn
- **THEN** vẫn có row trong kết quả; consumer tự filter nếu muốn loại bỏ segment nhỏ

#### Scenario: Identify worst performing segment
- **WHEN** chart/table sort theo `tal_pass_rate` ASC
- **THEN** segment có pass rate thấp nhất nằm đầu bảng, dễ nhìn thấy điểm cần cải thiện

#### Scenario: Platform và Standard không mix trong cùng 1 row
- **WHEN** query output được load vào chart
- **THEN** mỗi row chỉ thuộc 1 group, không có aggregation cross-group

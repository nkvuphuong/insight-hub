## ADDED Requirements

### Requirement: SLA pass rate tổng thể theo nhóm
Hệ thống báo cáo SHALL tính tỷ lệ đơn đạt SLA (pass rate) dựa trên **Tracking Active Lead (TAL = paid → first scan)**, riêng biệt cho 2 nhóm: **Platform** (shipping_class = 'Other', threshold ≤ 3 biz days) và **Standard** (shipping_class ≠ 'Other', threshold ≤ 4 biz days).

Các metric cần output (per nhóm, per tháng):
- `group`: Platform / Standard
- `month`: tháng aggregate
- `total_orders`: tổng số đơn có đủ data (denominator — chỉ đơn có TAL IS NOT NULL)
- `tal_pass_rate`: % đơn có TAL ≤ threshold tương ứng (**metric duy nhất hiển thị**)

#### Scenario: Pass rate tính đúng threshold theo nhóm
- **WHEN** query chạy với 12 tháng gần nhất
- **THEN** Platform so với ≤ 3 biz days, Standard so với ≤ 4 biz days — không áp dụng nhầm threshold

#### Scenario: Đơn thiếu data bị loại khỏi denominator
- **WHEN** đơn có TAL IS NULL (không có first scan data)
- **THEN** đơn đó KHÔNG được tính vào denominator; chart hiển thị footnote "(*) Chỉ tính đơn có tracking data" — không tách thành metric riêng

### Requirement: SLA threshold cấu hình trong SQL
SQL SHALL định nghĩa SLA thresholds dưới dạng constants trong CTE đầu tiên, không hardcode rải rác.

#### Scenario: Threshold được khai báo tập trung
- **WHEN** có thay đổi về SLA commitment (ví dụ Platform từ 3d → 2d)
- **THEN** chỉ cần sửa 1 CTE duy nhất (`sla_config`), không cần tìm kiếm nhiều chỗ trong query

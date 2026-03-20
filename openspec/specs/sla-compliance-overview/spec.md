# Spec: SLA Compliance Overview

**Capability:** sla-compliance-overview
**Report:** order-sla
**Audience:** BOD

---

## Requirements

### Requirement: SLA pass rate tổng thể theo nhóm

Hệ thống báo cáo SHALL tính tỷ lệ đơn đạt SLA (pass rate) dựa trên **Tracking Active Lead (TAL = paid → first scan)**, riêng biệt cho 2 nhóm:
- **Platform**: đơn có trong `v__usps_paided_to_first_scan_days` (USPS label do khách hàng cung cấp), threshold ≤ 3 biz days
- **Standard**: đơn KHÔNG có trong `v__usps_paided_to_first_scan_days` (GM mua label), threshold ≤ 4 biz days

TAL calculation:
- Platform: `business_days_exclude_payment` (integer biz days, floor-rounded)
- Standard: `floor(processing_day + first_scan_day)` (integer biz days elapsed, floor-rounded — đồng bộ convention với Platform)

Output per nhóm, per tháng:
- `group`: Platform / Standard
- `month`: tháng aggregate (YYYY-MM)
- `total_orders`: tổng số đơn có đủ data (denominator — chỉ đơn có TAL IS NOT NULL)
- `tal_pass_rate`: % đơn có TAL ≤ threshold tương ứng (**metric duy nhất hiển thị**)

#### Scenario: Pass rate tính đúng threshold theo nhóm
- **WHEN** query chạy với 12 tháng gần nhất
- **THEN** Platform so với ≤ 3 biz days, Standard so với ≤ 4 biz days — không áp dụng nhầm threshold

#### Scenario: Đơn thiếu data bị loại khỏi denominator
- **WHEN** đơn có TAL IS NULL (không có first scan data)
- **THEN** đơn đó KHÔNG được tính vào denominator; chart hiển thị footnote "(*) Chỉ tính đơn có tracking data" — không tách thành metric riêng

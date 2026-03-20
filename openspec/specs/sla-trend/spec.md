# Spec: SLA Trend

**Capability:** sla-trend
**Report:** order-sla
**Audience:** BOD

---

## Requirements

### Requirement: SLA trend TAL theo tháng

Hệ thống báo cáo SHALL hiển thị trend TAL pass rate theo từng tháng trong 12 tháng gần nhất, tách biệt **Platform** và **Standard**, để phát hiện degradation hoặc cải thiện theo thời gian.

Output per row:
- `month`: tháng (YYYY-MM)
- `group`: Platform / Standard
- `total_orders`: số đơn có TAL data (denominator)
- `tal_pass_rate`: % đơn đạt TAL ≤ threshold (**metric duy nhất hiển thị**)

#### Scenario: Trend line có đủ điểm data
- **WHEN** có data trong 12 tháng liên tục
- **THEN** có đủ 12 rows per group (24 rows total), không có tháng nào bị bỏ trống

#### Scenario: Phát hiện tháng degradation
- **WHEN** một tháng nào đó có TAL pass rate giảm đột ngột
- **THEN** row của tháng đó hiển thị giá trị thấp, visualize được trên line chart

### Requirement: Chart SLA trend

Python visualization SHALL plot line chart với **TAL pass rate** theo tháng, phân biệt Platform vs Standard (2 lines với markers khác nhau). Chart tập trung vào 1 metric chính — không overlay production/tracking lag (ops-level, không phù hợp BOD view).

#### Scenario: Visualize Plotly interactive
- **WHEN** notebook load DataFrame từ `sla_standard.sql` và `sla_platform.sql`
- **THEN** Plotly render line chart có tooltip, hover, legend rõ ràng cho Platform vs Standard

#### Scenario: Export PNG cho báo cáo
- **WHEN** `export.py` chạy
- **THEN** output PNG với DPI ≥ 150, readable trên slide presentation

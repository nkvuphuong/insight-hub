# Changelog — ops-sla-drilldown

## v0.2 — poc-done, unified dashboard (2026-03-24)

- Period đổi sang 1 tháng gần nhất hoàn chỉnh (tháng 2/2026) để phản ứng nhanh hơn
- HB1 + HB2 gộp thành CA (cùng ops lead California) tại tầng SQL
- Thêm `export_dashboard.py` — unified dashboard 1 trang (Bước 1→2→3), key findings auto-calculated
- **Key findings (tháng 2/2026):**
  - CA thấp hơn TX1: Platform 84.1% vs 93.4% · Standard 90.9% vs 98.0%
  - Platform CA (n=1,573): chỉ có Poster, avg_scan=1.44 ngày — carrier handoff lag
  - Platform TX1 Doormat (n=310): avg_tal=3.03 ngày (vượt SLA≤3), avg_scan=2.41 — carrier issue
  - Platform Sticker (n=2,958): 89.2%, avg_scan=1.50 — borderline, cần theo dõi
  - Carrier handoff là bottleneck chủ đạo — không phải production

## v0.1 — poc-done (2026-03-24)

- 4 SQL queries verified qua MCP: `ops_contribution`, `ops_product_breakdown`, `ops_location_breakdown`, `ops_facility_product`
- POC notebook (`poc.ipynb`) với 4 charts theo drill-down flow L1→L4
- `export.py` — export 4 PNGs riêng lẻ
- Drill-down flow: L1 facility triage → L2 facility×product bottleneck type → L3 product priority → L4 contribution split

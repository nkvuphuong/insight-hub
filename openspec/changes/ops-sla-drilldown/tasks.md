## 0. Prerequisite [gate: depends on enrich-fact-ofp-by-product]

> SQL phase (task 3.x) không bắt đầu cho đến khi `enrich-fact-ofp-by-product` hoàn tất và `fact_order_fulfillment_performance_by_product` có `is_platform` + `first_scan_day` đúng cho Platform.

- [x] 0.1 Confirm `enrich-fact-ofp-by-product` đã done — platform_with_scan=118,267 / platform_total=567,221 / standard_with_scan=627,417 ✓

## 1. Discovery → Spec Confirmed [gate: done — context từ order-sla explore session]

- [x] 1.1 Confirm Platform CÓ trong `fact_order_fulfillment_performance_by_product` nhưng không có `is_platform` và tracking timestamps = NULL
- [x] 1.2 Confirm product_type distribution: Platform có đủ catalog (Sticker #1, khác hẳn Standard)
- [x] 1.3 Confirm bottleneck patterns: Poster=scan (first_scan 1.96), Tumbler=production (prod 2.12), Doormat=scan (2.54)
- [x] 1.4 Confirm period: 6 tháng, không cần trend (BOD đã có)
- [x] 1.5 Design decision: sau enrich, cả Platform và Standard đều dùng `by_product` — không cần join nh_order_item

## 2. Setup [gate: Phuong confirm spec-confirmed]

- [x] 2.1 Tạo folder `reports/ops-sla-drilldown/queries/` và `reports/ops-sla-drilldown/changelog.md`
- [x] 2.2 Cập nhật bảng "Danh Sách Báo Cáo" trong `CLAUDE.md`

## 3. SQL — Viết và Verify qua MCP [gate: sql-verified]

- [x] 3.1 Viết `ops_contribution.sql` — avg processing_day + first_scan_day per product_type, Platform và Standard (2 CTEs, 1 UNION output)
- [x] 3.2 Verify `ops_contribution.sql` qua MCP — kiểm tra numbers khớp data khảo sát (Tumbler prod=2.02, Poster scan=1.96 cho Platform)
- [x] 3.3 Viết `ops_product_breakdown.sql` — SLA pass rate per product_type, Platform và Standard
- [x] 3.4 Verify `ops_product_breakdown.sql` qua MCP — kiểm tra Platform Poster ≈65%, Tumbler ≈71%
- [x] 3.5 Viết `ops_location_breakdown.sql` — SLA pass rate per `ordx_fulfill_locate`, Platform và Standard
- [x] 3.6 Verify `ops_location_breakdown.sql` qua MCP — kiểm tra row count, pass rate range hợp lý
- [x] 3.7 Viết `ops_facility_product.sql` — avg processing_day + first_scan_day per facility × product_type, Platform và Standard
- [x] 3.8 Verify `ops_facility_product.sql` qua MCP — kiểm tra HB1/HB2 vs TX1 pattern hợp lý

## 4. POC Visualization [gate: poc-done]

- [x] 4.1 Tạo `reports/ops-sla-drilldown/poc.ipynb` — load 4 CSVs vào DataFrames
- [x] 4.2 Chart 1 — Contribution split: grouped stacked bar, product_type × (prod_day + scan_day), reference line SLA threshold
- [x] 4.3 Chart 2 — Product breakdown: horizontal bar, Platform panel + Standard panel, sorted worst→best
- [x] 4.4 Chart 3 — Location breakdown: grouped bar Platform vs Standard per facility, bubble size = order volume
- [x] 4.5 Chart 4 — Facility × product cross-tab: grouped bar per facility, x = product_type, stacked prod+scan, TX1 làm benchmark
- [x] 4.6 Tạo `reports/ops-sla-drilldown/export.py` — export PNGs cho 4 charts
- [x] 4.7 Ghi `reports/ops-sla-drilldown/changelog.md` — entry v0.1 poc-done
- [x] 4.8 Ghi entry vào `docs/CHANGELOG.md`

## 5. Biz Validation [gate: biz-validated]

- [x] 5.1 Chuẩn bị summary cho ops team: "Tháng này cần fix gì trước — product nào, facility nào?"
- [ ] 5.2 Ops review — thu thập feedback: breakdown đủ để identify action không? Cần thêm dimension không?
- [ ] 5.3 Ghi feedback từ ops review vào `changelog.md`
- [ ] 5.4 Điều chỉnh chart nếu có feedback — re-export PNG
